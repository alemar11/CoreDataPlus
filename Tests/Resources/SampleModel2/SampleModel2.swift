// CoreDataPlus

import CoreData
@testable import CoreDataPlus

public typealias V1 = SampleModel2.V1
public typealias V2 = SampleModel2.V2

public enum SampleModel2 {
  public enum V1 { }
  public enum V2 { }
}

@available(OSX 10.15, *)
extension SampleModel2 {
  public enum SampleModel2Version: String, CaseIterable {
    case version1 = "SampleModel"
    case version2 = "SampleModel2"
    case version3 = "SampleModel3"
  }
}

@available(OSX 10.15, *)
extension SampleModel2.SampleModel2Version: ModelVersion {
  public static var allVersions: [SampleModel2.SampleModel2Version] { return SampleModel2.SampleModel2Version.allCases }
  public static var currentVersion: SampleModel2.SampleModel2Version { return .version1 }
  public var modelName: String { return "SampleModel" }

  public var successor: SampleModel2.SampleModel2Version? {
    switch self {
      case .version1: return .version2
      case .version2: return .version3
      default: return nil
    }
  }

  public var versionName: String { return rawValue }

  public var modelBundle: Bundle { Bundle.tests }
  
  public var options: [AnyHashable : Any]? {
    var options = [
      NSMigratePersistentStoresAutomaticallyOption: true,
      NSInferMappingModelAutomaticallyOption: false,
      NSPersistentHistoryTrackingKey: false,
      NSPersistentHistoryTokenKey: true
    ]
    
    switch self {
    case .version1, .version3:
      return options
    case .version2:
      options[NSPersistentHistoryTrackingKey] = true //❌ you can't change this value once set to true
      options[NSPersistentHistoryTokenKey] = true
      options[NSReadOnlyPersistentStoreOption] = false
    }
    return options
  }

  public func managedObjectModel() -> NSManagedObjectModel {
    switch self {
      case .version1: return V1.makeManagedObjectModel()
      case .version2: return V2.makeManagedObjectModel()
      case .version3: fatalError("not implemented")
    }
  }
}

@available(OSX 10.15, *)
extension SampleModel2.SampleModel2Version {
  public func mappingModelsToNextModelVersion() -> [NSMappingModel]? {
    switch self {
      case .version1:
        let mapping = SampleModel2.SampleModel2Version.version1.inferredMappingModelToNextModelVersion()!
        // Removed Author siteURL
        // Renamed Book covert into frontCover
        return [mapping]
      case .version2:
        let mappings: NSMappingModel
        fatalError("not implemented")
      default:
        return []
    }
  }
}

