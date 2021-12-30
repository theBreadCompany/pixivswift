// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "pixivswift",
    platforms: [
        .macOS(.v10_13), .iOS(.v11)
    ],
    products: [
        .library(name: "pixivswift", targets: ["pixivswift"]),
        .library(name: "pixivswiftWrapper", targets: ["pixivswiftWrapper", "pixivswift"])
    ],
    dependencies: [
        //.package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from:"5.0.1"),
        .package(url: "https://github.com/phimage/Erik.git", from: "5.1.0"),
        .package(url: "https://github.com/maparoni/Zip.git", .revisionItem("059e7346082d02de16220cd79df7db18ddeba8c3"))
    ],
    targets: [
        .target(
            name: "pixivswift",
            dependencies: [ .productItem(name: "Erik", package: "Erik", condition: .when(platforms: [.linux, .windows, .macOS])) ], // headless login only makes sense in headless environments (CLIs)
            exclude: ["papi.swift"]
        ),
        .target(
            name: "pixivswiftWrapper",
            dependencies: ["pixivswift", "Zip"]
        )
    ]
)
