// CoreDataPlus

import CoreData
import os.lock

@testable import CoreDataPlus

public typealias V1 = SampleModel2.V1
public typealias V2 = SampleModel2.V2
public typealias V3 = SampleModel2.V3

//public typealias SampleModel2Version = SampleModel2.SampleModel2Version

public enum SampleModel2 {
  static let modelCache = OSAllocatedUnfairLock(uncheckedState: [String: NSManagedObjectModel]())
  public enum V1 {}
  public enum V2 {}
  public enum V3 {}
}

extension SampleModel2 {
  public enum SampleModelVersion2: String, CaseIterable, LegacyMigration {
    case version1 = "SampleModel2V1"
    case version2 = "SampleModel2V2"
    case version3 = "SampleModel3V3"
  }
}

let model2_1 = V1.makeManagedObjectModel()
let model2_2 = V2.makeManagedObjectModel()
let model2_3 = V3.makeManagedObjectModel()

extension SampleModel2.SampleModelVersion2: ModelVersion {
  public static var allVersions: [SampleModel2.SampleModelVersion2] { SampleModel2.SampleModelVersion2.allCases }
  public static var currentVersion: SampleModel2.SampleModelVersion2 { .version1 }
  public var modelName: String { "SampleModel2" }

  public var next: SampleModel2.SampleModelVersion2? {
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
    case .version1: model2_1
    case .version2: model2_2
    case .version3: model2_3
    }
  }
}

extension SampleModel2.SampleModelVersion2 {
  public func mappingModelsToNextModelVersion() -> [NSMappingModel]? {
    switch self {
    case .version1:
      let mappingModel = SampleModel2.SampleModelVersion2.version1.inferredMappingModelToNextModelVersion()!
      // Removed Author siteURL
      // Renamed Book cover into frontCover
      return [mappingModel]
    case .version2:
      let mappingModels = V3.makeMappingModelV2toV3()
      return mappingModels
    default:
      return []
    }
  }
}
