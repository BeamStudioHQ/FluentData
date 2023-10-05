// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "FluentData",
    platforms: [.iOS(.v17), .macOS(.v11)],
    products: [
        .library(
            name: "FluentData",
            targets: ["FluentData"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services", from: "1.19.0"),
        .package(url: "https://github.com/vapor/fluent-kit.git", from: "1.44.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.5.0"),
        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.53.0")
    ],
    targets: [
        .target(
            name: "FluentData",
            dependencies: [
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                .product(name: "FluentKit", package: "fluent-kit"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
            ],
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
    ]
)
