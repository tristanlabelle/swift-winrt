// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftWinRT",
    products: [
        .executable(
            name: "SwiftWinRT",
            targets: ["SwiftWinRT"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "1.2.0")),
        .package(url: "https://github.com/apple/swift-collections", .upToNextMinor(from: "1.0.4")),
        .package(url: "https://github.com/tristanlabelle/swift-dotnetmetadata", branch: "main")
    ],
    targets: [
        // Code generator
        .executableTarget(
            name: "SwiftWinRT",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "DotNetMetadata", package: "swift-dotnetmetadata"),
                "ProjectionGenerator"
            ],
            path: "Sources/SwiftWinRT",
            // Workaround for SPM library support limitations causing "LNK4217: locally defined symbol imported" spew
            linkerSettings: [ .unsafeFlags(["-Xlinker", "-ignore:4217"]) ]),
        .target(
            name: "CodeWriters",
            path: "Sources/CodeWriters"),
        .target(
            name: "ProjectionGenerator",
            dependencies: [ "CodeWriters" ],
            path: "Sources/ProjectionGenerator"),
        .testTarget(
            name: "Tests",
            dependencies: [ "CodeWriters", "ProjectionGenerator" ],
            path: "Tests",
            // Workaround for SPM library support limitations causing "LNK4217: locally defined symbol imported" spew
            linkerSettings: [ .unsafeFlags(["-Xlinker", "-ignore:4217"]) ])
    ]
)
