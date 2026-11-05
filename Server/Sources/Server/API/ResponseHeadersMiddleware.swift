import Foundation
import HTTPTypes
import PadlokAPIServer

/// Marks every response `no-store`: shares are personal, errors and health checks are
/// not worth caching either.
///
/// Also undoes the percent-encoding swift-openapi-runtime applies to the string headers
/// the spec declares: it would send `no-store` intact, but a value with a comma or a
/// space would go out mangled.
struct ResponseHeadersMiddleware: ServerMiddleware {
    private static let plainTextHeaders: [HTTPField.Name] = [.cacheControl, .wwwAuthenticate]

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        metadata: ServerRequestMetadata,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var (response, responseBody) = try await next(request, body, metadata)
        for name in Self.plainTextHeaders {
            if let value = response.headerFields[name], let decoded = value.removingPercentEncoding {
                response.headerFields[name] = decoded
            }
        }
        response.headerFields[.cacheControl] = "no-store"
        return (response, responseBody)
    }
}
