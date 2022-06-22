// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "pixivswift",
    platforms: [
        .macOS(.v10_11), .iOS(.v9)
    ],
    products: [
        .library(name: "pixivswift", targets: ["pixivswift"]),
        .library(name: "pixivswiftWrapper", targets: ["pixivswiftWrapper", "pixivswift"]),
        .executable(name: "pixivauth", targets: ["pixivauth"])
    ],
    dependencies: [
//        .package(url: "https://github.com/phimage/Erik.git", from: "5.1.0"),
//        .package(url: "https://github.com/maparoni/Zip.git", .revisionItem("059e7346082d02de16220cd79df7db18ddeba8c3"))
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0"))
    ],
    targets: [
        .target(
            name: "pixivswift",
            dependencies: [
//                .productItem(name: "Erik", package: "Erik", condition: .when(platforms: [.linux, .windows, .macOS])) // headless login only makes sense in headless environments (CLIs), otherwise check out the pixivauth target
            ],
            exclude: ["papi.swift"]
        ),
        .target(
            name: "pixivswiftWrapper",
            dependencies: ["pixivswift", "ZIPFoundation"]
        ),
        .testTarget(
            name: "pixivswiftTests",
            dependencies: ["pixivswift"]
        ),
        .testTarget(
            name: "pixivswiftWrapperTests",
            dependencies: ["pixivswiftWrapper"]
        ),
        .target(
            name: "pixivauth",
            dependencies: ["pixivswift"]
        )
    ]
)
