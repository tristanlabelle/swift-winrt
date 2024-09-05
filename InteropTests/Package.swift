// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "InteropTests",
    dependencies: [
        .package(path: ".."), // Support package
        .package(path: "Generated"),
    ],
    targets: [
        .testTarget(
            name: "Tests",
            dependencies: [
                .product(name: "WindowsRuntime", package: "swift-winrt"),
                .product(name: "UWP", package: "Generated"),
                .product(name: "WinRTComponent", package: "Generated"),
            ],
            path: "Tests",
            // Workaround for SPM library support limitations causing "LNK4217: locally defined symbol imported" spew
            linkerSettings: [ .unsafeFlags([
                "-Xlinker", "-ignore:4217",
                "-Xlinker", "/manifestinput:Generated/WinRTComponent.manifest",
                "-Xlinker", "/manifest:embed"
            ]) ])
    ]
)
