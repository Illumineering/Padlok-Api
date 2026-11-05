import Foundation
import HTTPTypes
import HummingbirdTesting
import NIOCore
import OpenAPIRuntime

/// Carries the generated client's requests to the application under test, so a test can
/// call the API as the apps do.
struct TestClientTransport: ClientTransport {
    let client: any TestClientProtocol
    /// Sent as `X-Real-IP`, as nginx would.
    var clientIP = "192.0.2.1"

    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var buffer: ByteBuffer?
        if let body {
            buffer = ByteBuffer(bytes: try await Data(collecting: body, upTo: 1 << 20))
        }
        var headers = request.headerFields
        headers[HTTPField.Name("X-Real-IP")!] = clientIP
        return try await client.execute(uri: request.path ?? "/", method: request.method, headers: headers, body: buffer) { response in
            (HTTPResponse(status: response.status, headerFields: response.headers), HTTPBody(Data(buffer: response.body)))
        }
    }
}
