// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Mottzi",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Mottzi", targets: ["Mottzi"]),
        .executable(name: "Deployer", targets: ["Deployer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.12.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.4.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.8.0"),
    ],
    targets: [
        .executableTarget(
            name: "Mottzi",
            dependencies: [
                "Mist",
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
            ],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "Deployer",
            dependencies: [
                "Mist",
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "Mist",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "Leaf", package: "leaf"),
            ]
        ),
        .testTarget(
            name: "MistTests",
            dependencies: [
                "Mist",
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)

var swiftSettings: [SwiftSetting] {
    [
        .enableUpcomingFeature("DisableOutwardActorInference"),
        .enableExperimentalFeature("StrictConcurrency"),
    ]
}
