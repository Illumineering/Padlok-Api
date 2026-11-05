import Foundation
import HTTPTypes
import PadlokAPIClient
import Testing

@Suite struct ClientTests {
    private let info = Components.Schemas.SharedInfo(iterations: 1000, salt: "c2FsdA==", sealed: "c2VhbGVk")

    @Test func createSendsTheSealedAddressAndReadsTheAdminToken() async throws {
        let transport = RecordingTransport(status: .created, json: #"{"identifier":"3vJ8q","admin_token":"Tk9"}"#)
        let client = try Client.padlok(serverURL: Servers.Server1.url(), transport: transport)

        let created = try await client.createShare(body: .json(info)).created.body.json

        #expect(created == .init(identifier: "3vJ8q", adminToken: "Tk9"))
        let request = try #require(await transport.requests.first)
        #expect(request.method == .post)
        #expect(request.url == "https://api.padlok.app/share")
        #expect(request.headerFields[.authorization] == nil)
        let body = try JSONSerialization.jsonObject(with: request.body) as? [String: Any]
        #expect(body?["iterations"] as? Int == 1000)
        #expect(body?["salt"] as? String == "c2FsdA==")
        #expect(body?["sealed"] as? String == "c2VhbGVk")
    }

    @Test func updateSendsTheAdminTokenAsABearerToken() async throws {
        let transport = RecordingTransport(status: .noContent)
        let client = try Client.padlok(serverURL: Servers.Server1.url(), transport: transport)

        _ = try await client.updateShare(identifier: "3vJ8q", adminToken: "Tk9", info: info).noContent

        let request = try #require(await transport.requests.first)
        #expect(request.method == .put)
        #expect(request.url == "https://api.padlok.app/shared/3vJ8q")
        #expect(request.headerFields[.authorization] == "Bearer Tk9")
    }

    @Test func deleteSendsTheAdminTokenAsABearerToken() async throws {
        let transport = RecordingTransport(status: .noContent)
        let client = try Client.padlok(serverURL: Servers.Server1.url(), transport: transport)

        _ = try await client.deleteShare(identifier: "3vJ8q", adminToken: "Tk9").noContent

        let request = try #require(await transport.requests.first)
        #expect(request.method == .delete)
        #expect(request.url == "https://api.padlok.app/shared/3vJ8q")
        #expect(request.headerFields[.authorization] == "Bearer Tk9")
    }

    @Test func otherMiddlewaresNeverSeeTheAdminToken() async throws {
        let transport = RecordingTransport(status: .noContent)
        let spy = HeaderSpy()
        let client = try Client.padlok(serverURL: Servers.Server1.url(), transport: transport, middlewares: [spy])

        _ = try await client.deleteShare(identifier: "3vJ8q", adminToken: "Tk9")

        #expect(await spy.authorizations == [nil])
        #expect(await transport.requests.first?.headerFields[.authorization] == "Bearer Tk9")
    }

    @Test func theTokenIsOnlySentByTheCallItWasGivenTo() async throws {
        let transport = RecordingTransport(status: .noContent)
        let client = try Client.padlok(serverURL: Servers.Server1.url(), transport: transport)

        _ = try await client.deleteShare(identifier: "3vJ8q", adminToken: "Tk9")
        _ = try await client.updateShare(path: .init(identifier: "3vJ8q"), body: .json(info))

        #expect(await transport.requests.map { $0.headerFields[.authorization] } == ["Bearer Tk9", nil])
    }

    @Test func getReadsTheSealedAddress() async throws {
        let transport = RecordingTransport(status: .ok, json: #"{"iterations":1000,"salt":"c2FsdA==","sealed":"c2VhbGVk"}"#)
        let client = try Client.padlok(serverURL: Servers.Server1.url(), transport: transport)

        let shared = try await client.getShare(path: .init(identifier: "3vJ8q")).ok.body.json

        #expect(shared == info)
        #expect(await transport.requests.first?.url == "https://api.padlok.app/shared/3vJ8q")
    }

    @Test func aMissingShareIsNotFound() async throws {
        let transport = RecordingTransport(
            status: .notFound,
            contentType: "application/problem+json",
            json: #"{"title":"Not Found","status":404}"#
        )
        let client = try Client.padlok(serverURL: Servers.Server1.url(), transport: transport)

        let output = try await client.getShare(path: .init(identifier: "3vJ8q"))

        #expect(try output.notFound.body.applicationProblemJson.status == 404)
    }

    @Test func rateLimitsTellWhenToRetry() async throws {
        let transport = RecordingTransport(
            status: .tooManyRequests,
            headers: [.retryAfter: "120"],
            contentType: "application/problem+json",
            json: #"{"title":"Too Many Requests","status":429}"#
        )
        let client = try Client.padlok(serverURL: Servers.Server1.url(), transport: transport)

        let output = try await client.createShare(body: .json(info))

        #expect(try output.tooManyRequests.headers.retryAfter == 120)
    }

    @Test func unknownFieldsAreIgnored() async throws {
        let transport = RecordingTransport(
            status: .created,
            json: #"{"identifier":"3vJ8q","admin_token":"Tk9","expires_at":"2027-01-01T00:00:00Z"}"#
        )
        let client = try Client.padlok(serverURL: Servers.Server1.url(), transport: transport)

        let created = try await client.createShare(body: .json(info)).created.body.json

        #expect(created.identifier == "3vJ8q")
    }
}

/// A request as the transport received it.
struct RecordedRequest: Sendable {
    let method: HTTPRequest.Method
    let url: String
    let headerFields: HTTPFields
    let body: Data
}

/// Answers every request with the same response, and keeps the requests.
actor RecordingTransport: ClientTransport {
    private(set) var requests: [RecordedRequest] = []
    private let response: HTTPResponse
    private let json: String?

    init(
        status: HTTPResponse.Status,
        headers: HTTPFields = [:],
        contentType: String = "application/json",
        json: String? = nil
    ) {
        var headerFields = headers
        if json != nil {
            headerFields[.contentType] = contentType
        }
        self.response = HTTPResponse(status: status, headerFields: headerFields)
        self.json = json
    }

    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let data: Data
        if let body {
            data = try await Data(collecting: body, upTo: 1 << 20)
        } else {
            data = Data()
        }
        let url = baseURL.absoluteString + (request.path ?? "")
        requests.append(RecordedRequest(method: request.method, url: url, headerFields: request.headerFields, body: data))
        return (response, json.map { HTTPBody($0) })
    }
}

/// Records the `Authorization` header of each request it passes on.
actor HeaderSpy: ClientMiddleware {
    private(set) var authorizations: [String?] = []

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        authorizations.append(request.headerFields[.authorization])
        return try await next(request, body, baseURL)
    }
}
