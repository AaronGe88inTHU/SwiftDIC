// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftDIC",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftDIC",
            targets: ["SwiftDIC"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0"),
//        .package(path: "../Surge"),
        .package(url: "https://github.com/AaronGe88inTHU/Surge.git", branch: "master"),
//        .package(url: "https://github.com/apple/swift-se0288-is-power.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
        
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftDIC",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Surge", package: "Surge"),
//                .product(name: "SE0288_IsPower", package: "swift-se0288-is-power"),
                .product(name: "Numerics", package: "swift-numerics"),
            ]),
        .testTarget(
            name: "SwiftDICTests",
            dependencies: ["SwiftDIC",
                          "Surge"]),
    ]
)
