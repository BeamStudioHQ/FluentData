// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FluentToDoSPM",
    platforms: [.iOS(.v17), .macOS(.v11)],
    products: [
        .library(
            name: "ToDoCore",
            targets: ["ToDoCore"]
        ),
        .library(
            name: "ToDoTVUI",
            targets: ["ToDoTVUI"]
        ),
        .library(
            name: "ToDoUI",
            targets: ["ToDoUI"]
        ),
        .library(
            name: "ToDoWatchUI",
            targets: ["ToDoWatchUI"]
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
            name: "ToDoTVUI",
            dependencies: [
                .product(name: "FluentData", package: "FluentData"),
                "ToDoCore",
            ]
        ),
        .target(
            name: "ToDoUI",
            dependencies: [
                "ToDoCore",
            ]
        ),
        .target(
            name: "ToDoWatchUI",
            dependencies: [
                "ToDoCore",
            ]
        ),
    ]
)
