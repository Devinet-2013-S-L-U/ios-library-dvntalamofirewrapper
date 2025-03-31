// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DVNTAlamofireWrapper",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        .library(
            name: "DVNTAlamofireWrapper",
            targets: ["DVNTAlamofireWrapper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.10.2"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", from: "5.0.2"),
        .package(url: "https://github.com/ashleymills/Reachability.swift", from: "5.2.4")
    ],
    targets: [
        .target(
            name: "DVNTAlamofireWrapper",
            dependencies: ["Alamofire", "SwiftyJSON", "Reachability"])
    ]
)
