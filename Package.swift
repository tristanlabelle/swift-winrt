// swift-tools-version: 5.9
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
            name: "WindowsRuntime_ABI",
            path: "Support/Sources/WindowsRuntime_ABI"),
        .target(
            name: "COM",
            dependencies: ["WindowsRuntime_ABI"],
            path: "Support/Sources/COM"),
        .target(
            name: "WindowsRuntime",
            dependencies: ["WindowsRuntime_ABI", "COM"],
            path: "Support/Sources/WindowsRuntime"),
        .testTarget(
            name: "Tests",
            dependencies: ["COM", "WindowsRuntime"],
            path: "Support/Tests",
            // Workaround for SPM library support limitations causing "LNK4217: locally defined symbol imported" spew
            linkerSettings: [ .unsafeFlags(["-Xlinker", "-ignore:4217"]) ]),
    ]
)
