// CoreDataPlus

import CoreData
import XCTest
@testable import CoreDataPlus

private var cache = [String: NSManagedObjectModel]()

public enum SampleModelVersion: String, CaseIterable {
  case version1 = "SampleModel"
  case version2 = "SampleModel2"
  case version3 = "SampleModel3"
}

extension SampleModelVersion: CoreDataModelVersion {
  public static var allVersions: [SampleModelVersion] { return SampleModelVersion.allCases }
  public static var currentVersion: SampleModelVersion { return .version1 }
  public var modelName: String { return "SampleModel" }

  public var successor: SampleModelVersion? {
    switch self {
    case .version1: return .version2
    case .version2: return .version3
    default: return nil
    }
  }

  public var versionName: String { return rawValue }

  public var modelBundle: Bundle {
    return Bundle.tests
  }

  public func managedObjectModel() -> NSManagedObjectModel {
    if let model = cache[self.versionName], #available(iOS 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, *) {
      return model
    }

    let model = _managedObjectModel()
    cache[self.versionName] = model
    return model
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
        if let em = e.entityMigrationPolicyClassName, em.contains("V2to3MakerPolicyPolicy") {
          /// Hack: we need to change the project module depending on the test target we are currently running
          /// By default in the V2toV3.xcmappingmodel the custom policy  is set to REPLACE_AT_RUNTIME.V2to3MakerPolicyPolicy so that we remember that
          /// REPLACE_AT_RUNTIME is just a placeholder since we can have different targets (and different module names).
          /// https://stackoverflow.com/questions/48284404/core-data-custom-migration-policy-with-multiple-targets

          /// iOS: "CoreDataPlus_Tests_iOS.V2to3MakerPolicyPolicy"
          /// tvOS: "CoreDataPlus_Tests_tvOS.V2to3MakerPolicyPolicy"
          /// macOS: "CoreDataPlus_Tests_macOS.V2to3MakerPolicyPolicy"
          /// spm: "Tests.V2to3MakerPolicyPolicy"

          let policyClassName = NSStringFromClass(V2to3MakerPolicyPolicy.self)
          e.entityMigrationPolicyClassName = policyClassName
        }
      }

      return [mappings]
    default:
      return []
    }
  }
}
