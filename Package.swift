// swift-tools-version:5.6
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
//        .package(url: "https://github.com/maparoni/Zip.git", revision: "059e7346082d02de16220cd79df7db18ddeba8c3")
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", revision: "fac78dfe5a886ad98e355ba98475b30b3753213a")
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
        .executableTarget(
            name: "pixivauth",
            dependencies: ["pixivswift"]
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

#if !canImport(CommonCrypto)
package.dependencies.append(.package(url: "https://github.com/apple/swift-crypto.git", .upToNextMajor(from: "3.0.0")))
package.targets.first(where: {$0.name == "pixivswift"})!.dependencies.append(.productItem(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux])))
#endif
#if !canImport(ImageIO)
package.dependencies.append(contentsOf: [
    .package(url: "https://github.com/fwcd/swift-gif.git", .upToNextMajor(from: "2.0.0")),
    .package(url: "https://github.com/twostraws/SwiftGD", revision: "07650dcb343d5b045598459fd3aad0936e0259bf")
])
package.targets.first(where: {$0.name == "pixivswiftWrapper"})!.dependencies.append(contentsOf: [
    .product(name: "GIF", package: "swift-gif", condition: .when(platforms: [.linux])),
    .product(name: "SwiftGD", package: "SwiftGD", condition: .when(platforms: [.linux]))
])
#endif
