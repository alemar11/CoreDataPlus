// CoreDataPlus

import CoreData
import XCTest
import os.lock

@testable import CoreDataPlus

final class Migrations_Tests: BaseTestCase {
  // MARK: - LightWeight Migration

  func test_MigrationFromNotExistingPersistentStore() {
    let url = URL(fileURLWithPath: "/path/to/nothing.sqlite")
    let sourceDescription = NSPersistentStoreDescription(url: url)
    let destinationDescription = NSPersistentStoreDescription(url: url)
    let migrator = Migrator<SampleModelVersion>(
      sourceStoreDescription: sourceDescription,
      destinationStoreDescription: destinationDescription,
      targetVersion: .version3)

    XCTAssertThrowsError(try migrator.migrate(enableWALCheckpoint: true), "The store shouldn't exist.")
  }

  func test_MigrationEdgeCases() throws {
    let name = "SampleModel-\(UUID())"
    let container = NSPersistentContainer(name: name, managedObjectModel: model1)
    let context = container.viewContext

    let expectation1 = expectation(description: "\(#function)\(#line)")

    container.loadPersistentStores { (store, error) in
      XCTAssertNil(error)
      expectation1.fulfill()
    }
    wait(for: [expectation1], timeout: 5)

    context.fillWithSampleData()
    try context.save()
    context.reset()

    let sourceURL = try XCTUnwrap(container.persistentStoreCoordinator.persistentStores.first?.url)

    let targetVersion = SampleModelVersion.version2
    let steps = SampleModelVersion.version1.migrationSteps(to: .version2)
    XCTAssertEqual(steps.count, 1)

    let version = try SampleModelVersion(persistentStoreURL: sourceURL)
    XCTAssertTrue(version == .version1)

    // When

    // ⚠️ if the store is referenced, enabling the WAL checkpoint will block the migration
    // you can solve this removing the store from the container from the NSPersistentStoreCoordinator
    let enableWALCheckpoint = false
    let sourceDescription = NSPersistentStoreDescription(url: sourceURL)
    let destinationDescription = NSPersistentStoreDescription(url: sourceURL)
    let migrator = Migrator<SampleModelVersion>(
      sourceStoreDescription: sourceDescription,
      destinationStoreDescription: destinationDescription,
      targetVersion: targetVersion)
    try migrator.migrate(enableWALCheckpoint: enableWALCheckpoint)

    // ⚠️ migration should be done before loading the NSPersistentContainer instance or you need to create a new one after the migration
    let migratedContainer = NSPersistentContainer(name: name, 
                                                  managedObjectModel: targetVersion.managedObjectModel())

    let expectation2 = expectation(description: "\(#function)\(#line)")
    migratedContainer.loadPersistentStores { (store, error) in
      XCTAssertNil(error)
      expectation2.fulfill()
    }
    wait(for: [expectation2], timeout: 5)

    let context2 = migratedContainer.viewContext
    let luxuryCars = try context2.fetch(NSFetchRequest<NSManagedObject>(entityName: "LuxuryCar"))
    for car in luxuryCars {
      XCTAssertNotNil(car.value(forKey: "isLimitedEdition"))
    }
  }

  func test_IfMigrationIsNeeded() throws {
    let bundle = Bundle.tests
    let sourceURLV1 = try XCTUnwrap(bundle.url(forResource: "SampleModel_V1", withExtension: "sqlite"))
    let sourceURLV2 = try XCTUnwrap(bundle.url(forResource: "SampleModel_V2", withExtension: "sqlite"))
    let migrationNeededFromV1toV1 = try CoreDataPlus.isMigrationNecessary(
      for: sourceURLV1, to: SampleModelVersion.version1)
    XCTAssertFalse(migrationNeededFromV1toV1)
    let migrationNeededFromV1toV2 = try CoreDataPlus.isMigrationNecessary(
      for: sourceURLV1, to: SampleModelVersion.version2)
    XCTAssertTrue(migrationNeededFromV1toV2)
    let migrationNeededFromV1toV3 = try CoreDataPlus.isMigrationNecessary(
      for: sourceURLV1, to: SampleModelVersion.version3)
    XCTAssertTrue(migrationNeededFromV1toV3)
    let migrationNeededFromV2toV1 = try CoreDataPlus.isMigrationNecessary(
      for: sourceURLV2, to: SampleModelVersion.version1)
    XCTAssertFalse(migrationNeededFromV2toV1)
  }

  func test_MigrationFromV1toV1() throws {
    let sourceURL = try Self.createSQLiteSample1ForV1()

    let sourceDescription = NSPersistentStoreDescription(url: sourceURL)
    let destinationDescription = NSPersistentStoreDescription(url: sourceURL)
    let migrator = Migrator<SampleModelVersion>(
      sourceStoreDescription: sourceDescription,
      destinationStoreDescription: destinationDescription,
      targetVersion: .version1)
    try migrator.migrate(enableWALCheckpoint: true)
    
    try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
  }

