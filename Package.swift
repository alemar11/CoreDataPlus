// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CoreDataPlus",
    platforms: [.macOS(.v10_14), .iOS(.v12), .tvOS(.v12), .watchOS(.v5)],
    products: [
        .library(name: "CoreDataPlus", targets: ["CoreDataPlus"])
    ],
    targets: [
        .target(name: "CoreDataPlus", path: "Sources"),
        .testTarget(name: "Tests",
                    dependencies: ["CoreDataPlus"],
                    path: "Tests",
                    exclude: ["CoreDataMigrationsTests.swift"])
    ],
    swiftLanguageVersions: [.v5]
)
