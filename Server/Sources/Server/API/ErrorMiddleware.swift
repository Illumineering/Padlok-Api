import Foundation
import HTTPTypes
import Logging
import PadlokAPIServer

/// Turns every error into a problem details response, so none reaches Hummingbird.
///
/// - A request that does not make an operation's input: 422 when the JSON body lacks a
///   field or has one of the wrong type, as the Symfony server answered; otherwise the
///   runtime's own status (400 for a body that is not JSON, 415 for another content type).
/// - Anything else is the server's fault: 500, logged with the operation, never the
///   request's path, which may hold an admin token.
struct ErrorMiddleware: ServerMiddleware {
    let logger: Logger

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        metadata: ServerRequestMetadata,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        do {
            return try await next(request, body, metadata)
        } catch let error as ServerError where error.operationInput == nil {
            if let decoding = error.underlyingError as? DecodingError {
                return Components.Schemas.Problem.response(Self.status(of: decoding), detail: Self.detail(of: decoding))
            }
            let status = error.httpStatus.kind == .clientError ? error.httpStatus : .badRequest
            return Components.Schemas.Problem.response(status)
        } catch {
            let underlying = (error as? ServerError)?.underlyingError ?? error
            logger.error("Request failed", metadata: ["operation": "\(operationID)", "error": "\(String(reflecting: underlying))"])
            return Components.Schemas.Problem.response(.internalServerError)
        }
    }

    static func status(of error: DecodingError) -> HTTPResponse.Status {
        switch error {
        case .keyNotFound, .valueNotFound, .typeMismatch: .unprocessableContent
        case .dataCorrupted: .badRequest
        @unknown default: .badRequest
        }
    }

    /// Which field is wrong, never its value.
    static func detail(of error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, _): "\(key.stringValue) is missing."
        case .valueNotFound(_, let context), .typeMismatch(_, let context):
            "\(context.codingPath.map(\.stringValue).joined(separator: ".")) is not of the expected type."
        case .dataCorrupted: "The body is not valid JSON."
        @unknown default: "The body cannot be read."
        }
    }
}
