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
  public enum SampleModel2Version: String, CaseIterable {
    case version1 = "SampleModel2V1"
    case version2 = "SampleModel2V2"
    case version3 = "SampleModel3V3"
  }
}

extension SampleModel2.SampleModel2Version: ModelVersion {
  public static var allVersions: [SampleModel2.SampleModel2Version] { SampleModel2.SampleModel2Version.allCases }
  public static var currentVersion: SampleModel2.SampleModel2Version { .version1 }
  public var modelName: String { "SampleModel2" }

  public var successor: SampleModel2.SampleModel2Version? {
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

extension SampleModel2.SampleModel2Version {
  @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
  public func migrationStagesToNextModelVersion() -> [NSMigrationStage]? {
    switch self {
    case .version1:
      
      let stage = NSLightweightMigrationStage([SampleModel2.SampleModel2Version.version1.versionChecksum])
      
//      let stage = NSCustomMigrationStage(migratingFrom: self.managedObjectModelReference(),
//                                         to: self.successor!.managedObjectModelReference())
      
      stage.label = "V1 to V2 (Lightweight)"
      return [stage]
    case .version2:
      let stage = NSCustomMigrationStage(migratingFrom: self.managedObjectModelReference(),
                                         to: self.successor!.managedObjectModelReference())

      stage.label = "V2 to V3 (Custom)"
   fatalError("No implemented yet")
//      stage.willMigrateHandler = { migrationManager, stage in
//        return
//        guard let container = migrationManager.container else {
//          return
//        }
//        
//        var makers = [NSManagedObject]()
//        
//        let context = container.newBackgroundContext()
//        try context.performAndWait {
//          let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Car")
//          let allCars = try context.fetch(fetchRequest)
//          for car in allCars {
//            if let makerString = car.value(forKey: "maker") as? String {
//              let maker = makers.first { $0.entity.name == "Maker" && $0.value(forKey: "name") as? String == makerString }
//              if let maker {
//                if var currentCars = maker.value(forKey: "cars") as? Set<NSManagedObject> {
//                  currentCars.insert(car)
//                  maker.setValue(currentCars, forKey: "cars")
//                } else {
//                  var cars = Set<NSManagedObject>()
//                  cars.insert(car)
//                  maker.setValue(cars, forKey: "cars")
//                }
//              } else {
//                let maker = NSEntityDescription.insertNewObject(forEntityName: "Maker", into: context)
//                var cars = Set<NSManagedObject>()
//                cars.insert(car)
//                maker.setValue(cars, forKey: "cars")
//                makers.append(maker)
//              }
//            }
//            
//            try context.save()
//          }
//        }
//
//      }
//      
//      stage.didMigrateHandler = { migrationManager, stage in
//        print("---")
//        
//        guard let container = migrationManager.container else {
//          return
//        }
//        
//        var makers = [NSManagedObject]()
//        
//        let context = container.newBackgroundContext()
//        print(container.managedObjectModel.entities)
//      }
      return [stage]
    default:
      return []
    }
  }
}
