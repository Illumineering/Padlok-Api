import Logging
import SQLKit

/// A change to the schema, applied once.
///
/// MariaDB cannot roll back DDL, while a deploy can roll back the binary to the previous
/// release. So a migration must leave a schema the previous release still works with:
/// add tables and columns first, and remove them only in a later release, once nothing
/// reads them. Prefer one statement per migration, so a failure cannot leave one half
/// applied.
struct Migration: Sendable {
    /// Applied in this order, and never renamed once deployed: `0001-shared-data`.
    let id: String
    let statements: [SQLQueryString]
}

/// Applies the migrations not yet recorded in `schema_migrations`, in order.
///
/// Run at startup, before the server takes traffic: if a migration fails, the process
/// exits, /healthz never answers, and padlok-activate rolls the deploy back.
struct Migrator {
    let database: any SQLDatabase
    let logger: Logger

    func run(_ migrations: [Migration]) async throws {
        try await database.raw(
            """
            CREATE TABLE IF NOT EXISTS schema_migrations (
                id VARCHAR(191) NOT NULL PRIMARY KEY,
                applied_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """
        ).run()

        let applied = Set(
            try await database.raw("SELECT id FROM schema_migrations").all(decodingColumn: "id", as: String.self)
        )
        for migration in migrations where !applied.contains(migration.id) {
            logger.notice("Applying migration \(migration.id)")
            for statement in migration.statements {
                try await database.raw(statement).run()
            }
            try await database.raw("INSERT INTO schema_migrations (id) VALUES (\(bind: migration.id))").run()
        }
    }
}