  func test_MigrationFromV1ToV2() throws {
    let sourceURL = try Self.createSQLiteSample1ForV1()

    let targetVersion = SampleModelVersion.version2
    let steps = SampleModelVersion.version1.migrationSteps(to: .version2)
    XCTAssertEqual(steps.count, 1)

    let version = try SampleModelVersion(persistentStoreURL: sourceURL)
    XCTAssertTrue(version == .version1)

    // When
    let targetDescription = NSPersistentStoreDescription(url: sourceURL)
    let migrator = Migrator<SampleModelVersion>(targetStoreDescription: targetDescription,
                                                targetVersion: targetVersion)
    migrator.enableLog = true
    migrator.enableLog = false

    let completion = OSAllocatedUnfairLock(initialState: 0.0)
    let token = migrator.progress.observe(\.fractionCompleted, options: [.new]) { (progress, change) in
      completion.withLock { $0 = progress.fractionCompleted }
    }

    try migrator.migrate(enableWALCheckpoint: true)

    let migratedContext = NSManagedObjectContext(model: targetVersion.managedObjectModel(),
                                                 storeURL: sourceURL)
    let luxuryCars = try LuxuryCar.fetchObjects(in: migratedContext)
    XCTAssertEqual(luxuryCars.count, 5)

    let cars = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Car"))
    XCTAssertTrue(cars.count >= 1)

    for car in cars {
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

    XCTAssertEqual(completion.withLock { $0 }, 1.0)

    migratedContext._fix_sqlite_warning_when_destroying_a_store()
    token.invalidate()
    try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
  }

  func test_MigrationFromV1ToV2UsingCustomMigratorProvider() throws {
    let sourceURL = try Self.createSQLiteSample1ForV1()
    
    let targetVersion = SampleModelVersion.version2
    let steps = SampleModelVersion.version1.migrationSteps(to: .version2)
    XCTAssertEqual(steps.count, 1)

    let version = try SampleModelVersion(persistentStoreURL: sourceURL)
    XCTAssertTrue(version == .version1)

    let sourceDescription = NSPersistentStoreDescription(url: sourceURL)
    let destinationDescription = NSPersistentStoreDescription(url: sourceURL)

    let migrator = Migrator<SampleModelVersion>(
      sourceStoreDescription: sourceDescription,
      destinationStoreDescription: destinationDescription,
      targetVersion: targetVersion)

    // When
    let completion = OSAllocatedUnfairLock(initialState: 0.0)
    let token = migrator.progress.observe(\.fractionCompleted, options: [.new]) { (progress, change) in
      completion.withLock { $0 = progress.fractionCompleted }
    }

    try migrator.migrate(enableWALCheckpoint: true)

    let migratedContext = NSManagedObjectContext(model: targetVersion.managedObjectModel(), storeURL: sourceURL)
    let luxuryCars = try LuxuryCar.fetchObjects(in: migratedContext)
    XCTAssertEqual(luxuryCars.count, 5)

    let cars = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Car"))
    XCTAssertTrue(cars.count >= 1)

    for car in cars {
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

    XCTAssertEqual(completion.withLock { $0 }, 1.0)

    migratedContext._fix_sqlite_warning_when_destroying_a_store()
    token.invalidate()
    try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
  }

  // MARK: - HeavyWeight Migration

  func test_MigrationFromV2ToV3() throws {
    let sourceURL = try Self.createSQLiteSample1ForV2()

    let targetURL = sourceURL
    let version = try SampleModelVersion(persistentStoreURL: sourceURL as URL)

    XCTAssertTrue(version == .version2)

    let sourceDescription = NSPersistentStoreDescription(url: sourceURL)
    let destinationDescription = NSPersistentStoreDescription(url: sourceURL)
    let migrator = Migrator<SampleModelVersion>(sourceStoreDescription: sourceDescription,
                                                destinationStoreDescription: destinationDescription,
                                                targetVersion: .version3)
    try migrator.migrate(enableWALCheckpoint: true)

    let migratedContext = NSManagedObjectContext(model: SampleModelVersion.version3.managedObjectModel(),
                                                 storeURL: targetURL)
    let cars = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Car"))
    let makers = try Maker.fetchObjects(in: migratedContext)
    XCTAssertEqual(makers.count, 10)
    XCTAssertEqual(cars.count, 125)

    for object in cars {
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

  func test_CancelMigrationFromV2ToV3() throws {
    // Given
    let sourceURL = try Self.createSQLiteSample1ForV2()
    let sourceDescription = NSPersistentStoreDescription(url: sourceURL)
    let destinationDescription = NSPersistentStoreDescription(url: sourceURL)
    let migrator = Migrator<SampleModelVersion>(sourceStoreDescription: sourceDescription,
                                                destinationStoreDescription: destinationDescription,
                                                targetVersion: .version3)
    migrator.enableLog = true
    // When
    migrator.progress.cancel()
    // Then
    XCTAssertThrowsError(
      try migrator.migrate(enableWALCheckpoint: true),
      "The migrator should throw an error because the progress has cancelled the migration steps"
    ) { error in
      let nserror = error as NSError
      XCTAssertEqual(nserror.domain, NSError.migrationCancelled.domain)
      XCTAssertEqual(nserror.code, NSError.migrationCancelled.code)
    }

    // When
    let migrator2 = Migrator<SampleModelVersion>(
      sourceStoreDescription: sourceDescription,
      destinationStoreDescription: destinationDescription,
      targetVersion: .version3)
    migrator2.enableLog = true
    XCTAssertNoThrow(
      try migrator2.migrate(enableWALCheckpoint: true),
      "A new migrator should handle the migration phase without any errors.")

    try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
  }

  func test_MigrationFromV1ToV3() throws {
    let sourceURL = try Self.createSQLiteSample1ForV1()
    let version = try SampleModelVersion(persistentStoreURL: sourceURL as URL)
    XCTAssertTrue(version == .version1)
    
    XCTAssertTrue(SampleModelVersion.version1.isLightWeightMigrationPossibleToNextModelVersion())
    XCTAssertTrue(SampleModelVersion.version2.isLightWeightMigrationPossibleToNextModelVersion())
    XCTAssertFalse(SampleModelVersion.version3.isLightWeightMigrationPossibleToNextModelVersion())

    let targetURL = URL.temporaryDirectory.appendingPathComponent("SampleModel").appendingPathExtension("sqlite")
    let sourceDescription = NSPersistentStoreDescription(url: sourceURL)
    let destinationDescription = NSPersistentStoreDescription(url: targetURL)
    let migrator = Migrator<SampleModelVersion>(sourceStoreDescription: sourceDescription,
                                                destinationStoreDescription: destinationDescription,
                                                targetVersion: .version3)
    migrator.enableLog = true
    let completion = OSAllocatedUnfairLock(initialState: 0.0)
    let token = migrator.progress.observe(\.fractionCompleted, options: [.new]) { (progress, change) in
      //print(progress.fractionCompleted)
      completion.withLock { $0 = progress.fractionCompleted }
    }

    try migrator.migrate(enableWALCheckpoint: true)
    let migratedContext = NSManagedObjectContext(model: SampleModelVersion.version3.managedObjectModel(),
                                                 storeURL: targetURL)
    let makers = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Maker"))
    XCTAssertEqual(makers.count, 10)

    for maker in makers {
      let name = maker.value(forKey: "name") as! String
      maker.setValue("--\(name)--", forKey: "name")
    }
    try migratedContext.save()

    XCTAssertEqual(completion.withLock { $0 }, 1.0)
    XCTAssertFalse(FileManager.default.fileExists(atPath: sourceURL.path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: targetURL.path))

    migratedContext._fix_sqlite_warning_when_destroying_a_store()
    token.invalidate()
    try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
  }

  func test_InvestigationProgress() {
    let expectationChildCancelled = expectation(description: "Child Progress cancelled")
    let expectationGrandChildCancelled = expectation(description: "Grandchild Progress cancelled")
    let progress = Progress(totalUnitCount: 1)
    progress.cancel()
    // if the parent is already cancelled, children and grandchildren will inherit the cancellation
    let child = Progress(totalUnitCount: 1, parent: progress, pendingUnitCount: 1)
    child.cancellationHandler = { expectationChildCancelled.fulfill() }
    let grandChild = Progress(totalUnitCount: 1, parent: child, pendingUnitCount: 1)
    grandChild.cancellationHandler = { expectationGrandChildCancelled.fulfill() }
    XCTAssertTrue(child.isCancelled)
    XCTAssertTrue(grandChild.isCancelled)
    wait(for: [expectationChildCancelled, expectationGrandChildCancelled], timeout: 2)
  }
}

// MARK: - Sample creation

extension Migrations_Tests {
  static func createSQLiteSample1ForV1() throws -> URL {
    let bundle = Bundle.tests
    // 125 cars, 5 sport cars
    let _sourceURL = try XCTUnwrap(bundle.url(forResource: "SampleModel_V1", withExtension: "sqlite"))
    
    // Being the test run multiple times, we create an unique copy for every test
    let uuid = UUID().uuidString
    let sourceURL = bundle.bundleURL.appendingPathComponent("SampleModel_V1_copy-\(uuid).sqlite")
    try FileManager.default.copyItem(at: _sourceURL, to: sourceURL)
    XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
    return sourceURL
  }
  
  static func createSQLiteSample1ForV2() throws -> URL {
    let bundle = Bundle.tests
    // 125 cars, 5 sport cars
    let _sourceURL = try XCTUnwrap(bundle.url(forResource: "SampleModel_V2", withExtension: "sqlite"))
    
    // Being the test run multiple times, we create an unique copy for every test
    let uuid = UUID().uuidString
    let sourceURL = bundle.bundleURL.appendingPathComponent("SampleModel_V2_copy-\(uuid).sqlite")
    try FileManager.default.copyItem(at: _sourceURL, to: sourceURL)
    XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
    return sourceURL
  }
  
  /// Creates a .sqlite with some data for the initial model (version 1)
  static func createSampleVersion1(completion: @escaping (Result<URL, Error>) -> Void) {
    let containerSQLite = NSPersistentContainer(name: "SampleModel-\(UUID())", managedObjectModel: model1)
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
        completion(.success(sourceURL))
      } catch {
        completion(.failure(error))
      }
    }
  }
}
