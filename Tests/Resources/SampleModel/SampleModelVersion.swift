// CoreDataPlus

import CoreData
import XCTest
import os.lock

@testable import CoreDataPlus

// Make sure models are loaded in memory
let model1 = SampleModelVersion.version1._managedObjectModel()
let model2 = SampleModelVersion.version2._managedObjectModel()
let model3 = SampleModelVersion.version3._managedObjectModel()

public enum SampleModelVersion: String, CaseIterable, LegacyMigration {
  case version1 = "SampleModel"
  case version2 = "SampleModel2"
  case version3 = "SampleModel3"
}

extension SampleModelVersion: ModelVersion {
  public static var allVersions: [SampleModelVersion] { SampleModelVersion.allCases }
  public static var currentVersion: SampleModelVersion { .version1 }
  public var modelName: String { "SampleModel" }

  public var next: SampleModelVersion? {
    switch self {
    case .version1: return .version2
    case .version2: return .version3
    default: return nil
    }
  }

  public var versionName: String { rawValue }

  public var modelBundle: Bundle { Bundle.tests }

  public func managedObjectModel() -> NSManagedObjectModel {
    switch self {
    case .version1:
      model1
    case .version2:
      model2
    case .version3:
      model3
    }
  }
}

extension SampleModelVersion {
  public func mappingModelsToNextModelVersion() -> [NSMappingModel]? {
    switch self {
    case .version1:
      let mapping = SampleModelVersion.version1.inferredMappingModelToNextModelVersion()!
      // Renamed ExpensiveSportCar as LuxuryCar using a "renaming id" on entity ExpensiveSportCar
      // Added the index: byMakerAndNumberPlate on entity Car
      return [mapping]

    case .version2:
      let mappings: NSMappingModel
      mappings = SampleModelVersion.version2.mappingModelToNextModelVersion()!

      for e in mappings.entityMappings {
        if let em = e.entityMigrationPolicyClassName, em.contains("V2to3MakerPolicy") {
          /// Hack: we need to change the project module depending on the test target we are currently running
          /// By default in the V2toV3.xcmappingmodel the custom policy  is set to REPLACE_AT_RUNTIME.V2to3MakerPolicy so that we remember that
          /// REPLACE_AT_RUNTIME is just a placeholder since we can have different targets (and different module names).
          /// https://stackoverflow.com/questions/48284404/core-data-custom-migration-policy-with-multiple-targets

          /// iOS: "CoreDataPlus_Tests_iOS.V2to3MakerPolicy"
          /// tvOS: "CoreDataPlus_Tests_tvOS.V2to3MakerPolicy"
          /// macOS: "CoreDataPlus_Tests_macOS.V2to3MakerPolicy"
          /// spm: "Tests.V2to3MakerPolicy"

          let policyClassName = NSStringFromClass(V2to3MakerPolicy.self)
          e.entityMigrationPolicyClassName = policyClassName
        }
      }

      return [mappings]
    default:
      return []
    }
  }
}
