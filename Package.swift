// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "TTAttributedLabel",
    products: [
        .library(
            name: "TTAttributedLabel",
            targets: ["TTAttributedLabel"])
    ],
    targets: [
        .target(
            name: "TTAttributedLabel"
    ],
    swiftLanguageVersions: [.v5]
)