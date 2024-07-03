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
        .target(
            name: "CodeWriters",
            path: "Sources/CodeWriters"),
        .target(
            name: "ProjectionModel",
            dependencies: [
                "CodeWriters",
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "DotNetMetadata", package: "swift-dotnetmetadata")
            ],
            path: "Sources/ProjectionModel"),
        .executableTarget(
            name: "SwiftWinRT",
            dependencies: [
                "ProjectionModel",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "DotNetMetadata", package: "swift-dotnetmetadata")
            ],
            path: "Sources/SwiftWinRT",
            resources: [
                // Avoid the .swift extension or SPM will pick those up a source files.
                .embedInCode("Extensions/WindowsFoundation_IAsyncAction_swift"),
                .embedInCode("Extensions/WindowsFoundation_IAsyncActionWithProgress_swift"),
                .embedInCode("Extensions/WindowsFoundation_IAsyncOperation_swift"),
                .embedInCode("Extensions/WindowsFoundation_IAsyncOperationWithProgress_swift"),
                .embedInCode("Extensions/WindowsFoundation_IMemoryBufferReference_swift"),
                .embedInCode("Extensions/WindowsFoundationCollections_IIterable_swift"),
                .embedInCode("Extensions/WindowsFoundationCollections_IVector_swift"),
                .embedInCode("Extensions/WindowsFoundationCollections_IVectorView_swift"),
                .embedInCode("Extensions/WindowsStorageStreams_IBuffer_swift")
            ],
            // Workaround for SPM library support limitations causing "LNK4217: locally defined symbol imported" spew
            linkerSettings: [ .unsafeFlags(["-Xlinker", "-ignore:4217"]) ]),
        .testTarget(
            name: "Tests",
            dependencies: [ "CodeWriters", "ProjectionModel" ],
            path: "Tests",
            // Workaround for SPM library support limitations causing "LNK4217: locally defined symbol imported" spew
            linkerSettings: [ .unsafeFlags(["-Xlinker", "-ignore:4217"]) ])
    ]
)
