// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

class CoreDataMigrationsTests: XCTestCase {
  // MARK: - LightWeight Migration

  /// Creates a .sqlite with some data for the initial model (version 1)
  func createSampleVersion1(completion: @escaping (Result<URL,Error>) -> Void) {
    let containerSQLite = NSPersistentContainer(name: "SampleModel-\(UUID())", managedObjectModel: model)
    containerSQLite.loadPersistentStores { (description, error) in
      if let error = error {
        completion(.failure(error))
        return
      }
      do {
        let context = containerSQLite.viewContext
        let sourceURL = containerSQLite.persistentStoreDescriptions[0].url!
        context.fillWithSampleData()
        try context.save()
        print("sample create at: \(sourceURL)")
        completion(.success(sourceURL))
      } catch {
        print(error)
        completion(.failure(error))
      }
    }
  }

  func testMigrationFromNotExistingPersistentStore() {
    let url = URL(fileURLWithPath: "/path/to/nothing.sqlite")
    XCTAssertThrowsError(try CoreDataMigration.migrateStore(at: url, targetVersion: SampleModelVersion.version2),
                         "The store shouldn't exist.")
  }

  func testIfMigrationsIsNeeded() throws {
    let bundle = Bundle.tests
    let sourceURLV1 = bundle.url(forResource: "SampleModelV1", withExtension: "sqlite")!
    let sourceURLV2 = bundle.url(forResource: "SampleModelV2", withExtension: "sqlite")!
    let migrationNeededFromV1toV1 = try CoreDataPlus.isMigrationNecessary(for: sourceURLV1, to: SampleModelVersion.version1)
    XCTAssertFalse(migrationNeededFromV1toV1)
    let migrationNeededFromV1toV2 = try CoreDataPlus.isMigrationNecessary(for: sourceURLV1, to: SampleModelVersion.version2)
    XCTAssertTrue(migrationNeededFromV1toV2)
    let migrationNeededFromV1toV3 = try CoreDataPlus.isMigrationNecessary(for: sourceURLV1, to: SampleModelVersion.version3)
    XCTAssertTrue(migrationNeededFromV1toV3)
    let migrationNeededFromV2toV1 = try CoreDataPlus.isMigrationNecessary(for: sourceURLV2, to: SampleModelVersion.version1)
    XCTAssertFalse(migrationNeededFromV2toV1)
  }

