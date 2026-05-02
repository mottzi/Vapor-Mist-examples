// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Mottzi",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "./Dependencies/Vapor-Mist"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.8.0"),
        .package(url: "https://github.com/vapor-community/vapor-elementary.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "mottzi",
            dependencies: [
                .product(name: "Mist", package: "Vapor-Mist"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "VaporElementary", package: "vapor-elementary")
            ],
        ),
    ],
    swiftLanguageModes: [.v6]
)
