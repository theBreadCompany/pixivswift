// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "pixivswift",
    platforms: [
        .macOS(.v10_13), .iOS(.v11)
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
            dependencies: [
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "Erik", package: "Erik", condition: .when(platforms: [.macOS, .linux, .windows])) // headless login only makes sense on headless environments like CLIs
            ]
        )
    ]
)
