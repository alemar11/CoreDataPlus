// CoreDataPlus

import XCTest

@testable import CoreDataPlus

final class ModelVersion_Tests: XCTestCase {
  func test_InvalidInitialization() {
    XCTAssertThrowsError(try SampleModelVersion(persistentStoreURL: URL(string: "wrong-url")!))
  }

  func test_VersionModelSetup() {
    XCTAssertTrue(SampleModelVersion.currentVersion == .version1)
    XCTAssertTrue(SampleModelVersion.allVersions == [.version1, .version2, .version3])
    XCTAssertTrue(SampleModelVersion.version1.next == .version2)
    XCTAssertNil(SampleModelVersion.version3.mappingModelToNextModelVersion())
  }

  func test_MappingModelsByName() {
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
