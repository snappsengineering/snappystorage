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
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.10.0"),
    ],
    targets: [
        .target(
            name: "SnappyStorage",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux, .android, .windows, .wasi])),
            ],
            path: "Sources/SnappyStorage",
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "SnappyStorageTests",
            dependencies: ["SnappyStorage"],
            path: "Tests/SnappyStorageTests",
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
    ]
)
