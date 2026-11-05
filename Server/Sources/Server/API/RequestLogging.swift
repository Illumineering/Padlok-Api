import Hummingbird
import Logging

/// Logs requests at debug level, with the admin token of the legacy routes
/// (`/shared/{identifier}/{admin_token}`) redacted. Bearer tokens travel in a header,
/// which is never logged. nginx writes the access log, with the same redaction.
struct LogRequestsWithoutTokens<Context: RequestContext>: RouterMiddleware {
    static var redacted: String { "[redacted]" }

    func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        context.logger.debug(
            "Request",
            metadata: ["hb.request.method": "\(request.method)", "hb.request.path": "\(Self.redact(request.uri.path))"]
        )
        return try await next(request, context)
    }

    /// `path` with everything after `/shared/{identifier}/` replaced.
    static func redact(_ path: String) -> String {
        let segments = path.split(separator: "/", omittingEmptySubsequences: false)
        // "", "shared", identifier, admin_token…
        guard segments.count > 3, segments[1] == "shared" else {
            return path
        }
        return (segments.prefix(3) + [Substring(redacted)]).joined(separator: "/")
    }
}
