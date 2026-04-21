// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CodexStatusRadar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "CodexStatusRadarCore",
            targets: ["CodexStatusRadarCore"]
        )
    ],
    targets: [
        .target(
            name: "CodexStatusRadarCore",
            path: "packages/core/Sources/CodexStatusRadarCore"
        ),
        .testTarget(
            name: "CodexStatusRadarCoreTests",
            dependencies: ["CodexStatusRadarCore"],
            path: "packages/core/Tests/CodexStatusRadarCoreTests"
        )
    ]
)
