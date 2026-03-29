// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SnappyStorage",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(name: "SnappyStorage", targets: ["SnappyStorage"]),
    ],
    targets: [
        .target(
            name: "SnappyStorage",
            path: "Sources"
        ),
        .testTarget(
            name: "SnappyStorageTests",
            dependencies: ["SnappyStorage"]
        ),
    ]
)
