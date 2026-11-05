import Foundation
import HTTPTypes
import HummingbirdTesting
import NIOCore
import SQLKit
import Testing

@testable import Server

private var data: [String: Any] { ["iterations": 1000, "salt": "kLpHPb2zsjo=", "sealed": "rphyE9rfNKrL"] }
private var updated: [String: Any] { ["iterations": 1000, "salt": "qpVdZ1Tf9Ag=", "sealed": "0Ux2xNfCF4R5/+=="] }
private let realIP = HTTPField.Name("X-Real-IP")!

/// A share created through the API: its identifier and admin token.
private func create(_ client: any TestClientProtocol, ip: String = "192.0.2.1") async throws -> (String, String) {
    let response = try await client.execute(uri: "/share", method: .post, headers: [realIP: ip], json: data)
    try #require(response.status == .created)
    let json = try #require(response.json)
    return (try #require(json["identifier"] as? String), try #require(json["admin_token"] as? String))
}

@Suite(.enabled(if: TestDatabase.isAvailable, "needs PADLOK_TEST_DB_HOST"))
struct ShareTests {
    @Test
    func createReturnsTheIdentifierAndAdminToken() async throws {
        try await testApplication { client, _ in
            let response = try await client.execute(uri: "/share", method: .post, json: data)

            #expect(response.status == .created)
            #expect(response.headers[.contentType]?.hasPrefix("application/json") == true)
            #expect(response.headers[.cacheControl] == "no-store")
            let json = try #require(response.json)
            #expect(Set(json.keys) == ["identifier", "admin_token"])
            #expect((json["identifier"] as? String)?.isEmpty == false)
            #expect((json["admin_token"] as? String)?.isEmpty == false)
        }
    }

    @Test
    func getReturnsTheSealedAddressAsSent() async throws {
        try await testApplication { client, _ in
            let (identifier, _) = try await create(client)

            let response = try await client.execute(uri: "/shared/\(identifier)", method: .get)

            #expect(response.status == .ok)
            #expect(response.json as NSDictionary? == data as NSDictionary)
        }
    }

    @Test
    func identifiersAreCaseSensitive() async throws {
        try await testApplication { client, _ in
            let (identifier, _) = try await create(client)
            let swapped = String(identifier.map { $0.isUppercase ? Character($0.lowercased()) : Character($0.uppercased()) })
            try #require(swapped != identifier)

            let response = try await client.execute(uri: "/shared/\(swapped)", method: .get)

            #expect(response.status == .notFound)
        }
    }

    @Test(arguments: ["/shared/unknown", "/shared/%C3%A9", "/shared/\(String(repeating: "a", count: 40))"])
    func unknownSharesAreNotFound(uri: String) async throws {
        try await testApplication { client, _ in
            let response = try await client.execute(uri: uri, method: .get)

            #expect(response.status == .notFound)
            #expect(response.headers[.contentType]?.hasPrefix("application/problem+json") == true)
            #expect(response.json?["status"] as? Int == 404)
        }
    }

    @Test
    func updateReplacesTheSealedAddress() async throws {
        try await testApplication { client, _ in
            let (identifier, token) = try await create(client)

            let response = try await client.execute(
                uri: "/shared/\(identifier)",
                method: .put,
                headers: [.authorization: "Bearer \(token)"],
                json: updated
            )

            #expect(response.status == .noContent)
            #expect(response.body.readableBytes == 0)
            let after = try await client.execute(uri: "/shared/\(identifier)", method: .get)
            #expect(after.json as NSDictionary? == updated as NSDictionary)
        }
    }

    @Test
    func deleteRemovesTheShare() async throws {
        try await testApplication { client, _ in
            let (identifier, token) = try await create(client)

            let response = try await client.execute(
                uri: "/shared/\(identifier)",
                method: .delete,
                headers: [.authorization: "Bearer \(token)"]
            )

            #expect(response.status == .noContent)
            #expect(try await client.execute(uri: "/shared/\(identifier)", method: .get).status == .notFound)
            let again = try await client.execute(
                uri: "/shared/\(identifier)",
                method: .put,
                headers: [.authorization: "Bearer \(token)"],
                json: updated
            )
            #expect(again.status == .notFound)
        }
    }

    @Test
    func changesWithoutATokenAreUnauthorized() async throws {
        try await testApplication { client, _ in
            let (identifier, _) = try await create(client)

            let put = try await client.execute(uri: "/shared/\(identifier)", method: .put, json: updated)
            let delete = try await client.execute(uri: "/shared/\(identifier)", method: .delete)

            for response in [put, delete] {
                #expect(response.status == .unauthorized)
                #expect(response.headers[.wwwAuthenticate] == "Bearer")
            }
        }
    }

    @Test(arguments: ["Basic {token}", "{token}", "Bearer", "Bearer a b"])
    func malformedAuthorizationsAreUnauthorized(authorization: String) async throws {
        try await testApplication { client, _ in
            let (identifier, token) = try await create(client)

            let response = try await client.execute(
                uri: "/shared/\(identifier)",
                method: .put,
                headers: [.authorization: authorization.replacingOccurrences(of: "{token}", with: token)],
                json: updated
            )

            #expect(response.status == .unauthorized)
        }
    }

    @Test
    func theBearerSchemeIsCaseInsensitive() async throws {
        try await testApplication { client, _ in
            let (identifier, token) = try await create(client)

            let response = try await client.execute(
                uri: "/shared/\(identifier)",
                method: .delete,
                headers: [.authorization: "bearer \(token)"]
            )

            #expect(response.status == .noContent)
        }
    }

    @Test
    func wrongTokensAreForbidden() async throws {
        try await testApplication { client, _ in
            let (identifier, _) = try await create(client)

            let put = try await client.execute(
                uri: "/shared/\(identifier)",
                method: .put,
                headers: [.authorization: "Bearer 1234"],
                json: updated
            )
            let delete = try await client.execute(uri: "/shared/\(identifier)", method: .delete, headers: [.authorization: "Bearer 1234"])

            #expect(put.status == .forbidden)
            #expect(delete.status == .forbidden)
            #expect(try await client.execute(uri: "/shared/\(identifier)", method: .get).json as NSDictionary? == data as NSDictionary)
        }
    }

    /// Released apps still send the token in the path.
    @Test
    func legacyRoutesTakeTheTokenFromThePath() async throws {
        try await testApplication { client, _ in
            let (identifier, token) = try await create(client)

            #expect(try await client.execute(uri: "/shared/\(identifier)/1234", method: .put, json: updated).status == .forbidden)
            #expect(try await client.execute(uri: "/shared/\(identifier)/1234", method: .delete).status == .forbidden)
            #expect(try await client.execute(uri: "/shared/\(identifier)/\(token)", method: .put, json: updated).status == .noContent)
            #expect(try await client.execute(uri: "/shared/\(identifier)", method: .get).json as NSDictionary? == updated as NSDictionary)
            #expect(try await client.execute(uri: "/shared/\(identifier)/\(token)", method: .delete).status == .noContent)
            #expect(try await client.execute(uri: "/shared/\(identifier)/\(token)", method: .delete).status == .notFound)
        }
    }

    static var invalidPayloads: [(String, [String: Any])] {
        [
            ("empty payload", [:]),
            ("missing iterations", data.filter { $0.key != "iterations" }),
            ("missing salt", data.filter { $0.key != "salt" }),
            ("missing sealed", data.filter { $0.key != "sealed" }),
            ("zero iterations", data.merging(["iterations": 0]) { $1 }),
            ("negative iterations", data.merging(["iterations": -5]) { $1 }),
            ("too many iterations", data.merging(["iterations": 1_000_001]) { $1 }),
            ("iterations as string", data.merging(["iterations": "1000"]) { $1 }),
            ("null salt", data.merging(["salt": NSNull()]) { $1 }),
            ("sealed as number", data.merging(["sealed": 42]) { $1 }),
            ("blank salt", data.merging(["salt": ""]) { $1 }),
            ("blank sealed", data.merging(["sealed": ""]) { $1 }),
            ("salt too long", data.merging(["salt": String(repeating: "a", count: 256)]) { $1 }),
            ("sealed too long", data.merging(["sealed": String(repeating: "a", count: 16_385)]) { $1 }),
        ]
    }

    @Test(arguments: invalidPayloads.map(\.0))
    func invalidPayloadsAreUnprocessable(name: String) async throws {
        try await testApplication { client, database in
            let payload = try #require(Self.invalidPayloads.first { $0.0 == name }?.1)
            let (identifier, token) = try await create(client)

            let post = try await client.execute(uri: "/share", method: .post, json: payload)
            let put = try await client.execute(
                uri: "/shared/\(identifier)",
                method: .put,
                headers: [.authorization: "Bearer \(token)"],
                json: payload
            )

            #expect(post.status == .unprocessableContent)
            #expect(post.headers[.contentType]?.hasPrefix("application/problem+json") == true)
            #expect(put.status == .unprocessableContent)
            let count = try await database.sql.raw("SELECT COUNT(*) AS count FROM shared_data").first(decodingColumn: "count", as: Int.self)
            #expect(count == 1)
        }
    }

    @Test
    func theLongestValidValuesAreAccepted() async throws {
        try await testApplication { client, _ in
            let payload: [String: Any] = [
                "iterations": 1_000_000, "salt": String(repeating: "a", count: 255), "sealed": String(repeating: "a", count: 16_384),
            ]
            let response = try await client.execute(uri: "/share", method: .post, json: payload)
            #expect(response.status == .created)
        }
    }

    @Test
    func aBodyThatIsNotJSONIsABadRequest() async throws {
        try await testApplication { client, _ in
            let response = try await client.execute(
                uri: "/share",
                method: .post,
                headers: [.contentType: "application/json"],
                body: ByteBuffer(string: "{not json")
            )

            #expect(response.status == .badRequest)
            #expect(response.headers[.contentType]?.hasPrefix("application/problem+json") == true)
        }
    }

    @Test
    func unknownFieldsAreIgnored() async throws {
        try await testApplication { client, _ in
            let response = try await client.execute(uri: "/share", method: .post, json: data.merging(["extra": true]) { $1 })
            #expect(response.status == .created)
        }
    }
}

@Suite(.enabled(if: TestDatabase.isAvailable, "needs PADLOK_TEST_DB_HOST"))
struct ShareStorageTests {
    @Test
    func onlyAHashOfTheAdminTokenIsStored() async throws {
        try await testApplication { client, database in
            let (identifier, token) = try await create(client)

            let row = try #require(
                try await database.sql.raw("SELECT * FROM shared_data WHERE identifier = \(bind: identifier)").first()
            )
            #expect(try row.decode(column: "admin_token_hash", as: String.self) == AdminToken.hash(token))
            for column in row.allColumns {
                let value = try? row.decode(column: column, as: String.self)
                #expect(value?.contains(token) != true, "\(column) holds the admin token")
            }
        }
    }

    @Test
    func timestampsComeFromTheClock() async throws {
        let clock = TestClock()
        let created = clock.now()
        try await testApplication(clock: clock) { client, database in
            let (identifier, token) = try await create(client)
            clock.advance(by: 90)

            let response = try await client.execute(
                uri: "/shared/\(identifier)",
                method: .put,
                headers: [.authorization: "Bearer \(token)"],
                json: updated
            )
            try #require(response.status == .noContent)

            let row = try #require(try await database.sql.raw("SELECT created_at, updated_at FROM shared_data").first())
            #expect(try row.decode(column: "created_at", as: Date.self) == created)
            #expect(try row.decode(column: "updated_at", as: Date.self) == created.addingTimeInterval(90))
        }
    }
}

