// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BibleStoryCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BibleStoryCore", targets: ["BibleStoryCore"]),
    ],
    targets: [
        .target(name: "BibleStoryCore"),
        .testTarget(
            name: "BibleStoryCoreTests",
            dependencies: ["BibleStoryCore"]
        ),
    ]
)
