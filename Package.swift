// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "CoreDataPlus",
    platforms: [.macOS(.v10_12), .iOS(.v10), .tvOS(.v10), .watchOS(.v3)],
    products: [
        .library(name: "CoreDataPlus", targets: ["CoreDataPlus"])
    ],
    targets: [
        .target(name: "CoreDataPlus", path: "Sources"),
        .testTarget(name: "Tests", dependencies: ["CoreDataPlus"], path: "Tests", exclude: ["CoreDataMigrationsTests.swift"])
    ],
    swiftLanguageVersions: [.v5]
)
