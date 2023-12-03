// swift-tools-version: 5.9

// TODO(#10): Swift/WinRT should generate this Package.swift file
import PackageDescription

let package = Package(
    name: "Generated",
    products: [
        .library(
            name: "Projection",
            targets: [
                "WinRTComponent"
            ]),
    ],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .target(
            name: "CWinRT",
            path: "CWinRT"),
        .target(
            name: "WinRTComponent",
            dependencies: [
                "CWinRT",
                .product(name: "WindowsRuntime", package: "swift-winrt")
            ],
            path: "WinRTComponent/Assembly")
    ]
)
