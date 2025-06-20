// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TTTAttributedLabel",
    platforms: [
        .iOS(.v8),
        .tvOS(.v9)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TTTAttributedLabel",
            targets: ["TTTAttributedLabel"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // No external dependencies - uses only system frameworks
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        .target(
            name: "TTTAttributedLabel",
            dependencies: [],
            path: "TTTAttributedLabel",
            sources: ["TTTAttributedLabel.h", "TTTAttributedLabel.m"],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("."),
            ],
            linkerSettings: [
                .linkedFramework("UIKit"),
                .linkedFramework("CoreText"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("QuartzCore")
            ]
        ),
    ]
) 
