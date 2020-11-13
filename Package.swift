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
                    exclude: [
                      "TestPlans",
                      "Resources/SampleModel/Fixtures/README.md",
                      //"Resources/SampleModel/Fixtures/SampleModel.momd",
                      //"Resources/SampleModel/Fixtures/V2toV3.cdm"
                    ],
                    resources: [
                      .copy("Resources/SampleModel/Fixtures/SampleModelV1.sqlite"),
                      .copy("Resources/SampleModel/Fixtures/SampleModelV2.sqlite"),
//                      .copy("Resources/SampleModel/Fixtures/SampleModel.momd"),
//                      .copy("Resources/SampleModel/Fixtures/V2toV3.cdm"),
                    ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
