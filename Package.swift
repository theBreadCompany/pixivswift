// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "pixivswift",
    platforms: [
        .macOS(.v10_11), .iOS(.v9)
    ],
    products: [
        .library(name: "pixivswift", targets: ["pixivswift"]),
        .library(name: "pixivswiftWrapper", targets: ["pixivswiftWrapper", "pixivswift"])
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
//                .productItem(name: "Erik", package: "Erik", condition: .when(platforms: [.linux, .windows, .macOS])), // headless login only makes sense in headless environments (CLIs), otherwise check out the pixivauth target
            ],
            exclude: ["papi.swift"]
        ),
        .target(
            name: "pixivswiftWrapper",
            dependencies: [
                "pixivswift", "ZIPFoundation",
            ]
        ),
        .testTarget(
            name: "pixivswiftTests",
            dependencies: ["pixivswift"]
        ),
        .testTarget(
            name: "pixivswiftWrapperTests",
            dependencies: ["pixivswiftWrapper"]
        ),
    ]
)

#if os(macOS)
package.targets.append(.target(name: "pixivauth", dependencies: ["pixivswift"]))
package.products.append(.executable(name: "pixivauth", targets: ["pixivauth"]))
#endif

#if !canImport(CommonCrypto)
package.dependencies.append(.package(url: "https://github.com/apple/swift-crypto.git", .upToNextMajor(from: "3.0.0")))
package.targets.first(where: {$0.name == "pixivswift"})!.dependencies.append(.productItem(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux])))
#endif
#if !canImport(ImageIO)
package.dependencies.append([
    .package(url: "https://github.com/fwcd/swift-gif.git", .upToNextMajor(from: "2.0.0")),
    .package(url: "https://github.com/twostraws/SwiftGD", .upToNextMajor(from: "2.0.0"))
])
package.targets.first(where: {$0.name == "pixivswiftWrapper"})!.dependencies.append([
    .product(name: "GIF", package: "swift-gif", condition: .when(platforms: [.linux])),
    .product(name: "SwiftGD", package: "SwiftGD", condition: .when(platforms: [.linux]))
])
#endif
