// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "changelog-generator",
    products: [
        .executable(name: "changelog", targets: ["changelog-generator"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser",
                 from: "0.0.1")
    ],
    targets: [
        .target(
            name: "changelog-generator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .testTarget(
            name: "changelog-generatorTests",
            dependencies: ["changelog-generator"]),
    ]
)
