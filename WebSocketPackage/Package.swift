// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let package = Package(
    name: "WebSocketPackage",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: "SharedModels", targets: ["SharedModels"]),
        .library(name: "WebSocketApp", targets: ["WebSocketApp"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),

        // pointfreeco
//        .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.1.0"),
//        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
//        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-issue-reporting", from: "1.2.3"),
//        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.10.0"),
//        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.6.0"),
    ],
    targets: [
        .target(
            name: "SharedModels",
            dependencies: [
//                .product(name: "CasePaths", package: "swift-case-paths"),
//                .product(name: "CustomDump", package: "swift-custom-dump"),
//                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),

        .target(
            name: "WebSocketApp",
            dependencies: [
                "SharedModels",
                .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
                .product(name: "IssueReporting", package: "swift-issue-reporting")
            ]
        ),

        .executableTarget(
            name: "WebSocketServer",
            dependencies: [
                "SharedModels",
                .product(name: "Vapor", package: "vapor"),
            ],
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),

    ]
)
