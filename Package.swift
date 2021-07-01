// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "pixivswift",
    platforms: [
        .macOS(.v11), .iOS(.v14)
    ],
    products: [
        .library(name: "pixivswift", targets: ["pixivswift"])
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from:"5.0.1"),
        .package(url: "https://github.com/phimage/Erik.git", from: "5.1.0")
    ],
    targets: [
        .target(
            name: "pixivswift",
            dependencies: ["SwiftyJSON", "Erik"]
        )
    ]
)
