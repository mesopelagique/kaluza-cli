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
    ],
    targets: [
        .target(name: "kaluza", dependencies: ["ZIPFoundation"])
    ]
)
