// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Leaf",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LeafCore",
            targets: ["LeafCore"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/groue/GRDB.swift.git",
            from: "6.29.0"
        )
    ],
    targets: [
        .target(
            name: "LeafCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Leaf",
            exclude: [
                "Resources",
                "App/LeafApp.swift"
            ]
        ),
        .testTarget(
            name: "LeafTests",
            dependencies: [
                "LeafCore",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "LeafTests"
        )
    ]
)

