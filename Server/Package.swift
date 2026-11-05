// swift-tools-version: 6.2

import PackageDescription

// The Padlok API server: Hummingbird 2, behind nginx. Built on Debian with
// `swift build -c release --static-swift-stdlib` (.github/workflows/server.yml).
//
// A package of its own, so that the apps importing the client at the repository root
// never resolve the server's dependencies.
let package = Package(
    name: "Server",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "Server", targets: ["Server"])
    ],
    dependencies: [
        // The client, for tests that go through it as the apps do.
        .package(name: "PadlokAPI", path: ".."),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.28.0"),
        .package(url: "https://github.com/swift-server/swift-openapi-hummingbird.git", from: "2.1.0"),
        .package(url: "https://github.com/apple/swift-openapi-generator.git", from: "1.14.3"),
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.13.4"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.16.2"),
        .package(url: "https://github.com/apple/swift-configuration.git", from: "1.4.0"),
        .package(url: "https://github.com/vapor/mysql-kit.git", from: "4.10.2"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.104.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.13.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "5.0.3"),
        .package(url: "https://github.com/apple/swift-http-types.git", from: "1.8.0"),
    ],
    targets: [
        // Generated from openapi.yaml (a symlink to the repository root's) at build time.
        .target(
            name: "PadlokAPIServer",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .executableTarget(
            name: "Server",
            dependencies: [
                "PadlokAPIServer",
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "OpenAPIHummingbird", package: "swift-openapi-hummingbird"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Configuration", package: "swift-configuration"),
                .product(name: "MySQLKit", package: "mysql-kit"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ]
        ),
        .testTarget(
            name: "ServerTests",
            dependencies: [
                "Server",
                .product(name: "PadlokAPIClient", package: "PadlokAPI"),
                .product(name: "HummingbirdTesting", package: "hummingbird"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
