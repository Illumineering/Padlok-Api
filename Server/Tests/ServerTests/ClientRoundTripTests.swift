import Foundation
import HummingbirdTesting
import PadlokAPIClient
import Testing

/// The API as the apps call it: through the generated client the repository exports.
@Suite(.enabled(if: TestDatabase.isAvailable, "needs PADLOK_TEST_DB_HOST"))
struct ClientRoundTripTests {
    private let info = Components.Schemas.SharedInfo(iterations: 1000, salt: "kLpHPb2zsjo=", sealed: "rphyE9rfNKrL")
    private let replacement = Components.Schemas.SharedInfo(iterations: 1000, salt: "qpVdZ1Tf9Ag=", sealed: "0Ux2xNfCF4R5/+==")

    @Test
    func createReadReplaceAndDelete() async throws {
        let info = info
        let replacement = replacement
        try await testApplication { testClient, _ in
            let client = try Client.padlok(serverURL: URL(string: "http://localhost")!, transport: TestClientTransport(client: testClient))

            let created = try await client.createShare(body: .json(info)).created.body.json
            #expect(try await client.getShare(path: .init(identifier: created.identifier)).ok.body.json == info)

            _ = try await client.updateShare(identifier: created.identifier, adminToken: created.adminToken, info: replacement).noContent
            #expect(try await client.getShare(path: .init(identifier: created.identifier)).ok.body.json == replacement)

            _ = try await client.deleteShare(identifier: created.identifier, adminToken: created.adminToken).noContent
            _ = try await client.getShare(path: .init(identifier: created.identifier)).notFound
            _ = try await client.deleteShare(identifier: created.identifier, adminToken: created.adminToken).notFound
        }
    }

    @Test
    func refusalsDecodeAsTheSpecSays() async throws {
        let info = info
        try await testApplication { testClient, _ in
            let client = try Client.padlok(serverURL: URL(string: "http://localhost")!, transport: TestClientTransport(client: testClient))
            let created = try await client.createShare(body: .json(info)).created.body.json

            let wrong = try await client.updateShare(identifier: created.identifier, adminToken: "wrong", info: info)
            #expect(try wrong.forbidden.body.applicationProblemJson.status == 403)

            let missing = try await client.updateShare(path: .init(identifier: created.identifier), body: .json(info))
            #expect(try missing.unauthorized.headers.wwwAuthenticate == .bearer)

            let invalid = try await client.createShare(body: .json(.init(iterations: 0, salt: "a", sealed: "b")))
            #expect(try invalid.unprocessableContent.body.applicationProblemJson.status == 422)
        }
    }

    @Test
    func theDeprecatedRoutesStillWork() async throws {
        let info = info
        let replacement = replacement
        try await testApplication { testClient, _ in
            let client = try Client.padlok(serverURL: URL(string: "http://localhost")!, transport: TestClientTransport(client: testClient))
            let created = try await client.createShare(body: .json(info)).created.body.json
            let path = Operations.UpdateShareLegacy.Input.Path(identifier: created.identifier, adminToken: created.adminToken)

            _ = try await client.updateShareLegacy(path: path, body: .json(replacement)).noContent
            #expect(try await client.getShare(path: .init(identifier: created.identifier)).ok.body.json == replacement)
            _ = try await client.deleteShareLegacy(path: .init(identifier: created.identifier, adminToken: created.adminToken)).noContent
        }
    }

    @Test
    func rateLimitsTellWhenToRetry() async throws {
        let info = info
        try await testApplication { testClient, _ in
            let client = try Client.padlok(serverURL: URL(string: "http://localhost")!, transport: TestClientTransport(client: testClient))
            for _ in 0..<20 {
                _ = try await client.createShare(body: .json(info)).created
            }

            let refused = try await client.createShare(body: .json(info))

            #expect(try refused.tooManyRequests.headers.retryAfter == 3600)
        }
    }
}
