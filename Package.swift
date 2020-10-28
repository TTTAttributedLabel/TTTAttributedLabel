// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "TTTAttributedLabel",
    platforms: [.iOS(.v9)],
    products: [
        .library(
            name: "TTTAttributedLabel",
            targets: ["TTTAttributedLabel"]
        )
    ],
    targets: [
        .target(
            name: "TTTAttributedLabel",
            path: "TTTAttributedLabel",
            exclude: ["Example", "Carthage"],
            publicHeadersPath: "."
        )
    ]
)
