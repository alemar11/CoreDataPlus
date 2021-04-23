// CoreDataPlus

import CoreData
@testable import CoreDataPlus

public typealias V1 = SampleModel2.V1
public typealias V2 = SampleModel2.V2
public typealias V3 = SampleModel2.V3

public enum SampleModel2 {
  static var modelCache = [String: NSManagedObjectModel]()
  public enum V1 { }
  public enum V2 { }
  public enum V3 { }
}

@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
extension SampleModel2 {
  public enum SampleModel2Version: String, CaseIterable {
    case version1 = "SampleModel2V1"
    case version2 = "SampleModel2V2"
    case version3 = "SampleModel3V3"
  }
}

@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
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

@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
extension SampleModel2.SampleModel2Version {
  public func mappingModelsToNextModelVersion() -> [NSMappingModel]? {
    switch self {
      case .version1:
        let mappingModel = SampleModel2.SampleModel2Version.version1.inferredMappingModelToNextModelVersion()!
        // Removed Author siteURL
        // Renamed Book cover into frontCover
        return [mappingModel]
      case .version2:
        let mappingModel = V3.makeMappingModelV2toV3()

        let sourceModel = V2.makeManagedObjectModel()
        let destinationModel = V3.makeManagedObjectModel()
        var entityMappings = [NSEntityMapping]()

        for mapping in mappingModel.entityMappings {
          if let sourceName = mapping.sourceEntityName {
            let mappingSourceHash = mapping.sourceEntityVersionHash!
            let sourceHash = sourceModel.entityVersionHashesByName[sourceName]!
            if mappingSourceHash != sourceHash, sourceModel.entitiesByName[sourceName]!.canBugMigration() {
              mapping.sourceEntityVersionHash = sourceHash
            } else if mappingSourceHash != sourceHash {
              print("❌---- \(mapping)")
            }
          }
          let destName = mapping.destinationEntityName!
          let mappingDestHash = mapping.destinationEntityVersionHash!
          let destHash = destinationModel.entityVersionHashesByName[destName]!
          if mappingDestHash != destHash, destinationModel.entitiesByName[destName]!.canBugMigration() {
            mapping.destinationEntityVersionHash = destHash
          } else if mappingDestHash != destHash {
            print("❌---- \(mapping)")
          }
          entityMappings.append(mapping)
        }
        mappingModel.entityMappings = entityMappings



        return [mappingModel]
      default:
        return []
    }
  }
}

//@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
//private extension NSMappingModel {
//  func fixMe() {
//    let sourceModel = V2.makeManagedObjectModel()
//    let destinationModel = V3.makeManagedObjectModel()
//
//    var entityMappings = [NSEntityMapping]()
//    for mapping in self.entityMappings {
//
//      if let sourceName = mapping.sourceEntityName {
//        let mappingSourceHash = mapping.sourceEntityVersionHash!
//        let sourceHash = sourceModel.entityVersionHashesByName[sourceName]!
//        if mappingSourceHash != sourceHash, sourceModel.entitiesByName[sourceName]!.canBugMigration() {
//          mapping.sourceEntityVersionHash = sourceHash
//        }
//      }
//      if let destName = mapping.destinationEntityName {
//      let mappingDestHash = mapping.destinationEntityVersionHash!
//      let destHash = destinationModel.entityVersionHashesByName[destName]!
//      if mappingDestHash != destHash, destinationModel.entitiesByName[destName]!.canBugMigration() {
//        mapping.destinationEntityVersionHash = destHash
//      }
//      }
//      entityMappings.append(mapping)
//    }
//
//    self.entityMappings = entityMappings
//  }
//}

// https://github.com/diogot/CoreDataModelMigrationBug
@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
private extension NSEntityDescription {
    func canBugMigration() -> Bool {
      !properties.compactMap { $0 as? NSDerivedAttributeDescription }.isEmpty
    }
}
