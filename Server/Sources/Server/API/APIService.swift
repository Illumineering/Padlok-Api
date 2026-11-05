import Foundation
import Logging
import PadlokAPIServer

/// The handlers for every operation in openapi.yaml.
struct APIService: APIProtocol {
    /// Whether the database answers. A closure, so that tests need no MariaDB.
    let isDatabaseReachable: @Sendable () async -> Bool

    init(isDatabaseReachable: @escaping @Sendable () async -> Bool) {
        self.isDatabaseReachable = isDatabaseReachable
    }

    init(database: Database) {
        // Short enough that a monitor or the deploy never waits on a stuck database.
        self.init(isDatabaseReachable: { await database.isReachable(within: .seconds(2)) })
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
        .notImplemented
    }

    func getShare(_ input: Operations.GetShare.Input) async throws -> Operations.GetShare.Output {
        .notImplemented
    }

    func updateShare(_ input: Operations.UpdateShare.Input) async throws -> Operations.UpdateShare.Output {
        .notImplemented
    }

    func deleteShare(_ input: Operations.DeleteShare.Input) async throws -> Operations.DeleteShare.Output {
        .notImplemented
    }

    func updateShareLegacy(_ input: Operations.UpdateShareLegacy.Input) async throws -> Operations.UpdateShareLegacy.Output {
        .notImplemented
    }

    func deleteShareLegacy(_ input: Operations.DeleteShareLegacy.Input) async throws -> Operations.DeleteShareLegacy.Output {
        .notImplemented
    }
}
