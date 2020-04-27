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
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.5"),
        .package(url: "https://github.com/serhii-londar/GithubAPI.git", from: "0.0.6")
    ],
    targets: [
        .target(name: "kaluza", dependencies: ["ZIPFoundation", "ArgumentParser", "GithubAPI"])
    ]
)
