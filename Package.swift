// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftWinRT",
    products: [
        .executable(
            name: "SwiftWinRT",
            targets: ["SwiftWinRT"]),
        .library(
            name: "WindowsRuntime",
            targets: ["COM", "WindowsRuntime"]),
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
                .target(name: "CodeWriters")
            ],
            path: "Generator/Sources/SwiftWinRT",
            // Workaround for SPM library support limitations causing "LNK4217: locally defined symbol imported" spew
            linkerSettings: [ .unsafeFlags(["-Xlinker", "-ignore:4217"]) ]),
        .target(
            name: "CodeWriters",
            path: "Generator/Sources/CodeWriters"),
        .testTarget(
            name: "GeneratorTests",
            dependencies: ["CodeWriters"],
            path: "Generator/Tests",
            // Workaround for SPM library support limitations causing "LNK4217: locally defined symbol imported" spew
            linkerSettings: [ .unsafeFlags(["-Xlinker", "-ignore:4217"]) ]),

        // Runtime libraries
        .target(
            name: "CWinRTCore",
            path: "Runtime/Sources/CWinRTCore"),
        .target(
            name: "COM",
            dependencies: ["CWinRTCore"],
            path: "Runtime/Sources/COM"),
        .target(
            name: "WindowsRuntime",
            dependencies: ["CWinRTCore", "COM"],
            path: "Runtime/Sources/WindowsRuntime"),
        .testTarget(
            name: "RuntimeTests",
            dependencies: ["COM", "WindowsRuntime"],
            path: "Runtime/Tests",
            // Workaround for SPM library support limitations causing "LNK4217: locally defined symbol imported" spew
            linkerSettings: [ .unsafeFlags(["-Xlinker", "-ignore:4217"]) ]),
    ]
)
