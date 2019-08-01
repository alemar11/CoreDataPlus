// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "CoreDataPlus",
    platforms: [.macOS(.v10_13), .iOS(.v11), .tvOS(.v11), .watchOS(.v4)],
    products: [
        .library(name: "CoreDataPlus", targets: ["CoreDataPlus"])
    ],
    targets: [
        .target(name: "CoreDataPlus", path: "Sources"),
        .testTarget(name: "Tests", dependencies: ["CoreDataPlus"], path: "Tests", exclude: ["CoreDataMigrationsTests.swift"])
    ],
    swiftLanguageVersions: [.v5]
)
