// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftWinRT",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/tristanlabelle/swift-dotnetmd", branch: "main")
    ],
    targets: [
        .executableTarget(name: "SwiftWinRT", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "DotNetMD", package: "swift-dotnetmd"),
            .target(name: "SwiftWriter")
        ]),
        .target(
            name: "SwiftWriter"),
        .testTarget(
            name: "SwiftWriterTests",
            dependencies: ["SwiftWriter"]),
    ]
)
