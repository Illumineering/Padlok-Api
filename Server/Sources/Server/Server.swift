import Hummingbird
import Logging
import ServiceLifecycle

@main
struct Server {
    static func main() async throws {
        let configuration = try await ServerConfiguration.load()
        var logger = Logger(label: "Padlok")
        logger.logLevel = configuration.logLevel

        let database = Database(configuration: configuration.database, logger: logger)
        do {
            // Before taking traffic: a failed migration stops the process, so the deploy
            // never becomes live and is rolled back.
            try await Migrator(database: database.sql, logger: logger).run(Migrations.all)
        } catch {
            logger.critical("Migrations failed: \(error)")
            try await database.shutdown()
            throw error
        }

        let api = try buildApplication(configuration: configuration, service: APIService(database: database), logger: logger)
        // The API and the database pool run until SIGTERM or SIGINT, then shut down
        // gracefully together: supervisor stops the program with SIGTERM.
        let services = ServiceGroup(
            configuration: .init(
                services: [api, DatabaseService(database: database)],
                gracefulShutdownSignals: [.sigterm, .sigint],
                logger: logger
            )
        )
        try await services.run()
    }
}
