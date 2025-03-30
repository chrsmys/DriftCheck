// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DriftCheck",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DriftCheck",
            targets: ["DriftCheck"]),
    ],
    dependencies: [
       .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.2.2"),
       .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0"),
     ],
    targets: [
        .target(
            name: "DriftCheck",
            dependencies: [
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay", condition: .when(platforms: [.iOS])),
            ]
        ),
        .testTarget(
            name: "DriftCheckTests",
            dependencies: ["DriftCheck"]
        ),
    ]
)
