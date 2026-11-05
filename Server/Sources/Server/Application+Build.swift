import Hummingbird
import Logging
import OpenAPIHummingbird
import PadlokAPIServer

func buildApplication(
    configuration: ServerConfiguration,
    service: APIService,
    logger: Logger
) throws -> some ApplicationProtocol {
    let router = Router()
    // Compact JSON: the runtime pretty-prints by default, which only costs bytes on
    // mobile networks.
    try service.registerHandlers(
        on: router,
        configuration: .init(jsonEncodingOptions: [.sortedKeys]),
        middlewares: [ResponseHeadersMiddleware()]
    )

    return Application(
        router: router,
        configuration: .init(
            address: .hostname(configuration.host, port: configuration.port),
            serverName: "Padlok"
        ),
        logger: logger
    )
}
