// CoreDataPlus

import CoreData
import XCTest

final class NSManagedObjectContextInvestigationTests: CoreDataPlusInMemoryTestCase {
  /// Investigation test: calling refreshAllObjects calls refreshObject:mergeChanges on all objects in the context.
  func testInvestigationRefreshAllObjects() throws {
    let viewContext = container.viewContext
    let car1 = Car(context: viewContext)
    car1.numberPlate = "car1"
    let car2 = Car(context: viewContext)
    car2.numberPlate = "car2"

    try viewContext.save()

    car1.numberPlate = "car1_updated"
    viewContext.refreshAllObjects()

    XCTAssertFalse(car1.isFault)
    XCTAssertTrue(car2.isFault)
    XCTAssertEqual(car1.numberPlate, "car1_updated")
  }

  /// Investigation test: KVO is fired whenever a property changes (even if the object is not saved in the context).
  func testInvestigationKVO() throws {
    let context = container.viewContext
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let sportCar1 = SportCar(context: context)
    var count = 0
    let token = sportCar1.observe(\.maker, options: .new) { (car, changes) in
      count += 1
      if count == 2 {
        expectation.fulfill()
      }
    }
    sportCar1.maker = "McLaren"
    sportCar1.model = "570GT"
    sportCar1.numberPlate = "203"
    sportCar1.maker = "McLaren 2"
    try context.save()

    waitForExpectations(timeout: 10)
    token.invalidate()
  }

  /// Investigation test: automaticallyMergesChangesFromParent behaviour
  func testInvestigationAutomaticallyMergesChangesFromParent() throws {
    // automaticallyMergesChangesFromParent = true
    do {
      let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
      let storeURL = URL.newDatabaseURL(withID: UUID())
      try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)

      let parentContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
      parentContext.persistentStoreCoordinator = psc

      let car1 = Car(context: parentContext)
      car1.maker = "FIAT"
      car1.model = "Panda"
      car1.numberPlate = UUID().uuidString
      try parentContext.save()

      let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
      childContext.parent = parentContext
      childContext.automaticallyMergesChangesFromParent = true

      let childCar = try childContext.performAndWaitResult { context -> Car in
        let car = try XCTUnwrap(try Car.existingObject(with: car1.objectID, in: context))
        XCTAssertEqual(car.maker, "FIAT")
        return car
      }

      try parentContext.performSaveAndWait { context in
        let car = try XCTUnwrap(try Car.existingObject(with: car1.objectID, in: context))
        XCTAssertEqual(car.maker, "FIAT")
        car.maker = "😀"
        XCTAssertEqual(car.maker, "😀")
      }

      // this will fail without automaticallyMergesChangesFromParent to true
      XCTAssertEqual(childCar.safeAccess({ $0.maker }), "😀")
    }

    // automaticallyMergesChangesFromParent = false
    do {
      let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
      let storeURL = URL.newDatabaseURL(withID: UUID())
      try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)

      let parentContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
      parentContext.persistentStoreCoordinator = psc

      let car1 = Car(context: parentContext)
      car1.maker = "FIAT"
      car1.model = "Panda"
      car1.numberPlate = UUID().uuidString
      try parentContext.save()

      let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
      childContext.parent = parentContext
      childContext.automaticallyMergesChangesFromParent = false

      let childCar = try childContext.performAndWaitResult { context -> Car in
        let car = try XCTUnwrap(try Car.existingObject(with: car1.objectID, in: context))
        XCTAssertEqual(car.maker, "FIAT")
        return car
      }

      try parentContext.performSaveAndWait { context in
        let car = try XCTUnwrap(try Car.existingObject(with: car1.objectID, in: context))
        XCTAssertEqual(car.maker, "FIAT")
        car.maker = "😀"
        XCTAssertEqual(car.maker, "😀")
      }

