// swift-tools-version: 6.2

import PackageDescription

// Runs swift-openapi-generator for scripts/generate-client. A package of its own, so
// that apps depending on the client never resolve the generator nor its dependencies.
let package = Package(
    name: "Generator",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator.git", exact: "1.14.3")
    ],
    targets: []
)
