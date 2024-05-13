// CoreDataPlus

import CoreData
import XCTest
@testable import CoreDataPlus

@available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
final class StagedMigrations_Tests: XCTestCase {
  
  func test_MigrationFromV1ToV2() throws {
    let sourceURL = try Self.createSQLiteSample3ForV1()
    let steps = SampleModelVersion3.version1.stagedMigrationSteps(to: .version2)
    XCTAssertEqual(steps.count, 1)
    
    XCTAssertFalse(try isMigrationNecessary(for: sourceURL, to: SampleModelVersion3.version1))
    XCTAssertTrue(try isMigrationNecessary(for: sourceURL, to: SampleModelVersion3.version2))
    
    let version = try SampleModelVersion3(persistentStoreURL: sourceURL)
    XCTAssertTrue(version == .version1)
    
    let stages = steps.compactMap { $0.stage }
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
    let sourceURL = try Self.createSQLiteSample3ForV1()
    let steps = SampleModelVersion3.version1.stagedMigrationSteps(to: .version3)
    XCTAssertEqual(steps.count, 2)
    
    XCTAssertFalse(try isMigrationNecessary(for: sourceURL, to: SampleModelVersion3.version1))
    XCTAssertTrue(try isMigrationNecessary(for: sourceURL, to: SampleModelVersion3.version2))
    XCTAssertTrue(try isMigrationNecessary(for: sourceURL, to: SampleModelVersion3.version3))
    
    XCTAssertTrue(SampleModelVersion3.version1.isLightWeightMigrationPossibleToNextModelVersion())
    XCTAssertTrue(SampleModelVersion3.version2.isLightWeightMigrationPossibleToNextModelVersion())
    XCTAssertFalse(SampleModelVersion3.version3.isLightWeightMigrationPossibleToNextModelVersion()) // no V4
    
    let version = try SampleModelVersion3(persistentStoreURL: sourceURL)
    XCTAssertTrue(version == .version1)
    
    let stages = steps.compactMap { $0.stage }
    let migrator = NSStagedMigrationManager(stages)
    let container = NSPersistentContainer(name: "SampleModel3",
                                          managedObjectModel: SampleModelVersion3.version3.managedObjectModel())
    
    let storeDescription = try XCTUnwrap(container.persistentStoreDescriptions.first)
    storeDescription.url = sourceURL
    storeDescription.setOption(migrator, forKey: NSPersistentStoreStagedMigrationManagerOptionKey)
    storeDescription.shouldAddStoreAsynchronously = true
    
    let expectation = expectation(description: "\(#function)\(#line)")
    container.loadPersistentStores { storeDescription, error in
      if let error = error {
        XCTFail(error.localizedDescription)
      } else {
        expectation.fulfill()
      }
    }
    
    wait(for: [expectation])
    
    let migratedContext = container.viewContext
    let users = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "User"))
    for user in users {
      let pet = user.value(forKey: "pet") as? NSManagedObject
      XCTAssertNotNil(pet)
      XCTAssertNotNil(pet?.value(forKey: "name"))
    }
    
    migratedContext._fix_sqlite_warning_when_destroying_a_store()
    try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
  }
  
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
  
}

@available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
extension StagedMigrations_Tests {
  static func createSQLiteSample2ForV1() throws -> URL {
    let bundle = Bundle.tests
    let _sourceURL = try XCTUnwrap(bundle.url(forResource: "SampleModel2_V1", withExtension: "sqlite"))
    
    // Being the test run multiple times, we create an unique copy for every test
    let uuid = UUID().uuidString
    let sourceURL = bundle.bundleURL.appendingPathComponent("SampleModel2_V1_copy-\(uuid).sqlite")
    try FileManager.default.copyItem(at: _sourceURL, to: sourceURL)
    XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
    return sourceURL
  }
  
  static func createSQLiteSample2ForV2() throws -> URL {
    let bundle = Bundle.tests
    let _sourceURL = try XCTUnwrap(bundle.url(forResource: "SampleModel2_V2", withExtension: "sqlite"))
    
    // Being the test run multiple times, we create an unique copy for every test
    let uuid = UUID().uuidString
    let sourceURL = bundle.bundleURL.appendingPathComponent("SampleModel2_V2_copy-\(uuid).sqlite")
    try FileManager.default.copyItem(at: _sourceURL, to: sourceURL)
    XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
    return sourceURL
  }
  
  static func createSQLiteSample3ForV1() throws -> URL {
    let bundle = Bundle.tests
    let _sourceURL = try XCTUnwrap(bundle.url(forResource: "SampleModel3_V1", withExtension: "sqlite"))
    
    // Being the test run multiple times, we create an unique copy for every test
    let uuid = UUID().uuidString
    let sourceURL = bundle.bundleURL.appendingPathComponent("SampleModel3_V1_copy-\(uuid).sqlite")
    try FileManager.default.copyItem(at: _sourceURL, to: sourceURL)
    XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
    return sourceURL
  }
}
