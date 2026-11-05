import Hummingbird
import HummingbirdTesting
import Logging

@testable import Server

/// Runs `body` against the application's router, without a network.
func testRouter(
    service: APIService,
    configuration: ServerConfiguration = ServerConfiguration(),
    _ body: @escaping @Sendable (any TestClientProtocol) async throws -> Void
) async throws {
    let app = try buildApplication(configuration: configuration, service: service, logger: Logger(label: "ServerTests"))
    try await app.test(.router, body)
}
