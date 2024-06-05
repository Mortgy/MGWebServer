// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MGWebServer",
    platforms: [
        .iOS(.v12), .macOS(.v10_14)
    ],
    products: [
        .library(
            name: "MGWebServer",
            targets: ["MGWebServer"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MGWebServer",
            dependencies: [],
            path: "Sources/MGWebServer",
            exclude: ["Assets"],
            resources: [
                .copy("Assets/silent.mp3")
            ]
        )
    ]
)