      XCTAssertEqual(childCar.safeAccess({ $0.maker }), "FIAT") // no changes
    }

    // automaticallyMergesChangesFromParent = true
    do {
      let parentContext = container.viewContext

      let car1 = Car(context: parentContext)
      car1.maker = "FIAT"
      car1.model = "Panda"
      car1.numberPlate = UUID().uuidString
      try parentContext.save()

      let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
      childContext.parent = parentContext
      childContext.automaticallyMergesChangesFromParent = true

      let childCar = try childContext.performAndWaitResult { context -> Car in
        let car = try XCTUnwrap(try Car.existingObject(with: car1.objectID, in: context))
        XCTAssertEqual(car.maker, "FIAT")
        return car
      }

      try parentContext.performSaveAndWait { context in
        let car = try XCTUnwrap(try Car.existingObject(with: car1.objectID, in: context))
        XCTAssertEqual(car.maker, "FIAT")
        car.maker = "😀"
        XCTAssertEqual(car.maker, "😀")
      }

      // this will fail without automaticallyMergesChangesFromParent to true
      XCTAssertEqual(childCar.safeAccess({ $0.maker }), "😀")
    }

    // automaticallyMergesChangesFromParent = false
    do {
      let parentContext = container.viewContext

      let car1 = Car(context: parentContext)
      car1.maker = "FIAT"
      car1.model = "Panda"
      car1.numberPlate = UUID().uuidString
      try parentContext.save()

      let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
      childContext.parent = parentContext
      childContext.automaticallyMergesChangesFromParent = false

      let childCar = try childContext.performAndWaitResult { context -> Car in
        let car = try XCTUnwrap(try Car.existingObject(with: car1.objectID, in: context))
        XCTAssertEqual(car.maker, "FIAT")
        return car
      }

      try parentContext.performSaveAndWait { context in
        let car = try XCTUnwrap(try Car.existingObject(with: car1.objectID, in: context))
        XCTAssertEqual(car.maker, "FIAT")
        car.maker = "😀"
        XCTAssertEqual(car.maker, "😀")
      }

      XCTAssertEqual(childCar.safeAccess({ $0.maker }), "FIAT") // no changes
    }
  }

  func testInvestigationStalenessInterval() throws {
    // Given
    let context = container.viewContext
    let car = Car(context: context)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = UUID().uuidString
    try context.save()

    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let result = try Car.batchUpdate(using: context, resultType: .updatedObjectIDsResultType, propertiesToUpdate: [#keyPath(Car.maker): "FCA"], includesSubentities: true, predicate: fiatPredicate)
    XCTAssertEqual(result.updates?.count, 1)

    // When, Then
    car.refresh()
    XCTAssertEqual(car.maker, "FIAT")

    // When, Then
    context.refreshAllObjects()
    XCTAssertEqual(car.maker, "FIAT")

    // When, Then
    context.stalenessInterval = 0 // issue a new fetch request instead of using the row cache
    car.refresh()
    XCTAssertEqual(car.maker, "FCA")
    context.stalenessInterval = -1 // default
  }

  func testInvestigationShouldRefreshRefetchedObjectsIsStillBroken() throws {
    // https://mjtsai.com/blog/2020/10/17/core-data-derived-attributes/
    // I've opened a feedback myself too: FB7419788

    // Given
    let readContext = container.viewContext
    let writeContext = container.newBackgroundContext()

    var writeCar: Car? = nil
    try writeContext.performAndWaitResult {
      writeCar = Car(context: writeContext)
      writeCar?.maker = "FIAT"
      writeCar?.model = "Panda"
      writeCar?.numberPlate = UUID().uuidString
      try $0.save()
    }

    // When
    var readEntity: Car? = nil
    readContext.performAndWait {
      readEntity = try! readContext.fetch(Car.newFetchRequest()).first!
      // Initially the attribute should be FIAT
      XCTAssertNotNil(readEntity)
      XCTAssertEqual(readEntity?.maker, "FIAT")
    }

    try writeContext.performAndWaitResult {
      writeCar?.maker = "FCA"
      try $0.save()
    }

    // Then
    readContext.performAndWait {
      let request = Car.newFetchRequest()
      request.shouldRefreshRefetchedObjects = true
      _ = try! readContext.fetch(request)
      // ⚠️ Now the attribute should be FCA, but it is still FIAT
      // This should be XCTAssertEqual, XCTAssertNotEqual is used only to make the test pass until
      // the problem is fixed
      XCTAssertNotEqual(readEntity?.maker, "FCA")

      readContext.refresh(readEntity!, mergeChanges: false)
      // However, manually refreshing does update it to FCA
      XCTAssertEqual(readEntity?.maker, "FCA")
    }
  }

  func testInvestigationTransientProperties() throws {
    let container = InMemoryPersistentContainer.makeNew()
    let viewContext = container.viewContext

    let car = Car(context: viewContext)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = UUID().uuidString
    car.currentDrivingSpeed = 50
    try viewContext.save()

    XCTAssertEqual(car.currentDrivingSpeed, 50)
    viewContext.refreshAllObjects()
    XCTAssertEqual(car.currentDrivingSpeed, 0)
    car.currentDrivingSpeed = 100
    XCTAssertEqual(car.currentDrivingSpeed, 100)
    viewContext.reset()
    XCTAssertEqual(car.currentDrivingSpeed, 0)
  }

  func testXXX() throws {
    let container = InMemoryPersistentContainer.makeNew()
    let viewContext = container.viewContext

    viewContext.performAndWait {
      let car = Car(context: viewContext)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = UUID().uuidString
      car.currentDrivingSpeed = 50
      try! viewContext.save()
    }

    viewContext.performAndWait {
      print(viewContext.registeredObjects)
    }
  }

  func testInvestigationTransientPropertiesBehaviorInParentChildContextRelationship() throws {
    let container = InMemoryPersistentContainer.makeNew()
    let viewContext = container.viewContext
    let childContext = viewContext.newBackgroundContext(asChildContext: true)
    var carID: NSManagedObjectID?

    let plateNumber = UUID().uuidString
    let predicate = NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), plateNumber)

    childContext.performAndWait {
      let car = Car(context: $0)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = plateNumber
      car.currentDrivingSpeed = 50
      try! $0.save()
      carID = car.objectID
      XCTAssertEqual(car.currentDrivingSpeed, 50)
      print($0.registeredObjects)
      car.currentDrivingSpeed = 20 // ⚠️ dirting the context again
    }

    childContext.performAndWait {
      print(childContext.registeredObjects)
    }

    let id = try XCTUnwrap(carID)
    let car = try XCTUnwrap(Car.object(with: id, in: viewContext))
    XCTAssertEqual(car.maker, "FIAT")
    XCTAssertEqual(car.model, "Panda")
    XCTAssertEqual(car.numberPlate, plateNumber)
    XCTAssertEqual(car.currentDrivingSpeed, 50, "The transient property value should be equal to the one saved by the child context.")

    try childContext.performAndWait {
      XCTAssertFalse(childContext.registeredObjects.isEmpty) // ⚠️ this condition is verified only because we have dirted the context after a save
      let car = try XCTUnwrap($0.object(with: id) as? Car)
      XCTAssertEqual(car.currentDrivingSpeed, 20)
      try $0.save()
    }

    XCTAssertEqual(car.currentDrivingSpeed, 20, "The transient property value should be equal to the one saved by the child context.")

    try childContext.performAndWait {
      XCTAssertTrue(childContext.registeredObjects.isEmpty) // ⚠️ it seems that after a save, the objects are freed unless the context gets dirted again
      let car = try XCTUnwrap(try Car.fetchUnique(in: $0, where: predicate))
      XCTAssertEqual(car.currentDrivingSpeed, 0)
    }

    // see testInvestigationContextRegisteredObjectBehaviorAfterSaving
  }

  func testInvestigationContextRegisteredObjectBehaviorAfterSaving() throws {
    let context = container.newBackgroundContext()

    // A context keeps registered objects until it's dirted
    try context.performAndWait {
      let person = Person(context: context)
      person.firstName = "Alessandro"
      person.lastName = "Marzoli"
      try $0.save()

      let person2 = Person(context: context)
      person2.firstName = "Andrea"
      person2.lastName = "Marzoli"
      // context dirted because person2 isn't yet saved
    }

    context.performAndWait {
      XCTAssertFalse(context.registeredObjects.isEmpty)
    }

    try context.performAndWait {
      try $0.save()
      // context is no more dirted, everything has been saved
    }

    context.performAndWait {
      XCTAssertTrue(context.registeredObjects.isEmpty)
    }

    try context.performAndWait {
      let person = Person(context: context)
      person.firstName = "Valedmaro"
      person.lastName = "Marzoli"
      try $0.save()
      // context is no more dirted, everything has been saved
    }

    context.performAndWait {
      XCTAssertTrue(context.registeredObjects.isEmpty)
    }
  }

  func testFetchLazilyUsingBatchSize() throws {
    // For this investigation you have to enable SQL logs in the test plan (-com.apple.CoreData.SQLDebug 3)
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()
    context.reset()

    // NSFetchedResultsController isn't affected
    do {
      let request = Car.fetchRequest()
      request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Car.maker), ascending: true)])
      request.fetchBatchSize = 10
      let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
      try frc.performFetch()
      // A SELECT with LIMIT 10 is executed every 10 looped cars ✅
      frc.fetchedObjects?.forEach { car in
        let _ = car as! Car
      }
    }

    // Running a Swift fetch request with a batch size doesn't work, you have to find a way to fallback to Obj-C
    // https://mjtsai.com/blog/2021/03/31/making-nsfetchrequest-fetchbatchsize-work-with-swift/
    // https://developer.apple.com/forums/thread/651325
    // This fetch will execute SELECT with LIMIT 10 as many times as needed to fetch all the cars ❌

    //let cars_batchSize_not_working = try Car.fetch(in: context) { $0.fetchBatchSize = 10 }

    // This fetch will execute SELECT with LIMIT 10 just one time ✅
    // let cars_batchLimit_working = try Car.fetch(in: context) { $0.fetchLimit = 10 }

    // cars is a _PFBatchFaultingArray proxy
    let cars = try Car.fetchLazily(in: context) { $0.fetchBatchSize = 10 }

    // This for loop will trigger a SELECT with LIMIT 10 every 10 looped cars. ✅
    cars.forEach { car in
      let _ = car as! Car
    }

    // This enumeration will trigger a SELECT with LIMIT 10 every 10 enumerated cars. ✅
    cars.enumerateObjects { car, _, _ in
      let _ = car as! Car
    }

    // firstObject will trigger only a single SELECT with LIMIT 10 ✅
    let _ = cars.firstObject as! Car
  }
}
