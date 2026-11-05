import Foundation
import HTTPTypes

// swift-openapi-generator ignores security schemes: the generated `updateShare` and
// `deleteShare` have no way to send the admin token. The wrappers below take it as an
// argument, and a middleware sends it as `Authorization: Bearer`.

extension Client {
    /// A client for the Padlok API, able to send the admin tokens given to
    /// ``updateShare(identifier:adminToken:info:)`` and ``deleteShare(identifier:adminToken:)``.
    ///
    /// The token is added after `middlewares` have run, so none of them sees it, a logging
    /// middleware included.
    ///
    /// - Parameter serverURL: `Servers.Server1.url()` for production,
    ///   `Servers.Server2.url()` for development.
    public static func padlok(
        serverURL: URL,
        transport: any ClientTransport,
        middlewares: [any ClientMiddleware] = []
    ) -> Client {
        Client(serverURL: serverURL, transport: transport, middlewares: middlewares + [AdminTokenMiddleware()])
    }

    /// Replaces a sealed address. Requires a client made by ``padlok(serverURL:transport:middlewares:)``.
    public func updateShare(
        identifier: String,
        adminToken: String,
        info: Components.Schemas.SharedInfo
    ) async throws -> Operations.UpdateShare.Output {
        try await AdminToken.$current.withValue(adminToken) {
            try await updateShare(path: .init(identifier: identifier), body: .json(info))
        }
    }

    /// Deletes a sealed address. Requires a client made by ``padlok(serverURL:transport:middlewares:)``.
    /// A share already gone answers `.notFound`, which callers should take as deleted.
    public func deleteShare(identifier: String, adminToken: String) async throws -> Operations.DeleteShare.Output {
        try await AdminToken.$current.withValue(adminToken) {
            try await deleteShare(path: .init(identifier: identifier))
        }
    }
}

/// The admin token of the call in progress, set by the wrappers above for the duration
/// of their call only.
enum AdminToken {
    @TaskLocal static var current: String?
}

struct AdminTokenMiddleware: ClientMiddleware {
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        guard let token = AdminToken.current else {
            return try await next(request, body, baseURL)
        }
        var request = request
        request.headerFields[.authorization] = "Bearer \(token)"
        return try await next(request, body, baseURL)
    }
}
