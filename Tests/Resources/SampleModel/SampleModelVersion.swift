// CoreDataPlus

import CoreData
import XCTest
import os.lock

@testable import CoreDataPlus

// Make sure models are loaded in memory
let model1 = SampleModelVersion.version1._managedObjectModel()
let model2 = SampleModelVersion.version2._managedObjectModel()
let model3 = SampleModelVersion.version3._managedObjectModel()

public enum SampleModelVersion: String, CaseIterable {
  case version1 = "SampleModel"
  case version2 = "SampleModel2"
  case version3 = "SampleModel3"
}

extension SampleModelVersion: ModelVersion {
  public static var allVersions: [SampleModelVersion] { SampleModelVersion.allCases }
  public static var currentVersion: SampleModelVersion { .version1 }
  public var modelName: String { "SampleModel" }

  public var successor: SampleModelVersion? {
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

extension SampleModelVersion {
  @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
  public func migrationStagesToNextModelVersion() -> [NSMigrationStage]? {
    switch self {
    case .version1:
      let stage = NSLightweightMigrationStage([SampleModelVersion.version1.versionChecksum])
      stage.label = "V1 to V2 (Lightweight)"
      return [stage]
    case .version2:
      let stage = NSCustomMigrationStage(migratingFrom: SampleModelVersion.version2.managedObjectModelReference(),
                                         to: SampleModelVersion.version3.managedObjectModelReference())

      stage.label = "V2 to V3 (Custom)"
      
      stage.willMigrateHandler = { migrationManager, stage in
        return
        guard let container = migrationManager.container else {
          return
        }
        
        var makers = [NSManagedObject]()
        
        let context = container.newBackgroundContext()
        try context.performAndWait {
          let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Car")
          let allCars = try context.fetch(fetchRequest)
          for car in allCars {
            if let makerString = car.value(forKey: "maker") as? String {
              let maker = makers.first { $0.entity.name == "Maker" && $0.value(forKey: "name") as? String == makerString }
              if let maker {
                if var currentCars = maker.value(forKey: "cars") as? Set<NSManagedObject> {
                  currentCars.insert(car)
                  maker.setValue(currentCars, forKey: "cars")
                } else {
                  var cars = Set<NSManagedObject>()
                  cars.insert(car)
                  maker.setValue(cars, forKey: "cars")
                }
              } else {
                let maker = NSEntityDescription.insertNewObject(forEntityName: "Maker", into: context)
                var cars = Set<NSManagedObject>()
                cars.insert(car)
                maker.setValue(cars, forKey: "cars")
                makers.append(maker)
              }
            }
            
            try context.save()
          }
        }
 // TODO: remove this
      }
      
      stage.didMigrateHandler = { migrationManager, stage in
        print("---")
        
        guard let container = migrationManager.container else {
          return
        }
        
        var makers = [NSManagedObject]()
        
        let context = container.newBackgroundContext()
        print(container.managedObjectModel.entities)
      }
      return [stage]
    default:
      return []
    }
  }
}
