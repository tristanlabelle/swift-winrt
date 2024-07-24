// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SwiftWinRT",
    products: [
        .library(
            name: "WindowsRuntime_ABI",
            targets: ["ExportedABI"]),
        .library(
            name: "WindowsRuntime",
            targets: ["COM", "WindowsRuntime"]),
    ],
    targets: [
        .target(
            name: "ExportedABI",
            path: "Support/Sources/ExportedABI",
            exclude: ["CMakeLists.txt"]),
        .target(
            name: "InternalABI",
            dependencies: ["ExportedABI"],
            path: "Support/Sources/InternalABI",
            exclude: ["CMakeLists.txt"]),
        .target(
            name: "COM",
            dependencies: ["ExportedABI", "InternalABI"],
            path: "Support/Sources/COM",
            exclude: ["CMakeLists.txt"]),
        .target(
            name: "WindowsRuntime",
            dependencies: ["ExportedABI", "InternalABI"],
            path: "Support/Sources/WindowsRuntime",
            exclude: ["CMakeLists.txt"]),
        .testTarget(
            name: "Tests",
            dependencies: ["COM", "WindowsRuntime"],
            path: "Support/Tests",
            // Workaround for SPM library support limitations causing "LNK4217: locally defined symbol imported" spew
            linkerSettings: [ .unsafeFlags(["-Xlinker", "-ignore:4217"]) ]),
    ]
)
