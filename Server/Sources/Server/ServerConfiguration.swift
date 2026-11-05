import Configuration
import Foundation
import Logging

/// Everything the server reads from its environment.
///
/// Keys map to environment variables: `padlok.port` is read from `PADLOK_PORT`. In
/// production, supervisor passes them from /etc/padlok/<environment>.env. Locally, a
/// `.env` file in the working directory is read too, the process environment winning
/// over it.
struct ServerConfiguration: Sendable {
    /// Defaults to localhost: nginx is the only way in.
    var host = "127.0.0.1"
    var port = 8080
    var logLevel = Logger.Level.info
    var database = DatabaseConfiguration()
    /// Browser origins allowed to call the API, as a regular expression matched against
    /// the whole `Origin` header. None by default: the apps are not browsers.
    var corsAllowedOrigin: String?

    init() {}

    init(reader: ConfigReader) {
        host = reader.string(forKey: "padlok.host", default: host)
        port = reader.int(forKey: "padlok.port", default: port)
        logLevel = reader.string(forKey: "padlok.log.level", as: Logger.Level.self, default: logLevel)
        database.host = reader.string(forKey: "padlok.db.host", default: database.host)
        database.port = reader.int(forKey: "padlok.db.port", default: database.port)
        database.name = reader.string(forKey: "padlok.db.name", default: database.name)
        database.user = reader.string(forKey: "padlok.db.user", default: database.user)
        database.password = reader.string(forKey: "padlok.db.password", isSecret: true, default: database.password)
        corsAllowedOrigin = reader.string(forKey: "padlok.cors.allow-origin").flatMap { $0.isEmpty ? nil : $0 }
    }

    static func load() async throws -> ServerConfiguration {
        let reader = ConfigReader(providers: [
            EnvironmentVariablesProvider(),
            // A local convenience only: there is no .env file in production.
            try await EnvironmentVariablesProvider(environmentFilePath: ".env", allowMissing: true),
        ])
        return ServerConfiguration(reader: reader)
    }
}
