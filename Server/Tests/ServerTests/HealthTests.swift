import Foundation
import Hummingbird
import HummingbirdTesting
import Logging
import Testing

@testable import Server

struct HealthTests {
    /// The deploy reads `version` from /livez to check that it actually switched releases.
    /// It must answer even when the database does not: rolling back cannot fix an outage.
    @Test
    func livezAnswersWhateverTheDatabase() async throws {
        try await testRouter(databaseReachable: false) { client in
            try await client.execute(uri: "/livez", method: .get) { response in
                #expect(response.status == .ok)
                #expect(response.headers[.cacheControl] == "no-store")
                #expect(String(buffer: response.body) == #"{"status":"ok","version":"dev"}"#)
            }
        }
    }

    @Test
    func healthzReportsTheDatabase() async throws {
        try await testRouter(databaseReachable: true) { client in
            try await client.execute(uri: "/healthz", method: .get) { response in
                #expect(response.status == .ok)
                #expect(response.headers[.cacheControl] == "no-store")
                #expect(String(buffer: response.body) == #"{"checks":{"database":"ok"},"status":"ok"}"#)
            }
        }
    }

    @Test
    func healthzFailsWhenTheDatabaseDoesNotAnswer() async throws {
        try await testRouter(databaseReachable: false) { client in
            try await client.execute(uri: "/healthz", method: .get) { response in
                #expect(response.status == .serviceUnavailable)
                #expect(response.headers[.cacheControl] == "no-store")
                #expect(String(buffer: response.body) == #"{"checks":{"database":"fail"},"status":"fail"}"#)
            }
        }
    }
}

struct TimeoutTests {
    @Test
    func returnsTheResultWhenInTime() async {
        let result = await firstResult(within: .seconds(2)) { 42 }
        #expect(result == 42)
    }

    /// The operation keeps running in the background; the caller does not wait for it.
    @Test
    func givesUpOnceTheTimeoutHasPassed() async {
        let clock = ContinuousClock()
        let start = clock.now
        let result = await firstResult(within: .milliseconds(100)) { () -> Int in
            try? await Task.sleep(for: .seconds(30))
            return 42
        }
        #expect(result == nil)
        #expect(clock.now - start < .seconds(10))
    }
}

struct DatabaseReachabilityTests {
    private let logger = Logger(label: "DatabaseReachabilityTests")

    /// Nothing listens on port 1: the connection is refused at once.
    @Test
    func aRefusedConnectionIsUnreachable() async throws {
        let database = Database(configuration: DatabaseConfiguration(port: 1), logger: logger)
        #expect(await database.isReachable(within: .seconds(2)) == false)
        try await database.shutdown()
    }

    @Test(.enabled(if: TestDatabase.isAvailable, "needs PADLOK_TEST_DB_HOST"))
    func aRunningDatabaseIsReachable() async throws {
        try await TestDatabase.with { database in
            #expect(await database.isReachable(within: .seconds(2)))
        }
    }
}
