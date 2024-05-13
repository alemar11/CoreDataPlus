// swift-tools-version:5.10

import PackageDescription
import Foundation

let isRunningFromCommandLine: Bool = { ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"] == "0" }()
let buildingDocumentation = getenv("BUILDING_FOR_DOCUMENTATION_GENERATION") != nil

var excluded = [
  "TestPlans",
  "Resources/SampleModel/Fixtures/README.md"
]

var resources: [Resource] = [
  .copy("Resources/SampleModel/Fixtures/SampleModelV1.sqlite"),
  .copy("Resources/SampleModel/Fixtures/SampleModelV2.sqlite"),
  
  .copy("Resources/SampleModel2/Fixtures/SampleModel2V1.sqlite"),
  .copy("Resources/SampleModel2/Fixtures/SampleModel2V2.sqlite"),
  
  .copy("Resources/SampleModel3/Fixtures/SampleModel3_V1.sqlite"),
]

if isRunningFromCommandLine {
  // When running tests from terminal, these resources needs to be copied in the test bundle,
  // viceversa when running tests from Xcode, Xcode will create automatically these binaries automatically.
  resources.append(contentsOf: [
    .copy("Resources/SampleModel/Fixtures/SampleModel.momd"),
    .copy("Resources/SampleModel/Fixtures/V2toV3.cdm"),
    .copy("Resources/SampleModel3/Fixtures/SampleModel3.momd"),
  ])
} else {
  // When running tests from Xcode, these resources needs to be excluded
  // because they are automatically created by Xcode
  excluded.append(contentsOf: [
    "Resources/SampleModel/Fixtures/SampleModel.momd",
    "Resources/SampleModel/Fixtures/V2toV3.cdm",
    "Resources/SampleModel3/Fixtures/SampleModel3.momd"
  ])
}

// Remove warnings when building documentation or runnning test from CLI
if isRunningFromCommandLine || buildingDocumentation {
  excluded += [
    "Resources/SampleModel/MappingModels/V2toV3.xcmappingmodel",
    "Resources/SampleModel/SampleModel.xcdatamodeld",
    "Resources/SampleModel3/SampleModel3.xcdatamodeld"]
}

let swiftSettings: [SwiftSetting] = [
  .enableExperimentalFeature("StrictConcurrency")
]

let package = Package(
  name: "CoreDataPlus",
  platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1)],
  products: [
    .library(name: "CoreDataPlus", targets: ["CoreDataPlus"])
  ],
  targets: [
    .target(name: "CoreDataPlus",
            path: "Sources",
            swiftSettings: swiftSettings
           ),
    .testTarget(name: "Tests",
                dependencies: ["CoreDataPlus"],
                path: "Tests",
                exclude: excluded,
                resources: resources,
                swiftSettings: swiftSettings
               ),
  ],
  swiftLanguageVersions: [.v5]
)

// Only require the docc plugin when building documentation
package.dependencies += buildingDocumentation ? [
  .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.2.0"),
] : []
