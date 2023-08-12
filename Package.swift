// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftWinRT",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "1.2.0")),
        .package(url: "https://github.com/apple/swift-collections", .upToNextMinor(from: "1.0.4")),
        .package(url: "https://github.com/tristanlabelle/swift-dotnetmetadata", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "SwiftWinRT",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "DotNetMetadata", package: "swift-dotnetmetadata"),
                .target(name: "CodeWriters")
            ],
            // Workaround for SPM library support limitations causing "LNK4217: locally defined symbol imported" spew
            linkerSettings: [ .unsafeFlags(["-Xlinker", "-ignore:4217"]) ]),
        .target(
            name: "CodeWriters"),
        .testTarget(
            name: "CodeWritersTests",
            dependencies: ["CodeWriters"],
            // Workaround for SPM library support limitations causing "LNK4217: locally defined symbol imported" spew
            linkerSettings: [ .unsafeFlags(["-Xlinker", "-ignore:4217"]) ]),
    ]
)
