// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SwiftWinRT",
    products: [
        .library(
            name: "WindowsRuntime_ABI",
            targets: ["COM_ABI", "WindowsRuntime_ABI"]),
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
            name: "WindowsRuntime_ABI",
            dependencies: ["COM_ABI"],
            path: "Support/Sources/WindowsRuntime_ABI",
            exclude: ["CMakeLists.txt"]),
        .target(
            name: "InternalABI",
            dependencies: ["COM_ABI", "WindowsRuntime_ABI"],
            path: "Support/Sources/InternalABI",
            exclude: ["CMakeLists.txt"]),
        .target(
            name: "ABIBindings",
            path: "Support/Sources/ABIBindings",
            exclude: ["CMakeLists.txt"]),
        .target(
            name: "COM",
            dependencies: ["ABIBindings", "COM_ABI", "InternalABI"],
            path: "Support/Sources/COM",
            exclude: ["CMakeLists.txt"]),
        .target(
            name: "WindowsRuntime",
            dependencies: ["COM", "WindowsRuntime_ABI", "InternalABI"],
            path: "Support/Sources/WindowsRuntime",
            exclude: [
                "CMakeLists.txt",
                "Projection/Readme.md",
                "Projection/WindowsFoundation/Readme.md",
            ]),
        .testTarget(
            name: "Tests",
            dependencies: ["COM", "WindowsRuntime"],
            path: "Support/Tests",
            // Workaround for SPM library support limitations causing "LNK4217: locally defined symbol imported" spew
            linkerSettings: [ .unsafeFlags(["-Xlinker", "-ignore:4217"]) ]),
    ]
)
