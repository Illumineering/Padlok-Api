import Foundation
import HTTPTypes
import Hummingbird
import HummingbirdTesting
import Logging
import NIOCore
import Synchronization

@testable import Server

/// Runs `body` against the application's router, without a network, with the database
/// answering or not as told. The pool only connects on a first query, so these tests
/// need no MariaDB; it still has to be shut down.
func testRouter(
    databaseReachable: Bool = true,
    configuration: ServerConfiguration = ServerConfiguration(),
    _ body: @escaping @Sendable (any TestClientProtocol) async throws -> Void
) async throws {
    let logger = Logger(label: "ServerTests")
    let database = Database(configuration: configuration.database, logger: logger)
    let service = APIService(shares: SharesRepository(sql: database.sql), isDatabaseReachable: { databaseReachable })
    do {
        let app = try buildApplication(configuration: configuration, service: service, logger: logger)
        try await app.test(.router, body)
    } catch {
        try await database.shutdown()
        throw error
    }
    try await database.shutdown()
}

/// Runs `body` against the application, on a throwaway migrated database, with time
/// standing still until `clock` moves it.
func testApplication(
    clock: TestClock = TestClock(),
    configuration: ServerConfiguration = ServerConfiguration(),
    _ body: @escaping @Sendable (any TestClientProtocol, Database) async throws -> Void
) async throws {
    try await TestDatabase.with { database in
        let logger = Logger(label: "ServerTests")
        try await Migrator(database: database.sql, logger: logger).run(Migrations.all)
        let service = APIService(shares: SharesRepository(sql: database.sql), now: clock.now, isDatabaseReachable: { true })
        let app = try buildApplication(configuration: configuration, service: service, logger: logger)
        try await app.test(.router) { client in
            try await body(client, database)
        }
    }
}

/// A clock that only moves when told to.
final class TestClock: Sendable {
    private let current: Mutex<Date>

    init(_ start: Date = Date(timeIntervalSince1970: 1_800_000_000)) {
        current = Mutex(start)
    }

    var now: @Sendable () -> Date {
        { self.current.withLock { $0 } }
    }

    func advance(by interval: TimeInterval) {
        current.withLock { $0 = $0.addingTimeInterval(interval) }
    }
}

extension TestClientProtocol {
    /// `body` encoded as JSON, from a dictionary so that tests can send what the
    /// generated types never would: missing fields, wrong types.
    func execute(
        uri: String,
        method: HTTPRequest.Method,
        headers: HTTPFields = [:],
        json: [String: Any]
    ) async throws -> TestResponse {
        var headers = headers
        headers[.contentType] = "application/json"
        let data = try JSONSerialization.data(withJSONObject: json)
        return try await execute(uri: uri, method: method, headers: headers, body: ByteBuffer(bytes: data))
    }
}

extension TestResponse {
    var json: [String: Any]? {
        (try? JSONSerialization.jsonObject(with: Data(buffer: body))) as? [String: Any]
    }

    var text: String {
        String(buffer: body)
    }
}
