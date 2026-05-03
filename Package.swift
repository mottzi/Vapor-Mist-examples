// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Mottzi",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/mottzi/Vapor-Mist", from: "0.20.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.8.0"),
    ],
    targets: [
        .executableTarget(
            name: "mottzi",
            dependencies: [
                .product(name: "Mist", package: "Vapor-Mist"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
            ],
        ),
    ],
    swiftLanguageModes: [.v6]
)

