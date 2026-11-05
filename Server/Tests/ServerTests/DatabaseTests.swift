import Foundation
import Logging
import SQLKit
import Testing

@testable import Server

/// `shared_data` exactly as the Symfony server's Doctrine migrations leave it, from
/// `SHOW CREATE TABLE` after Version20261104234058.
let symfonySharedDataTable: SQLQueryString = """
    CREATE TABLE `shared_data` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `identifier` char(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
      `info` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`info`)),
      `created_at` datetime NOT NULL,
      `updated_at` datetime NOT NULL,
      `admin_token_hash` char(64) NOT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `UNIQ_170598FB772E836A` (`identifier`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    """

@Suite(.enabled(if: TestDatabase.isAvailable, "needs PADLOK_TEST_DB_HOST"))
struct MigrationTests {
    private let logger = Logger(label: "MigrationTests")

    @Test
    func aNewDatabaseGetsTheSymfonyTable() async throws {
        try await TestDatabase.with { migrated in
            try await TestDatabase.with { symfony in
                try await Migrator(database: migrated.sql, logger: logger).run(Migrations.all)
                try await symfony.sql.raw(symfonySharedDataTable).run()

                let migratedTable = try await createTable(in: migrated.sql)
                let symfonyTable = try await createTable(in: symfony.sql)
                #expect(migratedTable == symfonyTable)
            }
        }
    }

    @Test
    func runningAgainChangesNothing() async throws {
        try await TestDatabase.with { database in
            let migrator = Migrator(database: database.sql, logger: logger)
            try await migrator.run(Migrations.all)
            try await migrator.run(Migrations.all)

            let applied = try await database.sql.raw("SELECT id FROM schema_migrations").all(decodingColumn: "id", as: String.self)
            #expect(applied == Migrations.all.map(\.id))
        }
    }

    /// The switch from Symfony: the existing table and its shares stay as they are.
    @Test
    func anExistingSymfonyDatabaseKeepsItsShares() async throws {
        try await TestDatabase.with { database in
            try await database.sql.raw(symfonySharedDataTable).run()
            try await database.sql.raw("CREATE TABLE doctrine_migration_versions (version VARCHAR(191) NOT NULL PRIMARY KEY)").run()
            try await database.sql.raw(
                """
                INSERT INTO shared_data (identifier, info, admin_token_hash, created_at, updated_at)
                VALUES ('3vJ8qLegacy', '{"iterations":1000,"salt":"c2FsdA==","sealed":"c2VhbGVk"}',
                        SHA2('token', 256), '2024-01-01 00:00:00', '2024-01-01 00:00:00')
                """
            ).run()

            try await Migrator(database: database.sql, logger: logger).run(Migrations.all)

            let share = try await SharesRepository(sql: database.sql).find(identifier: "3vJ8qLegacy")
            #expect(share?.info == SharedInfo(iterations: 1000, salt: "c2FsdA==", sealed: "c2VhbGVk"))
            #expect(share?.adminTokenHash == AdminToken.hash("token"))
        }
    }

    private func createTable(in sql: any SQLDatabase) async throws -> String {
        let row = try #require(try await sql.raw("SHOW CREATE TABLE shared_data").first())
        return try row.decode(column: "Create Table", as: String.self)
    }
}

@Suite(.enabled(if: TestDatabase.isAvailable, "needs PADLOK_TEST_DB_HOST"))
struct SharesRepositoryTests {
    private let info = SharedInfo(iterations: 1000, salt: "c2FsdA==", sealed: "c2VhbGVk/+")
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test
    func storesFindsUpdatesAndDeletes() async throws {
        try await withRepository { shares, sql in
            try await shares.insert(identifier: "3vJ8q", info: info, adminTokenHash: AdminToken.hash("Tk9"), at: now)

            let stored = try #require(try await shares.find(identifier: "3vJ8q"))
            #expect(stored.info == info)
            #expect(stored.adminTokenHash == AdminToken.hash("Tk9"))

            let later = now.addingTimeInterval(60)
            let replaced = SharedInfo(iterations: 2000, salt: "bmV3", sealed: "bmV3IGJveA==")
            try await shares.update(id: stored.id, info: replaced, at: later)
            #expect(try await shares.find(identifier: "3vJ8q")?.info == replaced)
            let dates = try #require(try await sql.raw("SELECT created_at, updated_at FROM shared_data").first())
            #expect(try dates.decode(column: "created_at", as: Date.self) == now)
            #expect(try dates.decode(column: "updated_at", as: Date.self) == later)

            try await shares.delete(id: stored.id)
            #expect(try await shares.find(identifier: "3vJ8q") == nil)
        }
    }

    @Test
    func identifiersAreCaseSensitive() async throws {
        try await withRepository { shares, _ in
            try await shares.insert(identifier: "aBc", info: info, adminTokenHash: AdminToken.hash("Tk9"), at: now)

            #expect(try await shares.find(identifier: "aBc") != nil)
            #expect(try await shares.find(identifier: "ABC") == nil)
            #expect(try await shares.find(identifier: "abc") == nil)
        }
    }

    @Test(arguments: ["", "é", "a b", "a/b", String(repeating: "a", count: 37)])
    func implausibleIdentifiersAreNotFound(identifier: String) async throws {
        try await withRepository { shares, _ in
            let found = try await shares.find(identifier: identifier)
            #expect(found == nil)
        }
    }

    @Test
    func olderUUIDIdentifiersAreFound() async throws {
        try await withRepository { shares, _ in
            let identifier = "5f0c3a9e-6c1b-4c39-9a51-0f9f0d6b1e2a"
            try await shares.insert(identifier: identifier, info: info, adminTokenHash: AdminToken.hash("Tk9"), at: now)
            #expect(try await shares.find(identifier: identifier) != nil)
        }
    }

    private func withRepository(_ body: (SharesRepository, any SQLDatabase) async throws -> Void) async throws {
        try await TestDatabase.with { database in
            try await Migrator(database: database.sql, logger: Logger(label: "SharesRepositoryTests")).run(Migrations.all)
            try await body(SharesRepository(sql: database.sql), database.sql)
        }
    }
}
