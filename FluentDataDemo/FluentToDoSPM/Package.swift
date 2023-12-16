// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FluentToDoSPM",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "ToDoCore",
            targets: ["ToDoCore"]
        ),
        .library(
            name: "ToDoUI",
            targets: ["ToDoUI"]
        ),
    ],
    dependencies: [
        .package(name: "FluentData", path: "../.."),
    ],
    targets: [
        .target(
            name: "ToDoCore",
            dependencies: [
                .product(name: "FluentData", package: "FluentData"),
            ]
        ),
        .target(
            name: "ToDoUI",
            dependencies: [
                "ToDoCore",
            ]
        ),
    ]
)
