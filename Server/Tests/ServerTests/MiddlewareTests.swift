import Foundation
import HTTPTypes
import Hummingbird
import HummingbirdTesting
import Testing

@testable import Server

struct CORSTests {
    private var configuration: ServerConfiguration {
        var configuration = ServerConfiguration()
        configuration.corsAllowedOrigin = #"^https?://(localhost|127\.0\.0\.1)(:[0-9]+)?$"#
        return configuration
    }

    @Test
    func preflightsFromAllowedOriginsAreAnswered() async throws {
        try await testRouter(configuration: configuration) { client in
            let headers: HTTPFields = [.origin: "http://localhost:3000", .accessControlRequestMethod: "PUT"]
            try await client.execute(uri: "/shared/abc", method: .options, headers: headers) { response in
                #expect(response.status == .noContent)
                #expect(response.headers[.accessControlAllowOrigin] == "http://localhost:3000")
                #expect(response.headers[.accessControlAllowMethods] == "GET, OPTIONS, POST, PUT, DELETE")
                #expect(response.headers[.accessControlAllowHeaders] == "Content-Type, Authorization")
                #expect(response.headers[.accessControlMaxAge] == "3600")
            }
        }
    }

    @Test
    func otherOriginsGetNoCORSHeaders() async throws {
        try await testRouter(configuration: configuration) { client in
            let preflight: HTTPFields = [.origin: "https://evil.example", .accessControlRequestMethod: "PUT"]
            try await client.execute(uri: "/shared/abc", method: .options, headers: preflight) { response in
                #expect(response.headers[.accessControlAllowOrigin] == nil)
            }
            try await client.execute(uri: "/livez", method: .get, headers: [.origin: "https://evil.example"]) { response in
                #expect(response.status == .ok)
                #expect(response.headers[.accessControlAllowOrigin] == nil)
            }
        }
    }

    @Test
    func responsesToAllowedOriginsSayWhoMayReadThem() async throws {
        try await testRouter(configuration: configuration) { client in
            try await client.execute(uri: "/livez", method: .get, headers: [.origin: "http://127.0.0.1:8000"]) { response in
                #expect(response.headers[.accessControlAllowOrigin] == "http://127.0.0.1:8000")
                #expect(response.headers[values: .vary].contains("Origin"))
            }
        }
    }

    @Test
    func withoutConfigurationNoOriginIsAllowed() async throws {
        try await testRouter { client in
            try await client.execute(uri: "/livez", method: .get, headers: [.origin: "http://localhost:3000"]) { response in
                #expect(response.headers[.accessControlAllowOrigin] == nil)
            }
        }
    }
}

struct ErrorTests {
    /// Nothing listens on port 1: every query fails at once.
    @Test
    func aDatabaseFailureIsAServerErrorWithoutDetails() async throws {
        var configuration = ServerConfiguration()
        configuration.database.port = 1
        try await testRouter(configuration: configuration) { client in
            try await client.execute(uri: "/shared/abc", method: .get) { response in
                #expect(response.status == .internalServerError)
                #expect(response.headers[.contentType] == "application/problem+json")
                #expect(response.headers[.cacheControl] == "no-store")
                #expect(String(buffer: response.body) == #"{"status":500,"title":"Internal Server Error"}"#)
            }
        }
    }

    @Test
    func unknownRoutesAreNotFound() async throws {
        try await testRouter { client in
            try await client.execute(uri: "/nope", method: .get) { response in
                #expect(response.status == .notFound)
            }
        }
    }
}

struct LoggingTests {
    @Test(arguments: [
        ("/shared/abc/Tk9secret", "/shared/abc/[redacted]"),
        ("/shared/abc/Tk9secret/more", "/shared/abc/[redacted]"),
        ("/shared/abc", "/shared/abc"),
        ("/share", "/share"),
        ("/healthz", "/healthz"),
    ])
    func legacyAdminTokensAreRedacted(path: String, logged: String) {
        #expect(LogRequestsWithoutTokens<BasicRequestContext>.redact(path) == logged)
    }

    @Test(
        arguments: [
            ("Bearer Tk9", "Tk9"),
            ("bearer Tk9", "Tk9"),
            ("BEARER   Tk9", "Tk9"),
            ("Basic Tk9", nil),
            ("Bearer", nil),
            ("Bearer a b", nil),
            ("Tk9", nil),
        ] as [(String, String?)])
    func bearerTokensAreReadFromTheHeader(authorization: String, token: String?) {
        #expect(RequestInfoMiddleware.bearerToken(from: authorization) == token)
    }
}
