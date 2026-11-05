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
