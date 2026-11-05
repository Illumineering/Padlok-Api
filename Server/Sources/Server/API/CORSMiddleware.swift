import Foundation
import HTTPTypes
import Hummingbird

/// Lets the browser origins matching `allowedOrigin` call the API, as nelmio/cors-bundle
/// did for the Symfony server: the pattern is matched case-insensitively against the
/// `Origin` header.
struct OriginPatternCORSMiddleware<Context: RequestContext>: RouterMiddleware {
    private let pattern: NSRegularExpression

    init(allowedOrigin: String) throws {
        pattern = try NSRegularExpression(pattern: allowedOrigin, options: [.caseInsensitive])
    }

    func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        guard let origin = request.headers[.origin] else {
            return try await next(request, context)
        }
        let allowed = isAllowed(origin)
        if request.method == .options, request.headers[.accessControlRequestMethod] != nil {
            var headers: HTTPFields = [.vary: "Origin"]
            if allowed {
                headers[.accessControlAllowOrigin] = origin
                headers[.accessControlAllowMethods] = "GET, OPTIONS, POST, PUT, DELETE"
                headers[.accessControlAllowHeaders] = "Content-Type, Authorization"
                headers[.accessControlMaxAge] = "3600"
            }
            return Response(status: .noContent, headers: headers)
        }
        var response = try await next(request, context)
        if allowed {
            response.headers[.accessControlAllowOrigin] = origin
            response.headers[values: .vary].append("Origin")
        }
        return response
    }

    func isAllowed(_ origin: String) -> Bool {
        pattern.firstMatch(in: origin, range: NSRange(origin.startIndex..., in: origin)) != nil
    }
}
