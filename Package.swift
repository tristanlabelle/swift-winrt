// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-winrt",
    dependencies: [
        .package(url: "https://github.com/tristanlabelle/swift-dotnetmd", branch: "main")
    ],
    targets: [
        .executableTarget(name: "swift-winrt", dependencies: [
            .product(name: "DotNetMD", package: "swift-dotnetmd")
        ])
    ]
)
