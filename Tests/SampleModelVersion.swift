//
// CoreDataPlus
//
//  Copyright © 2016-2018 Tinrobots.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import CoreData
import XCTest
@testable import CoreDataPlus

public enum SampleModelVersion: String {
  case version1 = "SampleModel"
  case version2 = "SampleModel2"
  case version3 = "SampleModel3"
}

extension SampleModelVersion: ModelVersion {

  public var modelName: String { return "SampleModel" }

  public static var allVersions: [SampleModelVersion] { return [.version1, .version2, .version3] } //TODO: Swift 4.2

  public static var currentVersion: SampleModelVersion { return .version1 }

  public var successor: SampleModelVersion? {
    switch self {
    case .version1: return .version2
    case .version2: return .version3
    default: return nil
    }
  }

  public var versionName: String { return rawValue }

  public var modelBundle: Bundle {
    class Object {} // used to get the current bundle 🤓
    return Bundle(for: Object.self)
  }

  public func managedObjectModel() -> NSManagedObjectModel {
    if ProcessInfo.isRunningSwiftPackageTests {
      let sampleFolderURL = URL(fileURLWithPath: #file, isDirectory: false).deletingLastPathComponent()
      let momUrl = sampleFolderURL.appendingPathComponent("\(modelName).momd/\(versionName).mom")

      XCTAssertTrue(FileManager.default.fileExists(atPath: momUrl.path))

      guard let model = NSManagedObjectModel(contentsOf: momUrl) else {
        preconditionFailure("Error initializing Managed Object Model: cannot open model at \(momUrl).")
      }

      return model
    }
    return _managedObjectModel()
  }

}

extension SampleModelVersion {

  func mappingModel_swift_package_tests() -> [NSMappingModel] {
    switch self {
    case .version2:
      let sampleFolderURL = URL(fileURLWithPath: #file, isDirectory: false).deletingLastPathComponent()
      let cdmUrl = sampleFolderURL.appendingPathComponent("V2toV3.cdm")
      if let mapping = NSMappingModel(contentsOf: cdmUrl) {
        return [mapping]
      }
      return []
    default: return []
    }
  }

  public func mappingModelsToNextModelVersion() -> [NSMappingModel]? {
    switch self {
    case .version1:
      let mapping = SampleModelVersion.version1.inferredMappingModelToNextModelVersion()!
      // Renamed ExpensiveSportCar as LuxuryCar using a "renaming id" on entity ExpensiveSportCar
      // Added the index: byMakerAndNumberPlate on entity Car
      return [mapping]

    case .version2:
      let mappings: NSMappingModel
      if ProcessInfo.isRunningSwiftPackageTests {
        mappings = mappingModel_swift_package_tests().first!
      } else {
        mappings = SampleModelVersion.version2.mappingModelToNextModelVersion()!
      }
      for e in mappings.entityMappings {
        if let em = e.entityMigrationPolicyClassName, em.contains("V2to3MakerPolicyPolicy") {
          /// Hack: we need to change the project module depending on the test target
          /// default value: CoreDataPlus_Tests_macOS.V2to3MakerPolicyPolicy
          #if os(iOS)
          e.entityMigrationPolicyClassName = "CoreDataPlus_Tests_iOS.V2to3MakerPolicyPolicy"
          #elseif os(tvOS)
          e.entityMigrationPolicyClassName = "CoreDataPlus_Tests_tvOS.V2to3MakerPolicyPolicy"
          #endif

          if ProcessInfo.isRunningSwiftPackageTests {
            XCTFail("NSEntityMigrationPolicy doesn't work on Swift Package testing.")
          }

        }
      }

      return [mappings]
    default:
      return []
    }
  }

}

