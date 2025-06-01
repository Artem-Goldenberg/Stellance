// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Stellance",
    dependencies: [
        .package(
            url: "https://github.com/Artem-Goldenberg/SwiftStella.git",
            branch: "main"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "Stellance",
            dependencies: [
                .product(name: "Stella", package: "SwiftStella")
            ]
        ),
        .testTarget(
            name: "StellanceTests",
            dependencies: ["Stellance"]
        )
    ],
    swiftLanguageModes: [.v5]
)
