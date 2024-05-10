// CoreDataPlus

import CoreData
import XCTest

final class StagedMigrations_Tests: BaseTestCase {

//  @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
//  func test_MigrationFromV1ToV2() throws {
//    // V1 to V2 can be tested with SampleModel because there aren't any mapping models otherwise you would get this error:
//    // Staged Migration was requested with NSPersistentStoreStagedMigrationManagerOptionKey but without setting NSMigratePersistentStoresAutomaticallyOption and NSInferMappingModelAutomaticallyOption to YES.
//    // If we use SampleModel to migrate from V2 to V3, the Core Data machinery will try to use the V2toV3 mapping model if NSInferMappingModelAutomaticallyOption is set to YES
//    
//    let sourceURL = try createSQLiteSampleForV1()
//    let steps = SampleModelVersion.version1.stagedMigrationSteps(to: .version2)
//    XCTAssertEqual(steps.count, 1)
//    
//    let version = try SampleModelVersion(persistentStoreURL: sourceURL)
//    XCTAssertTrue(version == .version1)
//    
//    let stages = steps.flatMap { $0.stages }
//    let migrator = NSStagedMigrationManager(stages)
//    let container = NSPersistentContainer(name: "SampleModel", managedObjectModel: model2)
//    
//    let storeDescription = try XCTUnwrap(container.persistentStoreDescriptions.first)
//    storeDescription.url = sourceURL
//    storeDescription.setOption(migrator, forKey: NSPersistentStoreStagedMigrationManagerOptionKey)
//
//    container.loadPersistentStores { storeDescription, error in
//      if let error = error {
//        XCTFail(error.localizedDescription)
//      }
//    }
//    
//    let migratedContext = container.viewContext
//    let luxuryCars = try LuxuryCar.fetchObjects(in: migratedContext) // won't work with SPM tests
//    XCTAssertEqual(luxuryCars.count, 5)
//
//    let cars = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Car"))
//    XCTAssertTrue(cars.count >= 1)
//
//    for car in cars {
//      if car is LuxuryCar || car is SportCar {
//        XCTAssertEqual(car.entity.indexes.count, 0)
//      } else if car is Car {
//        let index = car.entity.indexes.first
//        XCTAssertNotNil(index, "There should be a compound index")
//        XCTAssertEqual(index!.elements.count, 2)
//      } else {
//        XCTFail("Undefined")
//      }
//    }
//
//    migratedContext._fix_sqlite_warning_when_destroying_a_store()
//    try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
//  }
  
//  @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
//  func test_MigrationFromV1ToV2() throws {
//    let sourceURL = try createSQLiteSample2ForV1()
//    let steps = SampleModel2.SampleModel2Version.version1.stagedMigrationSteps(to: .version2)
//    XCTAssertEqual(steps.count, 1)
//    
//    let version = try SampleModel2.SampleModel2Version(persistentStoreURL: sourceURL)
//    XCTAssertTrue(version == .version1)
//    
//    let stages = steps.flatMap { $0.stages }
//    let migrator = NSStagedMigrationManager(stages)
//    let container = NSPersistentContainer(name: "SampleModel2", 
//                                          managedObjectModel: SampleModel2.SampleModel2Version.version1.managedObjectModel())
//    
//    let storeDescription = try XCTUnwrap(container.persistentStoreDescriptions.first)
//    storeDescription.url = sourceURL
//    storeDescription.setOption(migrator, forKey: NSPersistentStoreStagedMigrationManagerOptionKey)
//    storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
//
//    container.loadPersistentStores { storeDescription, error in
//      if let error = error {
//        XCTFail(error.localizedDescription)
//      }
//    }
//    
//    let migratedContext = container.viewContext
//    let authors = try AuthorV2.fetchObjects(in: migratedContext)
//    XCTAssertEqual(authors.count, 2)
//
////    let cars = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Car"))
////    XCTAssertTrue(cars.count >= 1)
////
//    for author in authors {
//      for book in author.books {
//        let b = book as? BookV2
//        print("🔴", b?.frontCover)
//      }
////      if car is LuxuryCar || car is SportCar {
////        XCTAssertEqual(car.entity.indexes.count, 0)
////      } else if car is Car {
////        let index = car.entity.indexes.first
////        XCTAssertNotNil(index, "There should be a compound index")
////        XCTAssertEqual(index!.elements.count, 2)
////      } else {
////        XCTFail("Undefined")
////      }
//    }
//
//    migratedContext._fix_sqlite_warning_when_destroying_a_store()
//    try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
//  }

//  @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
//  func test_MigrationFromV2ToV3() throws {
//    let sourceURL = try createSQLiteSampleForV2()
//    let steps = SampleModelVersion.version2.stagedMigrationSteps(to: .version3)
//    XCTAssertEqual(steps.count, 1)
//    
////    let version = try SampleModelVersion(persistentStoreURL: sourceURL)
////    XCTAssertTrue(version == .version2)
//    
//    let stages = steps.flatMap { $0.stages }
//    let migrator = NSStagedMigrationManager(stages)
//    let container = NSPersistentContainer(name: "SampleModel", managedObjectModel: model3)
//    
//    let storeDescription = try XCTUnwrap(container.persistentStoreDescriptions.first)
//    storeDescription.url = sourceURL
//    
//    
//    /// Staged Migration was requested with NSPersistentStoreStagedMigrationManagerOptionKey but without setting NSMigratePersistentStoresAutomaticallyOption and NSInferMappingModelAutomaticallyOption to YES.
//    
//    storeDescription.setOption(migrator, forKey: NSPersistentStoreStagedMigrationManagerOptionKey)
//    //storeDescription.setOption(false as NSObject, forKey: NSMigratePersistentStoresAutomaticallyOption)
//    //storeDescription.shouldInferMappingModelAutomatically = false
//    
//    
//    container.loadPersistentStores { storeDescription, error in
//      if let error = error {
//        print(error)
//        XCTFail(error.localizedDescription)
//      }
//    }
//    
//    let migratedContext = container.viewContext
//    
//    migratedContext._fix_sqlite_warning_when_destroying_a_store()
//    try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
//  }

}

func createSQLiteSample2ForV1() throws -> URL {
  let bundle = Bundle.tests
  let _sourceURL = try XCTUnwrap(bundle.url(forResource: "SampleModel2V1", withExtension: "sqlite"))

  // Being the test run multiple times, we create an unique copy for every test
  let uuid = UUID().uuidString
  let sourceURL = bundle.bundleURL.appendingPathComponent("SampleModel2V1_copy-\(uuid).sqlite")
  try FileManager.default.copyItem(at: _sourceURL, to: sourceURL)
  XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
  return sourceURL
}

func createSQLiteSample2ForV2() throws -> URL {
  let bundle = Bundle.tests
  let _sourceURL = try XCTUnwrap(bundle.url(forResource: "SampleModel2V2", withExtension: "sqlite"))

  // Being the test run multiple times, we create an unique copy for every test
  let uuid = UUID().uuidString
  let sourceURL = bundle.bundleURL.appendingPathComponent("SampleModel2V2_copy-\(uuid).sqlite")
  try FileManager.default.copyItem(at: _sourceURL, to: sourceURL)
  XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
  return sourceURL
}
