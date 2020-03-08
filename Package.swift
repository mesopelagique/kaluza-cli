// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "kaluza",
    products: [
        .executable(name: "kaluza",targets: ["kaluza"]),
    ],
    dependencies: [
    ],
    targets: [
        .target( name: "kaluza")
    ]
)
