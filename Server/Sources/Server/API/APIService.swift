import Foundation
import Logging
import PadlokAPIServer

/// The handlers for every operation in openapi.yaml.
struct APIService: APIProtocol {
    let shares: SharesRepository
    let rateLimits: RateLimits
    /// When things happen: `created_at`, `updated_at` and rate limits. Injectable for tests.
    let now: @Sendable () -> Date
    /// Whether the database answers. A closure, so that tests need no MariaDB.
    let isDatabaseReachable: @Sendable () async -> Bool

    init(
        shares: SharesRepository,
        now: @escaping @Sendable () -> Date = Date.init,
        isDatabaseReachable: @escaping @Sendable () async -> Bool
    ) {
        self.shares = shares
        self.rateLimits = RateLimits(now: now)
        self.now = now
        self.isDatabaseReachable = isDatabaseReachable
    }

    init(database: Database) {
        self.init(
            shares: SharesRepository(sql: database.sql),
            // Short enough that a monitor or the deploy never waits on a stuck database.
            isDatabaseReachable: { await database.isReachable(within: .seconds(2)) }
        )
    }

    // MARK: - Health

    func getLiveness(_ input: Operations.GetLiveness.Input) async throws -> Operations.GetLiveness.Output {
        .ok(.init(body: .json(.init(status: .ok, version: BuildInfo.version))))
    }

    func getHealth(_ input: Operations.GetHealth.Input) async throws -> Operations.GetHealth.Output {
        let database = await isDatabaseReachable()
        let health = Components.Schemas.Health(
            status: database ? "ok" : "fail",
            checks: .init(additionalProperties: ["database": database ? "ok" : "fail"])
        )
        return database ? .ok(.init(body: .json(health))) : .serviceUnavailable(.init(body: .json(health)))
    }

    // MARK: - Shares

    func createShare(_ input: Operations.CreateShare.Input) async throws -> Operations.CreateShare.Output {
        guard case .json(let body) = input.body else {
            return .badRequest(.init(body: .applicationProblemJson(.init(.badRequest))))
        }
        let info: SharedInfo
        do {
            info = try SharedInfo(validating: body)
        } catch {
            return .unprocessableContent(.init(body: .applicationProblemJson(.init(.unprocessableContent, detail: error.message))))
        }
        let identifier = ShareCredentials.random()
        let adminToken = ShareCredentials.random()
        try await shares.insert(identifier: identifier, info: info, adminTokenHash: AdminToken.hash(adminToken), at: now())
        // Only the hash is stored: this is the one time the token can be returned.
        return .created(.init(body: .json(.init(identifier: identifier, adminToken: adminToken))))
    }

    func getShare(_ input: Operations.GetShare.Input) async throws -> Operations.GetShare.Output {
        guard let share = try await shares.find(identifier: input.path.identifier) else {
            return .notFound(.init(body: .applicationProblemJson(.init(.notFound))))
        }
        let info = share.info
        return .ok(.init(body: .json(.init(iterations: info.iterations, salt: info.salt, sealed: info.sealed))))
    }

    func updateShare(_ input: Operations.UpdateShare.Input) async throws -> Operations.UpdateShare.Output {
        guard case .json(let body) = input.body else {
            return .badRequest(.init(body: .applicationProblemJson(.init(.badRequest))))
        }
        switch try await replace(identifier: input.path.identifier, adminToken: RequestInfo.bearerToken, with: body) {
        case .done: return .noContent(.init())
        case .notFound: return .notFound(.init(body: .applicationProblemJson(.init(.notFound))))
        case .unauthorized: return .unauthorized(Self.unauthorized)
        case .forbidden: return .forbidden(.init(body: .applicationProblemJson(.init(.forbidden))))
        case .tooManyRequests(let wait): return .tooManyRequests(Self.tooManyWrongTokens(wait))
        case .invalid(let message):
            return .unprocessableContent(.init(body: .applicationProblemJson(.init(.unprocessableContent, detail: message))))
        }
    }