  func testMigrationFromVersion1ToVersion2() throws {
    let bundle = Bundle.tests
    let _sourceURL = bundle.url(forResource: "SampleModelV1", withExtension: "sqlite")!  // 125 cars, 5 sport cars

    // Being the test run multiple times, we create an unique copy for every test
    let uuid = UUID().uuidString
    let sourceURL = bundle.bundleURL.appendingPathComponent("SampleModelV1_copy-\(uuid).sqlite")
    try FileManager.default.copyItem(at: _sourceURL, to: sourceURL)
    XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))

    let targetVersion = SampleModelVersion.version2
    let steps = SampleModelVersion.version1.migrationSteps(to: .version2)
    XCTAssertEqual(steps.count, 1)

    let version = try SampleModelVersion(persistentStoreURL: sourceURL)
    XCTAssertTrue(version == .version1)

    // When
    let progress = Progress(totalUnitCount: 1)
    var completionSteps = 0
    var completion = 0.0
    let token = progress.observe(\.fractionCompleted, options: [.new]) { (progress, change) in
      completion = progress.fractionCompleted
      completionSteps += 1
    }

    try CoreDataMigration.migrateStore(at: sourceURL, targetVersion: targetVersion, enableWALCheckpoint: true, progress: progress)
    let migratedContext = NSManagedObjectContext(model: targetVersion.managedObjectModel(), storeURL: sourceURL)
    let luxuryCars = try LuxuryCar.fetch(in: migratedContext)
    XCTAssertEqual(luxuryCars.count, 5)

    let cars = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Car"))
    XCTAssertTrue(cars.count >= 1)

    if #available(iOS 11, tvOS 11, watchOS 4, macOS 10.13, *) {
      cars.forEach { car in
        if car is LuxuryCar || car is SportCar {
          XCTAssertEqual(car.entity.indexes.count, 0)
        } else if car is Car {
          let index = car.entity.indexes.first
          XCTAssertNotNil(index, "There should be a compound index")
          XCTAssertEqual(index!.elements.count, 2)
        } else {
          XCTFail("Undefined")
        }
      }
    }

    try CoreDataMigration.migrateStore(from: sourceURL, to: sourceURL, targetVersion: targetVersion)

    XCTAssertEqual(completionSteps, 1)
    XCTAssertEqual(completion, 1.0)

    migratedContext._fix_sqlite_warning_when_destroying_a_store()
    token.invalidate()
  }

  // MARK: - HeavyWeight Migration

  func testMigrationFromVersion2ToVersion3() throws {
    let bundle = Bundle.tests
    let _sourceURL = bundle.url(forResource: "SampleModelV2", withExtension: "sqlite")!

    // Being the test run multiple times, we create an unique copy for every test
    let uuid = UUID().uuidString
    let sourceURL = bundle.bundleURL.appendingPathComponent("SampleModelV2_copy-\(uuid).sqlite")
    try FileManager.default.copyItem(at: _sourceURL, to: sourceURL)
    XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))

    let targetURL = sourceURL
    let version = try SampleModelVersion(persistentStoreURL: sourceURL as URL)

    XCTAssertTrue(version == .version2)

    try CoreDataMigration.migrateStore(from: sourceURL, to: targetURL, targetVersion: SampleModelVersion.version3)

    let migratedContext = NSManagedObjectContext(model: SampleModelVersion.version3.managedObjectModel(), storeURL: targetURL)
    let cars = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Car"))
    let makers = try Maker.fetch(in: migratedContext)
    XCTAssertEqual(makers.count, 11)
    XCTAssertEqual(cars.count, 125)

    cars.forEach { object in
      let owner = object.value(forKey: "owner") as? NSManagedObject
      let maker = object.value(forKey: "createdBy") as? NSManagedObject
      XCTAssertNotNil(maker)
      let name = maker!.value(forKey: "name") as! String
      maker!.setValue("--\(name)--", forKey: "name")
      let previousOwners = object.value(forKey: "previousOwners") as! Set<NSManagedObject>

      if let carOwner = owner {
        XCTAssertTrue(previousOwners.contains(carOwner))
        let previousCars = carOwner.value(forKey: "previousCars") as! Set<NSManagedObject>
        XCTAssertTrue(previousCars.contains(object))
      } else {
        XCTAssertEqual(previousOwners.count, 0)
      }
    }

    try migratedContext.save()
    XCTAssertTrue(FileManager.default.fileExists(atPath: targetURL.path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))

    migratedContext._fix_sqlite_warning_when_destroying_a_store()

    try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
  }

  func testMigrationFromVersion1ToVersion3() throws {
    let bundle = Bundle.tests
    let _sourceURL = bundle.url(forResource: "SampleModelV1", withExtension: "sqlite")!

    // Being the test run multiple times, we create an unique copy for every test
    let uuid = UUID().uuidString
    let sourceURL = bundle.bundleURL.appendingPathComponent("SampleModelV1_copy-\(uuid).sqlite")
    try FileManager.default.copyItem(at: _sourceURL, to: sourceURL)
    XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))

    let version = try SampleModelVersion(persistentStoreURL: sourceURL as URL)

    XCTAssertTrue(version == .version1)

    let targetURL = URL.temporaryDirectoryURL.appendingPathComponent("SampleModel").appendingPathExtension("sqlite")
    let progress = Progress(totalUnitCount: 1)
    var completionSteps = 0
    var completion = 0.0
    let token = progress.observe(\.fractionCompleted, options: [.new]) { (progress, change) in
      completion = progress.fractionCompleted
      completionSteps += 1
    }
    try CoreDataMigration.migrateStore(from: sourceURL, to: targetURL, targetVersion: SampleModelVersion.version3, deleteSource: true, progress: progress)

    let migratedContext = NSManagedObjectContext(model: SampleModelVersion.version3.managedObjectModel(), storeURL: targetURL)
    let makers = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Maker"))
    XCTAssertEqual(makers.count, 11)

    makers.forEach { (maker) in
      let name = maker.value(forKey: "name") as! String
      maker.setValue("--\(name)--", forKey: "name")
    }
    try migratedContext.save()

    XCTAssertEqual(completionSteps, 2)
    XCTAssertEqual(completion, 1.0)

    XCTAssertFalse(FileManager.default.fileExists(atPath: sourceURL.path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: targetURL.path))

    migratedContext._fix_sqlite_warning_when_destroying_a_store()
    token.invalidate()
  }
}

extension NSManagedObjectContext {
  convenience init(model: NSManagedObjectModel, storeURL: URL) {
    let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
    try! psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
    self.init(concurrencyType: .mainQueueConcurrencyType)
    persistentStoreCoordinator = psc
  }

  func _fix_sqlite_warning_when_destroying_a_store() {
    /// solve the warning: "BUG IN CLIENT OF libsqlite3.dylib: database integrity compromised by API violation: vnode unlinked while in use..."
    for store in persistentStoreCoordinator!.persistentStores {
      try! persistentStoreCoordinator?.remove(store)
    }
  }
}
