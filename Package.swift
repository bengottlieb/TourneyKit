// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TourneyKit",
     platforms: [
              .macOS(.v15),
              .iOS(.v17),
              .watchOS(.v10)
         ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "TourneyKit",
            targets: ["TourneyKit"]),
    ],
    dependencies: [
		.package(url: "https://github.com/ios-tooling/CrossPlatformKit.git", from: "1.0.12"),
		.package(url: "https://github.com/ios-tooling/JohnnyCache.git", from: "1.0.9"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "TourneyKit", dependencies: [
            .product(name: "CrossPlatformKit", package: "CrossPlatformKit"),
            .product(name: "JohnnyCache", package: "JohnnyCache"),
        ]),
    ]
)
