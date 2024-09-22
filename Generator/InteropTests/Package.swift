// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "InteropTests",
    dependencies: [
        .package(name: "Support", path: "../.."),
        .package(name: "Projection", path: "WinRTComponent/Projection"),
    ],
    targets: [
        .testTarget(
            name: "Tests",
            dependencies: [
                .product(name: "WindowsRuntime", package: "Support"),
                .product(name: "UWP", package: "Projection"),
                .product(name: "WinRTComponent", package: "Projection"),
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
