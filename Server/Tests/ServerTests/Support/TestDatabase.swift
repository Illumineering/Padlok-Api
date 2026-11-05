import Foundation
import Logging
import SQLKit

@testable import Server

/// A throwaway MariaDB database for one test.
///
/// Tests that need it are enabled only when `PADLOK_TEST_DB_HOST` is set: locally, start
/// compose.yaml and run `PADLOK_TEST_DB_HOST=127.0.0.1 swift test` (port 3308 by default);
/// CI sets host and port for its MariaDB service. Each test gets its own database, created
/// as root and dropped after.
enum TestDatabase {
    static var isAvailable: Bool {
        environment["PADLOK_TEST_DB_HOST"] != nil
    }

    /// Pools grow up to one connection per core: a few test databases at a time keep
    /// MariaDB under its 151 connections, however many tests run in parallel.
    private static let slots = AsyncSemaphore(4)

    static func with(_ body: (Database) async throws -> Void) async throws {
        await slots.wait()
        do {
            try await withSlot(body)
        } catch {
            await slots.signal()
            throw error
        }
        await slots.signal()
    }

    private static func withSlot(_ body: (Database) async throws -> Void) async throws {
        let name = "padlok_test_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16).lowercased())"
        let logger = Logger(label: "TestDatabase")

        let admin = Database(configuration: configuration(database: "mysql"), logger: logger)
        try await admin.sql.raw("CREATE DATABASE \(ident: name) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci").run()
        let database = Database(configuration: configuration(database: name), logger: logger)

        do {
            try await body(database)
        } catch {
            try await tearDown(database: database, admin: admin, name: name)
            throw error
        }
        try await tearDown(database: database, admin: admin, name: name)
    }

    private static func tearDown(database: Database, admin: Database, name: String) async throws {
        try await database.shutdown()
        try await admin.sql.raw("DROP DATABASE IF EXISTS \(ident: name)").run()
        try await admin.shutdown()
    }

    private static func configuration(database: String) -> DatabaseConfiguration {
        DatabaseConfiguration(
            host: environment["PADLOK_TEST_DB_HOST"] ?? "127.0.0.1",
            port: environment["PADLOK_TEST_DB_PORT"].flatMap(Int.init) ?? 3308,
            name: database,
            user: environment["PADLOK_TEST_DB_USER"] ?? "root",
            password: environment["PADLOK_TEST_DB_PASSWORD"] ?? "padlok",
            // Tests run in parallel, each with its pools: stay under max_connections.
            connectionsPerEventLoop: 1
        )
    }

    private static var environment: [String: String] {
        ProcessInfo.processInfo.environment
    }
}

/// Lets `count` tasks through at a time; the others wait their turn, in order.
actor AsyncSemaphore {
    private var available: Int
    private var waiting: [CheckedContinuation<Void, Never>] = []

    init(_ count: Int) {
        available = count
    }

    func wait() async {
        if available > 0 {
            available -= 1
            return
        }
        await withCheckedContinuation { waiting.append($0) }
    }

    func signal() {
        if waiting.isEmpty {
            available += 1
        } else {
            waiting.removeFirst().resume()
        }
    }
}
