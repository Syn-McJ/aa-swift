// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AA-Swift",
    platforms: [
       .iOS(.v13),
       .macOS(.v11),
       .watchOS(.v6),
       .tvOS(.v13),
       .macCatalyst(.v14),
       .driverKit(.v20),
    ],
    products: [
        .library(
            name: "Core",
            targets: ["AASwift"]),
        .library(
            name: "Alchemy",
            targets: ["AASwiftAlchemy"]),
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
        .package(url: "https://github.com/argentlabs/web3.swift.git", .revision("cc721d021297781b3e2479899585ce312808543e")),
        .package(url: "https://github.com/leoture/MockSwift.git", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "AASwift",
            dependencies: [
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "web3.swift", package: "web3.swift"),
            ],
            path: "Sources",
            sources: ["Core"]
        ),
        .target(
            name: "AASwiftAlchemy",
            dependencies: [
                "AASwift",
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "web3.swift", package: "web3.swift"),
            ],
            path: "Sources",
            sources: ["Alchemy"]
        ),
        .testTarget(
            name: "AASwiftTests",
            dependencies: ["AASwift", "MockSwift"]),
    ]
)