@Suite(.enabled(if: TestDatabase.isAvailable, "needs PADLOK_TEST_DB_HOST"))
struct RateLimitTests {
    @Test
    func shareCreationIsLimitedPerClientIP() async throws {
        let clock = TestClock()
        try await testApplication(clock: clock) { client, _ in
            for _ in 0..<20 {
                _ = try await create(client, ip: "192.0.2.1")
            }

            let refused = try await client.execute(uri: "/share", method: .post, headers: [realIP: "192.0.2.1"], json: data)
            #expect(refused.status == .tooManyRequests)
            #expect(refused.headers[.retryAfter] == "3600")
            #expect(refused.headers[.contentType]?.hasPrefix("application/problem+json") == true)

            // Another address has its own budget.
            _ = try await create(client, ip: "192.0.2.2")

            // Invalid requests count too: the limit applies before the body is read.
            let invalid = try await client.execute(uri: "/share", method: .post, headers: [realIP: "192.0.2.1"], json: [:])
            #expect(invalid.status == .tooManyRequests)

            // The window slides: once the first share is an hour old, one more is allowed.
            clock.advance(by: 3600)
            _ = try await create(client, ip: "192.0.2.1")
        }
    }

    @Test
    func wrongAdminTokensAreLimitedPerClientIP() async throws {
        let clock = TestClock()
        try await testApplication(clock: clock) { client, _ in
            let (identifier, token) = try await create(client)
            let attacker: HTTPFields = [realIP: "198.51.100.7", .authorization: "Bearer wrong"]

            for _ in 0..<10 {
                #expect(try await client.execute(uri: "/shared/\(identifier)", method: .delete, headers: attacker).status == .forbidden)
            }

            // Even the right token is refused from that address, so a lucky guess is not
            // told apart from a wrong one.
            let right: HTTPFields = [realIP: "198.51.100.7", .authorization: "Bearer \(token)"]
            let refused = try await client.execute(uri: "/shared/\(identifier)", method: .delete, headers: right)
            #expect(refused.status == .tooManyRequests)
            #expect(refused.headers[.retryAfter] == "3600")
            #expect(
                try await client.execute(uri: "/shared/\(identifier)/\(token)", method: .put, headers: right, json: updated).status
                    == .tooManyRequests)

            // The owner, elsewhere, is not locked out.
            let owner: HTTPFields = [realIP: "192.0.2.1", .authorization: "Bearer \(token)"]
            #expect(try await client.execute(uri: "/shared/\(identifier)", method: .put, headers: owner, json: updated).status == .noContent)

            clock.advance(by: 3600)
            #expect(try await client.execute(uri: "/shared/\(identifier)", method: .delete, headers: right).status == .noContent)
        }
    }

    @Test
    func successfulChangesAreNotCounted() async throws {
        try await testApplication { client, _ in
            let (identifier, token) = try await create(client)
            let owner: HTTPFields = [realIP: "192.0.2.1", .authorization: "Bearer \(token)"]

            for _ in 0..<15 {
                #expect(try await client.execute(uri: "/shared/\(identifier)", method: .put, headers: owner, json: updated).status == .noContent)
            }
        }
    }
}
