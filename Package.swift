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
            name: "CWinRTCore",
            path: "Support/Sources/CWinRTCore"),
        .target(
            name: "COM",
            dependencies: ["CWinRTCore"],
            path: "Support/Sources/COM"),
        .target(
            name: "WindowsRuntime",
            dependencies: ["CWinRTCore", "COM"],
            path: "Support/Sources/WindowsRuntime"),
        .testTarget(
            name: "Tests",
            dependencies: ["COM", "WindowsRuntime"],
            path: "Support/Tests",
            // Workaround for SPM library support limitations causing "LNK4217: locally defined symbol imported" spew
            linkerSettings: [ .unsafeFlags(["-Xlinker", "-ignore:4217"]) ]),
    ]
)