    func deleteShare(_ input: Operations.DeleteShare.Input) async throws -> Operations.DeleteShare.Output {
        switch try await delete(identifier: input.path.identifier, adminToken: RequestInfo.bearerToken) {
        case .done: return .noContent(.init())
        case .notFound: return .notFound(.init(body: .applicationProblemJson(.init(.notFound))))
        case .unauthorized: return .unauthorized(Self.unauthorized)
        case .forbidden: return .forbidden(.init(body: .applicationProblemJson(.init(.forbidden))))
        case .tooManyRequests(let wait): return .tooManyRequests(Self.tooManyWrongTokens(wait))
        case .invalid: return .undocumented(statusCode: 500, .init())
        }
    }

    func updateShareLegacy(_ input: Operations.UpdateShareLegacy.Input) async throws -> Operations.UpdateShareLegacy.Output {
        guard case .json(let body) = input.body else {
            return .badRequest(.init(body: .applicationProblemJson(.init(.badRequest))))
        }
        switch try await replace(identifier: input.path.identifier, adminToken: input.path.adminToken, with: body) {
        case .done: return .noContent(.init())
        case .notFound: return .notFound(.init(body: .applicationProblemJson(.init(.notFound))))
        // The token is in the path: there is always one, right or wrong.
        case .unauthorized, .forbidden: return .forbidden(.init(body: .applicationProblemJson(.init(.forbidden))))
        case .tooManyRequests(let wait): return .tooManyRequests(Self.tooManyWrongTokens(wait))
        case .invalid(let message):
            return .unprocessableContent(.init(body: .applicationProblemJson(.init(.unprocessableContent, detail: message))))
        }
    }

    func deleteShareLegacy(_ input: Operations.DeleteShareLegacy.Input) async throws -> Operations.DeleteShareLegacy.Output {
        switch try await delete(identifier: input.path.identifier, adminToken: input.path.adminToken) {
        case .done: return .noContent(.init())
        case .notFound: return .notFound(.init(body: .applicationProblemJson(.init(.notFound))))
        case .unauthorized, .forbidden: return .forbidden(.init(body: .applicationProblemJson(.init(.forbidden))))
        case .tooManyRequests(let wait): return .tooManyRequests(Self.tooManyWrongTokens(wait))
        case .invalid: return .undocumented(statusCode: 500, .init())
        }
    }

    // MARK: - Changing a share

    private enum Outcome {
        case done
        case notFound
        case unauthorized
        case forbidden
        case tooManyRequests(Int)
        case invalid(String)
    }

    private func replace(identifier: String, adminToken: String?, with body: Components.Schemas.SharedInfo) async throws -> Outcome {
        guard let share = try await shares.find(identifier: identifier) else {
            return .notFound
        }
        if let refusal = await authorize(adminToken, for: share) {
            return refusal
        }
        let info: SharedInfo
        do {
            info = try SharedInfo(validating: body)
        } catch {
            return .invalid(error.message)
        }
        try await shares.update(id: share.id, info: info, at: now())
        return .done
    }

    private func delete(identifier: String, adminToken: String?) async throws -> Outcome {
        guard let share = try await shares.find(identifier: identifier) else {
            return .notFound
        }
        if let refusal = await authorize(adminToken, for: share) {
            return refusal
        }
        try await shares.delete(id: share.id)
        return .done
    }

    /// `nil` when `adminToken` may change `share`.
    ///
    /// Wrong tokens are counted per client IP. Once over the limit, every change from that
    /// IP is refused before the token is even compared, so a guess that happens to be
    /// right answers the same as one that is wrong.
    private func authorize(_ adminToken: String?, for share: StoredShare) async -> Outcome? {
        let clientIP = RequestInfo.clientIP
        if let wait = await rateLimits.adminTokenFailures.retryAfter(clientIP) {
            return .tooManyRequests(wait)
        }
        guard let adminToken else {
            return .unauthorized
        }
        guard AdminToken.matches(adminToken, storedHash: share.adminTokenHash) else {
            _ = await rateLimits.adminTokenFailures.consume(clientIP)
            return .forbidden
        }
        return nil
    }

    private static let unauthorized = Components.Responses.Unauthorized(
        headers: .init(wwwAuthenticate: .bearer),
        body: .applicationProblemJson(.init(.unauthorized, detail: "Send the admin token as a Bearer token."))
    )

    private static func tooManyWrongTokens(_ wait: Int) -> Components.Responses.TooManyRequests {
        .init(
            headers: .init(retryAfter: wait),
            body: .applicationProblemJson(.init(.tooManyRequests, detail: "Too many wrong admin tokens from this address, retry later."))
        )
    }
}
