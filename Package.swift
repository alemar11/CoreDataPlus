// swift-tools-version:5.6

import PackageDescription
import Foundation

let isRunningTestsFromCommandLine: Bool = {
  return ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"] == "0"
}()

var excluded = [
  "TestPlans",
  "Resources/SampleModel/Fixtures/README.md"
]
var resources: [Resource] = [
  .copy("Resources/SampleModel/Fixtures/SampleModelV1.sqlite"),
  .copy("Resources/SampleModel/Fixtures/SampleModelV2.sqlite")
]

if isRunningTestsFromCommandLine {
  // When running tests from terminal, these resources needs to be copied in the test bundle,
  // viceversa when running tests from Xcode, Xcode will create automatically these binaries automaticcally.
  resources.append(contentsOf: [
    .copy("Resources/SampleModel/Fixtures/SampleModel.momd"),
    .copy("Resources/SampleModel/Fixtures/V2toV3.cdm"),
  ])
} else {
  // When running tests from Xcode, these resources needs to be excluded
  // because they are automatically created by Xcode
  excluded.append(contentsOf: [
    "Resources/SampleModel/Fixtures/SampleModel.momd",
    "Resources/SampleModel/Fixtures/V2toV3.cdm"
  ])
}

let package = Package(
  name: "CoreDataPlus",
  platforms: [.macOS(.v10_14), .iOS(.v12), .tvOS(.v12), .watchOS(.v5)],
  products: [
    .library(name: "CoreDataPlus", targets: ["CoreDataPlus"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
  ],
  targets: [
    .target(name: "CoreDataPlus", path: "Sources"),
    .testTarget(name: "Tests",
                dependencies: ["CoreDataPlus"],
                path: "Tests",
                exclude: excluded,
                resources: resources
    ),
  ],
  swiftLanguageVersions: [.v5]
)
