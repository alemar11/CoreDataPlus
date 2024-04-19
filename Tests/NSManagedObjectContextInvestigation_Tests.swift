// CoreDataPlus

import CoreData
import XCTest
import os.lock

final class NSManagedObjectContextInvestigation_Tests: InMemoryTestCase {
  /// Investigation test: calling refreshAllObjects calls refreshObject:mergeChanges on all objects in the context.
  func test_InvestigationRefreshAllObjects() throws {
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
  func test_InvestigationKVO() throws {
    let context = container.viewContext
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let sportCar1 = SportCar(context: context)
    let count = OSAllocatedUnfairLock(initialState: 0)
    let token = sportCar1.observe(\.maker, options: .new) { (car, changes) in
      let shouldFulfill = count.withLock {
        $0 += 1
        return $0 == 2
      }
      if shouldFulfill {
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
  func test_InvestigationAutomaticallyMergesChangesFromParent() throws {
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

      let childCar = try childContext.performAndWait { _ -> Car in
        let car = try XCTUnwrap(try Car.existingObject(with: car1.objectID, in: childContext))
        XCTAssertEqual(car.maker, "FIAT")
        return car
      }

      try parentContext.performAndWait { _ in
        let car = try XCTUnwrap(try Car.existingObject(with: car1.objectID, in: parentContext))
        XCTAssertEqual(car.maker, "FIAT")
        car.maker = "😀"
        XCTAssertEqual(car.maker, "😀")
        try parentContext.save()
      }

      // this will fail without automaticallyMergesChangesFromParent to true
      childContext.performAndWait {
        XCTAssertEqual(childCar.maker, "😀")
      }
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

      let childCar = try childContext.performAndWait { context -> Car in
        let car = try XCTUnwrap(try Car.existingObject(with: car1.objectID, in: context))
        XCTAssertEqual(car.maker, "FIAT")
        return car
      }

      try parentContext.performAndWait { _ in
        let car = try XCTUnwrap(try Car.existingObject(with: car1.objectID, in: parentContext))
        XCTAssertEqual(car.maker, "FIAT")
        car.maker = "😀"
        XCTAssertEqual(car.maker, "😀")
        try parentContext.save()
      }

      childContext.performAndWait {
        XCTAssertEqual(childCar.maker, "FIAT") // no changes
      }
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

      let childCar = try childContext.performAndWait { _ -> Car in
        let car = try XCTUnwrap(try Car.existingObject(with: car1.objectID, in: childContext))
        XCTAssertEqual(car.maker, "FIAT")
        return car
      }

      try parentContext.performAndWait { _ in
        let car = try XCTUnwrap(try Car.existingObject(with: car1.objectID, in: parentContext))
        XCTAssertEqual(car.maker, "FIAT")
        car.maker = "😀"
        XCTAssertEqual(car.maker, "😀")
        try parentContext.save()
      }

      // this will fail without automaticallyMergesChangesFromParent to true
      childContext.performAndWait {
        XCTAssertEqual(childCar.maker, "😀")
      }
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

      let childCar = try childContext.performAndWait { _ -> Car in
        let car = try XCTUnwrap(try Car.existingObject(with: car1.objectID, in: childContext))
        XCTAssertEqual(car.maker, "FIAT")
        return car
      }

      try parentContext.performAndWait { _ in
        let car = try XCTUnwrap(try Car.existingObject(with: car1.objectID, in: parentContext))
        XCTAssertEqual(car.maker, "FIAT")
        car.maker = "😀"
        XCTAssertEqual(car.maker, "😀")
        try parentContext.save()
      }

      childContext.performAndWait {
        XCTAssertEqual(childCar.maker, "FIAT") // no changes
      }
    }
  }

  func test_InvestigationStalenessInterval() throws {
    // Given
    let context = container.viewContext
    let car = Car(context: context)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = UUID().uuidString
    try context.save()

    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let result = try Car.batchUpdate(using: context) {
      $0.resultType = .updatedObjectIDsResultType
      $0.propertiesToUpdate = [#keyPath(Car.maker): "FCA"]
      $0.includesSubentities = true
      $0.predicate = fiatPredicate
    }
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
    // The default is a negative value, which represents infinite staleness allowed. 0.0 represents “no staleness acceptable”.
  }

  func test_InvestigationShouldRefreshRefetchedObjectsIsStillBroken() throws {
    // https://mjtsai.com/blog/2019/10/17/
    // I've opened a feedback myself too: FB7419788

    // Given
    let readContext = container.viewContext
    let writeContext = container.newBackgroundContext()

    var writeCar: Car? = nil
    try writeContext.performAndWait {
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

    try writeContext.performAndWait {
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

  func test_InvestigationTransientProperties() throws {
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

  func test_InvestigationTransientPropertiesBehaviorInParentChildContextRelationship() throws {
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
      //print($0.registeredObjects)
      car.currentDrivingSpeed = 20 // ⚠️ dirting the context again
    }

    childContext.performAndWait {
      //print(childContext.registeredObjects)
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
      let car = try XCTUnwrap(try Car.fetchUniqueObject(in: $0, where: predicate))
      XCTAssertEqual(car.currentDrivingSpeed, 0)
    }

    // see testInvestigationContextRegisteredObjectBehaviorAfterSaving
  }

  func test_InvestigationContextRegisteredObjectBehaviorAfterSaving() throws {
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

  // MARK: - Batch Size investigations

  func test_FetchAsNSArrayUsingBatchSize() throws {
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

    // This fetch will execute SELECT with LIMIT 10 just one time ✅
    // let cars_batchLimit_working = try Car.fetch(in: context) { $0.fetchLimit = 10 }

    // This fetch will execute SELECT with LIMIT 10 as many times as needed to fetch all the cars ❌
    //let cars_batchSize_not_working = try Car.fetch(in: context) { $0.fetchBatchSize = 10 }

    // cars is a _PFBatchFaultingArray proxy
    let cars = try Car.fetchNSArray(in: context) { $0.fetchBatchSize = 10 }

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

  func test_FetchAsDictionaryUsingBatchSize() throws {
    // For this investigation you have to enable SQL logs in the test plan (-com.apple.CoreData.SQLDebug 3)
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()
    context.reset()
    let request = Car.fetchRequest()
    request.returnsObjectsAsFaults = false
    request.propertiesToFetch = [#keyPath(Car.maker), #keyPath(Car.objectID)]
    request.resultType = .dictionaryResultType
    request.fetchBatchSize = 10
    // fetchBatchSize requires to add "objectID" in the "propertiesToFetch" otherwise it won't work

    // triggers SELECT t0.Z_ENT, t0.Z_PK FROM ZCAR t0 ❌
    // and 13 queries of: SELECT t0.ZMAKER, t0.Z_ENT, t0.Z_PK FROM ZCAR t0 WHERE  t0.Z_PK IN (SELECT * FROM _Z_intarray0)   LIMIT 10
    // let results__batchSize_not_working = try context.fetch(request) as! [Dictionary<String,Any>] // triggers 13 SELECT with LIMIT 10 ❌

    //    // triggers only SELECT t0.Z_ENT, t0.Z_PK FROM ZCAR t0
    let results_batchSize_working = try context.fetch(request) as! [NSDictionary]

    //    // triggers only a single SELECT with LIMIT 10 ✅
    //    // SELECT t0.ZMAKER, t0.Z_ENT, t0.Z_PK FROM ZCAR t0 WHERE  t0.Z_PK IN (SELECT * FROM _Z_intarray0) LIMIT 10
    XCTAssertNotNil(results_batchSize_working.first)
  }

  // MARK: - UndoManager

  // To enable undo support on iOS you have to set the context's NSUndoManager.
  // NOTE: https://forums.developer.apple.com/thread/74038 it appears the undoManager is nil by default on macos too.
  // https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext
  // https://stackoverflow.com/questions/10745027/undo-core-data-managed-object
  //
  //   undo: sends an undo message to the NSUndoManager
  //   redo: sends a redo message to the NSUndoManager
  //   rollback: sends undo messages to the NSUndoManager until there is nothing left to undo
  //
  //   undo vs rollback
  //   undo reverses a single change, rollback reverses all changes up to the previous save.

  /**
   From the Apple Core Data Programming Guid (old book)

   The Core Data framework provides automatic support for undo and redo. Undo management even extends to transient properties (properties that are not saved to persistent store, but are specified in the managed object model).
   Managed objects are associated with a managed object context. Each managed object context maintains an undo manager. The context uses key-value observing to keep track of modifications to its registered objects. You can make whatever changes you want to a managed object’s properties using normal accessor methods, key-value coding, or through any custom key-value-observing compliant methods you define for custom classes, and the context registers appropriate events with its undo manager.

   To undo an operation, you simply send the context an undo message and to redo it send the context a redo message. You can also roll back all changes made since the last save operation using rollback (this also clears the undo stack) and reset a context to its base state using reset.
   You also can use other standard undo manager functionality, such grouping undo events. Core Data, though, queues up the undo registrations and adds them in a batch (this allows the framework to coalesce changes, negate contradictory changes, and perform various other operations that work better with hindsight than immediacy). If you use methods other than **beginUndoGrouping** and **endUndoGrouping**, to ensure that any queued operations are properly flushed you must first therefore send the managed object context a **processPendingChanges message**.

   For example, in some situations you want to alter—or, specifically, disable—undo behavior. This may be useful if you want to create a default set of objects when a new document is created (but want to ensure that the document is not shown as being dirty when it is displayed), or if you need to merge new state from another thread or process. In general, to perform operations without undo registration, you send an undo manager a disableUndoRegistration message, make the changes, and then send the undo manager an enableUndoRegistration message. Before each, you send the context a processPendingChanges message, as illustrated in the following code fragment:

   NSManagedObjectContext *moc = ...;
   [moc processPendingChanges];  // flush operations for which you want undos
   [[moc undoManager] disableUndoRegistration];
   // make changes for which undo operations are not to be recorded
   [moc processPendingChanges];  // flush operations for which you do not want undos
   [[moc undoManager] enableUndoRegistration];
   **/

  func test_InvestigationUndoManager() throws {
    do {
      let context = container.newBackgroundContext()
      context.undoManager = UndoManager() // undoManager is needed to use the undo/redo methods
      context.performAndWait { _ in
        context.fillWithSampleData()
        context.undo()
        XCTAssertTrue(context.insertedObjects.isEmpty)
        context.redo()
        XCTAssertFalse(context.insertedObjects.isEmpty)
        // rollback resets all the pending changes (and the undo stack too).
        context.rollback()
        XCTAssertTrue(context.insertedObjects.isEmpty)
        context.redo()
        XCTAssertTrue(context.insertedObjects.isEmpty)
      }
    }
    do {
      // Without setting a UndoManager, the "undo" method won't work but the "rollback" will.
      let context = container.newBackgroundContext()
      context.performAndWait { _ in
        context.fillWithSampleData()
        context.undo()
        XCTAssertFalse(context.insertedObjects.isEmpty)
        // rollback works without an undomanager and clears the undo stack
        context.rollback()
        XCTAssertTrue(context.insertedObjects.isEmpty)
      }
    }
    do {
      let context = container.newBackgroundContext()
      context.performAndWait { _ in
        context.undoManager = UndoManager()
        // stuff...
        context.processPendingChanges() // flush operations for which you want undos
        context.undoManager!.disableUndoRegistration()
        // make changes for which undo operations are not to be recorded
        let car = Car(context: context)
        car.numberPlate = "1"
        car.maker = "fake-maker"
        car.model = "fake-model"
        context.processPendingChanges() // flush operations for which you do not want undos
        context.undoManager!.enableUndoRegistration()
        context.undo()
        XCTAssertFalse(context.insertedObjects.isEmpty)
      }
    }
  }
}
