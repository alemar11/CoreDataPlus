// CoreDataPlus

import CoreData
import XCTest

@available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
final class StagedMigrations_Tests: XCTestCase {
  @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
//  func test_yo() {
//    print(SampleModelVersion3.version1.managedObjectModel().versionChecksum)
//    print(SampleModelVersion3.version2.managedObjectModel().versionChecksum)
//  }
  
//  func test_generateSample() throws {
//    let container = NSPersistentContainer(name: "SampleModel3",
//                                          managedObjectModel: SampleModelVersion3.version1.managedObjectModel())
//    
//    let url = URL.newDatabaseURL(withID: UUID())
//    
//    let description = NSPersistentStoreDescription()
//    description.url = url
//    container.persistentStoreDescriptions = [description]
//
//    
//    container.loadPersistentStores { description, error in
//      XCTAssertNil(error)
//    }
//    
//    let context = container.viewContext
//    
//    for x in 0..<3 {
//      for i in 0..<4 {
//        let user = User(context: context)
//        user.name = "User_\(x)"
//        user.petName = "Dog_\(x)_\(i)"
//      }
//    }
//    
//    try context.save()
//    
//    print(url.path())
//  }

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
  
  @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
  func test_MigrationFromV1ToV2() throws {
    let sourceURL = try createSQLiteSample3ForV1()
    let steps = SampleModelVersion3.version1.stagedMigrationSteps(to: .version2)
    XCTAssertEqual(steps.count, 1)
    
    let version = try SampleModelVersion3(persistentStoreURL: sourceURL)
    XCTAssertTrue(version == .version1)
    
    let stages = steps.flatMap { $0.stages }
    let migrator = NSStagedMigrationManager(stages)
    let container = NSPersistentContainer(name: "SampleModel3",
                                          managedObjectModel: SampleModelVersion3.version2.managedObjectModel())
    
    let storeDescription = try XCTUnwrap(container.persistentStoreDescriptions.first)
    storeDescription.url = sourceURL
    storeDescription.setOption(migrator, forKey: NSPersistentStoreStagedMigrationManagerOptionKey)

    container.loadPersistentStores { storeDescription, error in
      if let error = error {
        XCTFail(error.localizedDescription)
      }
    }
    
    let migratedContext = container.viewContext
    let users = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "User"))
    for user in users {
      let pet = user.value(forKey: "pet") as? NSManagedObject
      let petName = user.value(forKey: "petName") as? String
      XCTAssertNotNil(pet)
      XCTAssertNotNil(petName)
      XCTAssertEqual(pet?.value(forKey: "name") as? String, petName)
    }
  
    migratedContext._fix_sqlite_warning_when_destroying_a_store()
    try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
  }
  
  func test_MigrationFromV1ToV3() throws {
    let sourceURL = try createSQLiteSample3ForV1()
    let steps = SampleModelVersion3.version1.stagedMigrationSteps(to: .version3)
    XCTAssertEqual(steps.count, 2)
    
    let version = try SampleModelVersion3(persistentStoreURL: sourceURL)
    XCTAssertTrue(version == .version1)
    
    let stages = steps.flatMap { $0.stages }
    let migrator = NSStagedMigrationManager(stages)
    let container = NSPersistentContainer(name: "SampleModel3",
                                          managedObjectModel: SampleModelVersion3.version3.managedObjectModel())
    
    let storeDescription = try XCTUnwrap(container.persistentStoreDescriptions.first)
    storeDescription.url = sourceURL
    storeDescription.setOption(migrator, forKey: NSPersistentStoreStagedMigrationManagerOptionKey)

    container.loadPersistentStores { storeDescription, error in
      if let error = error {
        XCTFail(error.localizedDescription)
      }
    }
    
    let migratedContext = container.viewContext
    let users = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "User"))
    for user in users {
      let pet = user.value(forKey: "pet") as? NSManagedObject
      XCTAssertNotNil(pet)
    }

    migratedContext._fix_sqlite_warning_when_destroying_a_store()
    try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
  }

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

//func createSQLiteSample2ForV1() throws -> URL {
//  let bundle = Bundle.tests
//  let _sourceURL = try XCTUnwrap(bundle.url(forResource: "SampleModel2V1", withExtension: "sqlite"))
//
//  // Being the test run multiple times, we create an unique copy for every test
//  let uuid = UUID().uuidString
//  let sourceURL = bundle.bundleURL.appendingPathComponent("SampleModel2V1_copy-\(uuid).sqlite")
//  try FileManager.default.copyItem(at: _sourceURL, to: sourceURL)
//  XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
//  return sourceURL
//}
//
//func createSQLiteSample2ForV2() throws -> URL {
//  let bundle = Bundle.tests
//  let _sourceURL = try XCTUnwrap(bundle.url(forResource: "SampleModel2V2", withExtension: "sqlite"))
//
//  // Being the test run multiple times, we create an unique copy for every test
//  let uuid = UUID().uuidString
//  let sourceURL = bundle.bundleURL.appendingPathComponent("SampleModel2V2_copy-\(uuid).sqlite")
//  try FileManager.default.copyItem(at: _sourceURL, to: sourceURL)
//  XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
//  return sourceURL
//}

func createSQLiteSample3ForV1() throws -> URL {
  let bundle = Bundle.tests
  let _sourceURL = try XCTUnwrap(bundle.url(forResource: "SampleModel3_V1", withExtension: "sqlite"))

  // Being the test run multiple times, we create an unique copy for every test
  let uuid = UUID().uuidString
  let sourceURL = bundle.bundleURL.appendingPathComponent("SampleModel3_V1_copy-\(uuid).sqlite")
  try FileManager.default.copyItem(at: _sourceURL, to: sourceURL)
  XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
  return sourceURL
}
