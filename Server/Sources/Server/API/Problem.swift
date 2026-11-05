import Foundation
import HTTPTypes
import PadlokAPIServer

/// RFC 9457 problem details, the body of every error.
extension Components.Schemas.Problem {
    init(_ status: HTTPResponse.Status, detail: String? = nil) {
        self.init(title: status.reasonPhrase, status: status.code, detail: detail)
    }

    /// The whole response, for middlewares that answer before an operation's handler.
    static func response(
        _ status: HTTPResponse.Status,
        detail: String? = nil,
        headerFields: HTTPFields = [:]
    ) -> (HTTPResponse, HTTPBody) {
        var fields = headerFields
        fields[.contentType] = "application/problem+json"
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let body = (try? encoder.encode(Self(status, detail: detail))) ?? Data()
        return (HTTPResponse(status: status, headerFields: fields), HTTPBody(body))
    }
}
