// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

// TODO: to create a sqlite for migrations with disabled NSPersistentHistoryTrackingKey

final class MigrationsTests: BaseTestCase {
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
        completion(.success(sourceURL))
      } catch {
        completion(.failure(error))
      }
    }
  }

  func testMigrationFromNotExistingPersistentStore() {
    let url = URL(fileURLWithPath: "/path/to/nothing.sqlite")
    XCTAssertThrowsError(try Migration.migrateStore(at: url, targetVersion: SampleModelVersion.version2),
                         "The store shouldn't exist.")
  }

  func testMigrationEdgeCases() throws {
    let name = "SampleModel-\(UUID())"
    let container = NSPersistentContainer(name: name, managedObjectModel: model)
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
    let progress = Progress(totalUnitCount: 1)

    // ⚠️ if the store is referenced, enabling the WAL checkpoint will block the migration
    // you can solve this removing the store from the container from the NSPersistentStoreCoordinator
    let enableWALCheckpoint = false
    try Migration.migrateStore(at: sourceURL, targetVersion: targetVersion, enableWALCheckpoint: enableWALCheckpoint, progress: progress)

    // ⚠️ migration should be done before loading the NSPersistentContainer instance or you need to create a new one after the migration
    let migratedContainer = NSPersistentContainer(name: name, managedObjectModel: targetVersion.managedObjectModel())

    let expectation2 = expectation(description: "\(#function)\(#line)")
    migratedContainer.loadPersistentStores { (store, error) in
      XCTAssertNil(error)
      expectation2.fulfill()
    }
    wait(for: [expectation2], timeout: 5)

    let context2 = migratedContainer.viewContext
    let luxuryCars = try context2.fetch(NSFetchRequest<NSManagedObject>(entityName: "LuxuryCar"))
    luxuryCars.forEach { XCTAssertNotNil($0.value(forKey: "isLimitedEdition")) }
  }

  func testIfMigrationIsNeeded() throws {
    let bundle = Bundle.tests
    let sourceURLV1 = try XCTUnwrap(bundle.url(forResource: "SampleModelV1", withExtension: "sqlite"))
    let sourceURLV2 = try XCTUnwrap(bundle.url(forResource: "SampleModelV2", withExtension: "sqlite"))
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
    let _sourceURL = try XCTUnwrap(bundle.url(forResource: "SampleModelV1", withExtension: "sqlite"))  // 125 cars, 5 sport cars

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

    try Migration.migrateStore(at: sourceURL, targetVersion: targetVersion, enableWALCheckpoint: true, progress: progress)
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

    try Migration.migrateStore(from: sourceURL, to: sourceURL, targetVersion: targetVersion)

    XCTAssertEqual(completionSteps, 1)
    XCTAssertEqual(completion, 1.0)

    migratedContext._fix_sqlite_warning_when_destroying_a_store()
    token.invalidate()
  }

  func testMigrationFromVersion1ToVersion2__() throws {
    let bundle = Bundle.tests
    let _sourceURL = try XCTUnwrap(bundle.url(forResource: "SampleModelV1", withExtension: "sqlite"))  // 125 cars, 5 sport cars

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

    let sourceDescription = NSPersistentStoreDescription(url: sourceURL)
    let destinationDescription = NSPersistentStoreDescription(url: sourceURL)

    let migrator = Migrator(sourceStoreDescription: sourceDescription, destinationStoreDescription: destinationDescription)

    // When
    var completion = 0.0
    let token = migrator.progress.observe(\.fractionCompleted, options: [.new]) { (progress, change) in
      completion = progress.fractionCompleted
    }

    try migrator.migrate(to: targetVersion, deleteSource: false, enableWALCheckpoint: true)

    //try Migration.migrateStore(at: sourceURL, targetVersion: targetVersion, enableWALCheckpoint: true, progress: progress)
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

    try Migration.migrateStore(from: sourceURL, to: sourceURL, targetVersion: targetVersion)

    XCTAssertEqual(completion, 1.0)

    migratedContext._fix_sqlite_warning_when_destroying_a_store()
    token.invalidate()
  }

  // MARK: - HeavyWeight Migration

  func testMigrationFromVersion2ToVersion3() throws {
    let bundle = Bundle.tests
    let _sourceURL = try XCTUnwrap(bundle.url(forResource: "SampleModelV2", withExtension: "sqlite"))

    // Being the test run multiple times, we create an unique copy for every test
    let uuid = UUID().uuidString
    let sourceURL = bundle.bundleURL.appendingPathComponent("SampleModelV2_copy-\(uuid).sqlite")
    try FileManager.default.copyItem(at: _sourceURL, to: sourceURL)
    XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))

    let targetURL = sourceURL
    let version = try SampleModelVersion(persistentStoreURL: sourceURL as URL)

    XCTAssertTrue(version == .version2)

    try Migration.migrateStore(from: sourceURL, to: targetURL, targetVersion: SampleModelVersion.version3)

    let migratedContext = NSManagedObjectContext(model: SampleModelVersion.version3.managedObjectModel(), storeURL: targetURL)
    let cars = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Car"))
    let makers = try Maker.fetch(in: migratedContext)
    XCTAssertEqual(makers.count, 10)
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
    let _sourceURL = try XCTUnwrap(bundle.url(forResource: "SampleModelV1", withExtension: "sqlite"))

    // Being the test run multiple times, we create an unique copy for every test
    let uuid = UUID().uuidString
    let sourceURL = bundle.bundleURL.appendingPathComponent("SampleModelV1_copy-\(uuid).sqlite")
    try FileManager.default.copyItem(at: _sourceURL, to: sourceURL)
    XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))

    let version = try SampleModelVersion(persistentStoreURL: sourceURL as URL)

    XCTAssertTrue(version == .version1)

    let targetURL = URL.temporaryDirectoryURL.appendingPathComponent("SampleModel").appendingPathExtension("sqlite")
    let progress = Progress(totalUnitCount: 1)
    var completion = 0.0
    let token = progress.observe(\.fractionCompleted, options: [.new]) { (progress, change) in
      print(progress.fractionCompleted)
      completion = progress.fractionCompleted
    }
    try Migration.migrateStore(from: sourceURL, to: targetURL, targetVersion: SampleModelVersion.version3, deleteSource: true, progress: progress)

    let migratedContext = NSManagedObjectContext(model: SampleModelVersion.version3.managedObjectModel(), storeURL: targetURL)
    let makers = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Maker"))
    XCTAssertEqual(makers.count, 10)

    makers.forEach { (maker) in
      let name = maker.value(forKey: "name") as! String
      maker.setValue("--\(name)--", forKey: "name")
    }
    try migratedContext.save()

    XCTAssertEqual(completion, 1.0)

    XCTAssertFalse(FileManager.default.fileExists(atPath: sourceURL.path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: targetURL.path))

    migratedContext._fix_sqlite_warning_when_destroying_a_store()
    token.invalidate()
  }

  func testInvestigationProgress() {
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

  func testFakeProgressReportingWorker() throws {
    let workExpectation = self.expectation(description: "Actual work is completed.")
    let worker = FakeProgressReportingWorker(estimatedTime: 2, interval: 0.01, work: { isAlreadyCancelled in
      XCTAssertFalse(isAlreadyCancelled)
      sleep(2)
      workExpectation.fulfill()
    }, cancellation: {
      XCTFail("No cancel commands have been sent.")
    })

    let token = worker.progress.observe(\.fractionCompleted, options: [.new]) { (progress, change) in
      print(progress.fractionCompleted)
    }

    let progressExpectation = XCTKVOExpectation(keyPath: #keyPath(Progress.isFinished), object: worker.progress, expectedValue: true, options: [.new])

    try worker.run()

    wait(for: [workExpectation, progressExpectation], timeout: 10, enforceOrder: true)
    token.invalidate()
  }

  func testFakeProgressReportingWorkerCancellation() throws {
    let workExpectation = self.expectation(description: "Actual work is completed.")
    let cancellationExpectation = self.expectation(description: "Actual work is completed.")

    let worker = FakeProgressReportingWorker(estimatedTime: 2, work: { isAlreadyCancelled in
      XCTAssertTrue(isAlreadyCancelled)
      sleep(2)
      workExpectation.fulfill()
    }, cancellation: {
      cancellationExpectation.fulfill()
    })

    let token = worker.progress.observe(\.fractionCompleted, options: [.new]) { (progress, change) in
      print(progress.fractionCompleted)
    }

    let progressCancellationExpectation = XCTKVOExpectation(keyPath: #keyPath(Progress.isCancelled),
                                                            object: worker.progress,
                                                            expectedValue: true,
                                                            options: [.new])
    worker.progress.cancel()
    try worker.run()

    wait(for: [progressCancellationExpectation, cancellationExpectation, workExpectation], timeout: 10, enforceOrder: true)
    token.invalidate()
  }
}
