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
            linkerSettings: [ .unsafeFlags([
                // Embed the WinRT component manifest to locate activation factories
                "-Xlinker", "/manifestinput:WinRTComponent/Projection/WinRTComponent.manifest",
                "-Xlinker", "/manifest:embed",
                // Workaround for SPM library support limitations causing "LNK4217: locally defined symbol imported" spew
                "-Xlinker", "-ignore:4217"
            ]) ])
    ]
)
