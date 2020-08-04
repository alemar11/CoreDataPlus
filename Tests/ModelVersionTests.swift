import XCTest
@testable import CoreDataPlus

final class ModelVersionTests: XCTestCase {
  func testInvalidInitialization() {
    XCTAssertNil(SampleModelVersion(persistentStoreURL: URL(string: "wrong-url")!))
  }

  func testVersionModelSetup() {
    XCTAssertTrue(SampleModelVersion.currentVersion == .version1)
    XCTAssertTrue(SampleModelVersion.allVersions == [.version1, .version2, .version3])
    XCTAssertTrue(SampleModelVersion.version1.successor == .version2)
    XCTAssertNil(SampleModelVersion.version3.mappingModelToNextModelVersion())
  }

  func testMappingModelsByName() {
    if isRunningSwiftPackageTests() {
      print("Not implemented")
      return
    }

    do {
      let models = SampleModelVersion.version2.mappingModels(for: ["V2toV3"])
      XCTAssertEqual(models.count, 1)
    }

    do {
      let models = SampleModelVersion.version2.mappingModels(for: ["V2toV3_"])
      XCTAssertTrue(models.isEmpty)
    }
  }
}
