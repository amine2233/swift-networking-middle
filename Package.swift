// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "networking-middle",
    platforms: [.iOS(.v13), .macOS(.v11)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other
        // packages.
        .library(
            name: "NetworkingMiddle",
            targets: ["NetworkingMiddle"]
        ),
        .library(
            name: "NetworkingMiddleTesting",
            targets: ["NetworkingMiddleTesting"]
        ),
        .library(
            name: "NetworkingMiddleMocking",
            targets: ["NetworkingMiddleMocking"]
        ),
        .library(
            name: "NetworkingMiddlePinning",
            targets: ["NetworkingMiddlePinning"]
        )
    ],
    dependencies: [
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "NetworkingMiddle",
            dependencies: [
                .target(name: "AnyCodable")
            ]
        ),
        .testTarget(
            name: "NetworkingMiddleTests",
            dependencies: [
                .target(name: "NetworkingMiddle")
            ]
        ),
        .target(
            name: "NetworkingMiddleTesting",
            dependencies: [
                .target(name: "NetworkingMiddle")
            ],
            swiftSettings: [
                .enableUpcomingFeature("InternalImportsByDefault")
            ]
        ),
        .target(
            name: "NetworkingMiddleMocking"
        ),
        .testTarget(
            name: "NetworkingMiddleMockingTests",
            dependencies: [
                .target(name: "NetworkingMiddleMocking")
            ],
            resources: [
                .copy("Resources/bundle.json"),
                .copy("Resources/get_arg.json"),
                .copy("Resources/get_arg1.json"),
                .copy("Resources/ip.json")
            ]
        ),
        .target(
            name: "AnyCodable"
        ),
        .target(
            name: "NetworkingMiddlePinning",
            dependencies: [
                .target(name: "NetworkingMiddle")
            ]
        ),
        .testTarget(
            name: "NetworkingMiddlePinningTests",
            dependencies: [
                .target(name: "NetworkingMiddlePinning"),
                .target(name: "NetworkingMiddle")
            ],
            resources: [
                .copy("Resources/test_cert.der")
            ]
        )
    ]
)
