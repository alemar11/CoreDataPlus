// CoreDataPlus

import CoreData
import XCTest
import os.lock

@testable import CoreDataPlus

// Make sure models are loaded in memory
let model3_1 = SampleModelVersion3.version1._managedObjectModel()
let model3_2 = SampleModelVersion3.version2._managedObjectModel()
let model3_3 = SampleModelVersion3.version3._managedObjectModel()

public enum SampleModelVersion3: String, CaseIterable, StagedMigration {
  case version1 = "SampleModel3"
  case version2 = "SampleModel3_v2"
  case version3 = "SampleModel3_v3"
}

extension SampleModelVersion3: ModelVersion {
  public static var allVersions: [SampleModelVersion3] { SampleModelVersion3.allCases }
  public static var currentVersion: SampleModelVersion3 { .version1 }
  public var modelName: String { "SampleModel3" }

  public var next: SampleModelVersion3? {
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
      model3_1
    case .version2:
      model3_2
    case .version3:
      model3_3
    }
  }
}

extension SampleModelVersion3 {
  @available(
    iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0,
    macCatalystApplicationExtension 17.0, *
  )
  public func migrationStageToNextModelVersion() -> NSMigrationStage? {
    switch self {
    // There can't be stages with the same versionCheckSum (you can't have a NSLightweightMigrationStage and a
    // NSCustomMigrationStage referencing the same target versionCheckSum)
    case .version1:
      let stage = NSCustomMigrationStage(
        migratingFrom: self.managedObjectModelReference(),  // v1
        to: self.next!.managedObjectModelReference())  // v2
      stage.label = "V1 to V2 (Add Pet entity and denormalize User entity)"

      stage.willMigrateHandler = { migrationManager, stage in
        // in willMigrateHandler Pet is not yet defined
      }

      stage.didMigrateHandler = { migrationManager, stage in
        guard let container = migrationManager.container else { return }

        let context = container.newBackgroundContext()
        try context.performAndWait {
          let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
          let users = try context.fetch(fetchRequest)
          for user in users {
            if let petName = user.value(forKey: "petName") as? String {
              let pet = NSEntityDescription.insertNewObject(forEntityName: "Pet", into: context)
              pet.setValue(petName, forKey: "name")
              user.setValue(pet, forKey: "pet")
            }
          }
          try context.save()
        }
      }

      return stage
    case .version2:
      let stage = NSLightweightMigrationStage([self.next!.versionChecksum])  // v3
      stage.label = "V2 to V3 (remove petName from User entity)"
      return stage
    default:
      return nil
    }
  }
}

// SampleModel1 and SampleModel2 can't be used for staged migration:
//
// SampleModel1 has a mapping model and it seems that the NSStagedMigrationManager won't work because
// it tries to use that instead.
//
// SampleModel2 is defined programmatically and I didn't find a way to make it work
