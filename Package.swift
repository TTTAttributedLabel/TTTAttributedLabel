// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "TTTAttributedLabel",
    platforms: [.iOS(.v8)],
    products: [
        .library(
            name: "TTTAttributedLabel",
            targets: ["TTTAttributedLabel"]
        )
    ],
    targets: [
        .target(name: "TTTAttributedLabel")
    ]
)
