// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "kaluza",
    platforms: [
        .macOS(.v10_14)
    ],
    products: [
        .executable(name: "kaluza", targets: ["kaluza"])
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.11")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.2.0"),
        .package(url: "https://github.com/phimage/GitHubKit.git", .branch("feature/clientaccess")),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.1.1")
    ],
    targets: [ 
        .target(name: "kaluza", dependencies: ["ZIPFoundation", "ArgumentParser", "GitHubKit", "AsyncHTTPClient"])
    ]
)
