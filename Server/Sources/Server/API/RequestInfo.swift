import HTTPTypes
import PadlokAPIServer

/// What the handlers need from the request beyond the operation's input: the generated
/// inputs carry neither the client's address nor the `Authorization` header.
enum RequestInfo {
    /// The client's IP, from `X-Real-IP`: nginx sets it, overwriting whatever the client
    /// sent, and the server only listens on localhost. `unknown` without it, which only
    /// happens locally and in tests.
    @TaskLocal static var clientIP = "unknown"
    /// The token of a `Bearer` authorization, if the request sent a well-formed one.
    @TaskLocal static var bearerToken: String?
}

/// Reads the client's IP and Bearer token into `RequestInfo` for the rest of the request.
struct RequestInfoMiddleware: ServerMiddleware {
    static let realIP = HTTPField.Name("X-Real-IP")!

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        metadata: ServerRequestMetadata,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let clientIP = request.headerFields[Self.realIP].flatMap { $0.isEmpty ? nil : $0 } ?? "unknown"
        let token = request.headerFields[.authorization].flatMap(Self.bearerToken(from:))
        return try await RequestInfo.$clientIP.withValue(clientIP) {
            try await RequestInfo.$bearerToken.withValue(token) {
                try await next(request, body, metadata)
            }
        }
    }

    /// The token of `Bearer <token>`, the scheme case-insensitive (RFC 9110). `nil` for any
    /// other scheme, or a token with spaces in it.
    static func bearerToken(from authorization: String) -> String? {
        let parts = authorization.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count == 2, parts[0].lowercased() == "bearer" else {
            return nil
        }
        let token = String(parts[1])
        // Tokens are 22 characters; anything far longer is not one, and is not worth hashing.
        guard token.utf8.count <= 256 else {
            return nil
        }
        return token
    }
}
