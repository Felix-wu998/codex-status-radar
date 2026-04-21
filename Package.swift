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
        ),
        .executable(
            name: "CodexStatusRadarApp",
            targets: ["CodexStatusRadarApp"]
        )
    ],
    targets: [
        .target(
            name: "CodexStatusRadarCore",
            path: "packages/core/Sources/CodexStatusRadarCore"
        ),
        .executableTarget(
            name: "CodexStatusRadarApp",
            dependencies: ["CodexStatusRadarCore"],
            path: "apps/macos/Sources/CodexStatusRadarApp"
        ),
        .testTarget(
            name: "CodexStatusRadarCoreTests",
            dependencies: ["CodexStatusRadarCore"],
            path: "packages/core/Tests/CodexStatusRadarCoreTests"
        ),
        .testTarget(
            name: "CodexStatusRadarAppTests",
            dependencies: ["CodexStatusRadarApp"],
            path: "apps/macos/Tests/CodexStatusRadarAppTests"
        )
    ]
)
