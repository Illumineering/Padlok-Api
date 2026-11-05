import Logging
import MySQLKit
import NIOPosix
import ServiceLifecycle
import Synchronization

/// Where the database is and how to log in.
struct DatabaseConfiguration: Sendable {
    var host = "127.0.0.1"
    var port = 3306
    var name = "padlok"
    var user = "padlok"
    var password = ""
    /// Per event loop, so per core: tests, which open many pools at once, use one.
    var connectionsPerEventLoop = 4
}

/// The MariaDB connection pool, shared by every request.
///
/// Connections open on first use, so creating one never fails; queries do if the database
/// is unreachable. The pool must be shut down before it is released: `DatabaseService`
/// does it when the application stops, and `shutdown()` may be called again safely.
///
/// `@unchecked`: AsyncKit's pool is not annotated `Sendable`, but guards its state with a
/// lock and is meant to be shared across event loops; `sql` is a `Sendable` existential.
final class Database: @unchecked Sendable {
    private let pools: EventLoopGroupConnectionPool<MySQLConnectionSource>
    private let isShutDown = Mutex(false)
    let sql: any SQLDatabase

    init(configuration: DatabaseConfiguration, logger: Logger) {
        let source = MySQLConnectionSource(
            configuration: MySQLConfiguration(
                hostname: configuration.host,
                port: configuration.port,
                username: configuration.user,
                password: configuration.password,
                database: configuration.name,
                // The database is on the same machine, never across a network.
                tlsConfiguration: nil
            )
        )
        pools = EventLoopGroupConnectionPool(
            source: source,
            maxConnectionsPerEventLoop: configuration.connectionsPerEventLoop,
            pruneInterval: .minutes(1),
            logger: logger,
            on: MultiThreadedEventLoopGroup.singleton
        )
        sql = pools.database(logger: logger).sql()
    }

    /// Whether the database answers a trivial query within `timeout`.
    ///
    /// `false` as well when it does not answer in time, rather than waiting on a
    /// connection that may never respond.
    func isReachable(within timeout: Duration) async -> Bool {
        let sql = sql
        return await firstResult(within: timeout) {
            (try? await sql.raw("SELECT 1").run()) != nil
        } ?? false
    }

    /// Closes every connection. Only the first call does anything: the pool refuses a
    /// second shutdown.
    func shutdown() async throws {
        let isFirst = isShutDown.withLock { isShutDown in
            defer { isShutDown = true }
            return !isShutDown
        }
        guard isFirst else {
            return
        }
        try await pools.shutdownAsync()
    }
}

/// Closes the pool when the server shuts down.
struct DatabaseService: Service {
    let database: Database

    func run() async throws {
        try? await gracefulShutdown()
        try await database.shutdown()
    }
}
