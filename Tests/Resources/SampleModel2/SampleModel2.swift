// CoreDataPlus

import CoreData
@testable import CoreDataPlus
import os.lock

public typealias V1 = SampleModel2.V1
public typealias V2 = SampleModel2.V2
public typealias V3 = SampleModel2.V3

public enum SampleModel2 {
  static let modelCache = OSAllocatedUnfairLock(uncheckedState: [String: NSManagedObjectModel]())
  public enum V1 { }
  public enum V2 { }
  public enum V3 { }
}

extension SampleModel2 {
  public enum SampleModel2Version: String, CaseIterable {
    case version1 = "SampleModel2V1"
    case version2 = "SampleModel2V2"
    case version3 = "SampleModel3V3"
  }
}

extension SampleModel2.SampleModel2Version: ModelVersion {
  public static var allVersions: [SampleModel2.SampleModel2Version] { return SampleModel2.SampleModel2Version.allCases }
  public static var currentVersion: SampleModel2.SampleModel2Version { return .version1 }
  public var modelName: String { return "SampleModel2" }

  public var successor: SampleModel2.SampleModel2Version? {
    switch self {
      case .version1: return .version2
      case .version2: return .version3
      default: return nil
    }
  }

  public var versionName: String { return rawValue }

  public var modelBundle: Bundle { Bundle.tests }

  public func managedObjectModel() -> NSManagedObjectModel {
    switch self {
      case .version1: return V1.makeManagedObjectModel()
      case .version2: return V2.makeManagedObjectModel()
      case .version3: return V3.makeManagedObjectModel()
    }
  }
}

extension SampleModel2.SampleModel2Version {
  public func mappingModelsToNextModelVersion() -> [NSMappingModel]? {
    switch self {
      case .version1:
        let mappingModel = SampleModel2.SampleModel2Version.version1.inferredMappingModelToNextModelVersion()!
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
