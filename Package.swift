// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SwiftWinRT",
    products: [
        .library(
            name: "WindowsRuntime",
            targets: ["COM", "WindowsRuntime"]),
    ],
    targets: [
        .target(
            name: "COM_ABI",
            path: "Support/Sources/COM_ABI",
            exclude: ["CMakeLists.txt"]),
        .target(
            name: "COM",
            dependencies: ["COM_ABI"],
            path: "Support/Sources/COM",
            exclude: ["CMakeLists.txt"]),
        .target(
            name: "WindowsRuntime_ABI",
            dependencies: ["COM_ABI"],
            path: "Support/Sources/WindowsRuntime_ABI",
            exclude: ["CMakeLists.txt"]),
        .target(
            name: "WindowsRuntime",
            dependencies: ["WindowsRuntime_ABI", "COM"],
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
