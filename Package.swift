// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "TTTAttributedLabel",
    products: [
        .library(name: "TTTAttributedLabel", targets: ["TTTAttributedLabel"])
    ],
    targets: [
        .target(
            name: "TTTAttributedLabel",
            path: "TTTAttributedLabel",
            publicHeadersPath: "",
            cSettings: [
                .headerSearchPath("")
            ]
        )
    ]
)
