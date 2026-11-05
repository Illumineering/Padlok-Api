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
    // Request IDs come from nginx (X-Request-Id), which also writes the access log.
    router.middlewares.add(LogRequestsWithoutTokens())
    if let allowedOrigin = configuration.corsAllowedOrigin {
        router.middlewares.add(try OriginPatternCORSMiddleware(allowedOrigin: allowedOrigin))
    }
    // Compact JSON: the runtime pretty-prints by default, which only costs bytes on
    // mobile networks.
    try service.registerHandlers(
        on: router,
        configuration: .init(jsonEncodingOptions: [.sortedKeys]),
        middlewares: [
            // Outermost, so that error responses are marked no-store too.
            ResponseHeadersMiddleware(),
            ErrorMiddleware(logger: logger),
            RequestInfoMiddleware(),
            ShareCreationLimitMiddleware(limiter: service.rateLimits.shareCreation),
        ]
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
