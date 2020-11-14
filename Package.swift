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

                      // When running tests from Xcode, these resources needs to be excluded
                      // because they are automatically created by Xcode; viceversa when running
                      // tests from terminal these lines should be commented out.
                      "Resources/SampleModel/Fixtures/SampleModel.momd",
                      "Resources/SampleModel/Fixtures/V2toV3.cdm"
                    ],
                    resources: [
                      .copy("Resources/SampleModel/Fixtures/SampleModelV1.sqlite"),
                      .copy("Resources/SampleModel/Fixtures/SampleModelV2.sqlite"),
                      
                      // When running tests from terminal, these resources needs to be copied in the test bundle,
                      // viceversa when running tests from Xcode these lines should be commented out
                      // because Xcode will create automatically these binaries.
                      //.copy("Resources/SampleModel/Fixtures/SampleModel.momd"),
                      //.copy("Resources/SampleModel/Fixtures/V2toV3.cdm"),
                    ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
