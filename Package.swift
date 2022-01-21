// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "changelog-generator",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "changelog", targets: ["changelog-generator"])
    ],
    dependencies: [
        .package(
            name: "swift-argument-parser",
            url: "https://github.com/apple/swift-argument-parser",
            .exact("1.0.2")
        ),
        .package(url: "https://github.com/apple/swift-tools-support-core", from: "0.2.0")
    ],
    targets: [
        .target(name: "ChangelogCore",
                dependencies: [
                    .product(name: "ArgumentParser", package: "swift-argument-parser"),
                    .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core")
                    
                ]),
        .target(
            name: "changelog-generator",
            dependencies: [
                "ChangelogCore"
            ]),
        .testTarget(
            name: "changelog-generatorTests",
            dependencies: ["changelog-generator", "ChangelogCore"]),
    ]
)
