//
//  Package.swift
//  WebServer
//
//  Created by Muhammed Mortgy on 05.06.24.
//

// swift-tools-version:5.3
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
            path: "Sources/MGWebServer"
        )
    ]
)
