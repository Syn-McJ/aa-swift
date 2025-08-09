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
        .library(
            name: "Coinbase",
            targets: ["AASwiftCoinbase"]),
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", .upToNextMajor(from: "5.3.0")),
        .package(url: "https://github.com/argentlabs/web3.swift.git", .upToNextMajor(from: "1.6.1")),
        .package(url: "https://github.com/leoture/MockSwift.git", .upToNextMajor(from: "1.1.0")),
        .package(url: "https://github.com/apple/swift-testing.git", branch: "main")
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
        .target(
            name: "AASwiftCoinbase",
            dependencies: [
                "AASwift",
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "web3.swift", package: "web3.swift"),
            ],
            path: "Sources",
            sources: ["Coinbase"]
        ),
        .testTarget(
            name: "AASwiftTests",
            dependencies: [
                "AASwift",
                "AASwiftAlchemy",
                "MockSwift",
                .product(name: "web3.swift", package: "web3.swift"),
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "Testing", package: "swift-testing")
            ]),
    ]
)
