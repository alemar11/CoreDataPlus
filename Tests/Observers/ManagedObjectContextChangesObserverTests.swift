// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

final class ManagedObjectContextChangesObserverTests: CoreDataPlusInMemoryTestCase {
  /// To issue a NSManagedObjectContextObjectsDidChangeNotification from a background thread, call the NSManagedObjectContext’s processPendingChanges method.
  /// http://openradar.appspot.com/14310964
  /// NSManagedObjectContext’s `perform` method encapsulates an autorelease pool and a call to processPendingChanges, `performAndWait` does not.

  /**
   Track Changes in Other Threads Using Notifications

   Changes you make to a managed object in one context are not propagated to a corresponding managed object in a different context unless you either refetch or re-fault the object.
   If you need to track in one thread changes made to managed objects in another thread, there are two approaches you can take, both involving notifications.
   For the purposes of explanation, consider two threads, “A” and “B”, and suppose you want to propagate changes from B to A.
   Typically, on thread A you register for the managed object context save notification, NSManagedObjectContextDidSaveNotification.
   When you receive the notification, its user info dictionary contains arrays with the managed objects that were inserted, deleted, and updated on thread B.
   Because the managed objects are associated with a different thread, however, you should not access them directly.
   Instead, you pass the notification as an argument to mergeChangesFromContextDidSaveNotification: (which you send to the context on thread A). Using this method, the context is able to safely merge the changes.

   If you need finer-grained control, you can use the managed object context change notification, NSManagedObjectContextObjectsDidChangeNotification—the notification’s user info dictionary again contains arrays with the managed objects that were inserted, deleted, and updated. In this scenario, however, you register for the notification on thread B.
   When you receive the notification, the managed objects in the user info dictionary are associated with the same thread, so you can access their object IDs.
   You pass the object IDs to thread A by sending a suitable message to an object on thread A. Upon receipt, on thread A you can refetch the corresponding managed objects.

   Note that the change notification is sent in NSManagedObjectContext’s processPendingChanges method.
   The main thread is tied into the event cycle for the application so that processPendingChanges is invoked automatically after every user event on contexts owned by the main thread.
   This is not the case for background threads—when the method is invoked depends on both the platform and the release version, so you should not rely on particular timing.
   ▶️ If the secondary context is not on the main thread, you should call processPendingChanges yourself at appropriate junctures.
   (You need to establish your own notion of a work “cycle” for a background thread—for example, after every cluster of actions.)
   **/

  /**
   From Apple DTS (about automaticallyMergesChangesFromParent and didChange notification):

   Core Data triggers the didChange notification when the context is “indeed” changed, or the changes will have impact to you. Here is the logic:

   1. Merging new objects does change the context, so the notification is always triggered.
   2. Merging deleted objects changes the context when the deleted objects are in use (or in other word, are held by your code).
   3. Merging updated objects changes the context when the updated objects are in use and not faulted.
   **/

  // MARK: - DidChange Events

  func testObserveInsertionsOnDidChangeNotification() {
    let context = container.viewContext
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let event = NSManagedObjectContext.ObservableEvents.didChange
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(context), event: event) { (change, event, observedContext) in
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertTrue(observedContext === context)
      XCTAssertEqual(change.insertedObjects.count, 1)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertTrue(change.updatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    context.performAndWait {
      let car = Car(context: context)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "1"
      car.maker = "123!"
    }
    waitForExpectations(timeout: 2)
  }

  func testObserveInsertionsOnDidChangeNotificationFiredOnDifferentQueue() {
    let context = container.viewContext
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let event = NSManagedObjectContext.ObservableEvents.didChange
    let queue = OperationQueue()
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(context), event: event, queue: queue) { (change, event, observedContext) in
      // The posting thread is the Main Thread but the queue specified is not.
      XCTAssertTrue(queue === OperationQueue.current)
      XCTAssertFalse(Thread.isMainThread)
      XCTAssertTrue(observedContext === context)
      XCTAssertEqual(change.insertedObjects.count, 1)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertTrue(change.updatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    context.performAndWait {
      let car = Car(context: context)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "1"
      car.maker = "123!"
    }
    waitForExpectations(timeout: 2)
  }

  func testObserveInsertionsOnDidChangeNotificationOnBackgroundContext() {
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let backgroundContext = container.newBackgroundContext()
    let event = NSManagedObjectContext.ObservableEvents.didChange
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(backgroundContext), event: event) { (change, event, observedContext) in
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertTrue(backgroundContext === observedContext)
      XCTAssertEqual(change.insertedObjects.count, 1)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertTrue(change.updatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    backgroundContext.performAndWait {
      let car = Car(context: backgroundContext)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "1"
      car.maker = "123!"
      backgroundContext.processPendingChanges() // on a background context, processPendingChanges() must be called to trigger the notification
    }
    waitForExpectations(timeout: 5)
  }

  func testObserveAsyncInsertionsOnDidChangeNotificationOnBackgroundContext() {
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let backgroundcontext = container.newBackgroundContext()
    let event = NSManagedObjectContext.ObservableEvents.didChange
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(backgroundcontext), event: event) { (change, event, observedContext) in
      XCTAssertFalse(Thread.isMainThread) // `perform` is async, and it is responsible for posting this notification.
      XCTAssertTrue(backgroundcontext === observedContext)
      XCTAssertEqual(change.insertedObjects.count, 1)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertTrue(change.updatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    // perform, as stated in the documentation, calls internally processPendingChanges
    backgroundcontext.perform {
      XCTAssertFalse(Thread.isMainThread)
      let car = Car(context: backgroundcontext)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "1"
      car.maker = "123!"
    }
    waitForExpectations(timeout: 5)
  }

  func testObserveAsyncInsertionsOnDidChangeNotificationOnBackgroundContextAndDispatchQueue() {
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let backgroundContext = container.newBackgroundContext()
    let event = NSManagedObjectContext.ObservableEvents.didChange
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(backgroundContext), event: event) { (change, event, observedContext) in
      XCTAssertFalse(Thread.isMainThread)
      XCTAssertTrue(backgroundContext === observedContext)
      XCTAssertEqual(change.insertedObjects.count, 200)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertTrue(change.updatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    // performBlockAndWait will always run in the calling thread.
    // Using a DispatchQueue, we are making sure that it's not run on the Main Thread
    DispatchQueue.global().async {
      backgroundContext.performAndWait {
        XCTAssertFalse(Thread.isMainThread)
        (1...100).forEach({ i in
          let car = Car(context: backgroundContext)
          car.maker = "FIAT"
          car.model = "Panda"
          car.numberPlate = UUID().uuidString
          car.maker = "123!"
          let person = Person(context: backgroundContext)
          person.firstName = UUID().uuidString
          person.lastName = UUID().uuidString
          car.owner = person
        })
        XCTAssertTrue(backgroundContext.hasChanges, "The context should have uncommitted changes.")
        backgroundContext.processPendingChanges()
      }
    }

    waitForExpectations(timeout: 5)
  }

  func testObserveNoInsertionsOnDidChangeNotificationOnBackgroundContext() {
    let expectation = self.expectation(description: "\(#function)\(#line)")
    expectation.isInverted = true
    let backgroundContext = container.newBackgroundContext()
    let event = NSManagedObjectContext.ObservableEvents.didChange
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(backgroundContext), event: event) { (change, event, observedContext) in
      // The context doesn't have any changes so the notifcation shouldn't be issued.
      print(change)
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    backgroundContext.performAndWait {
      backgroundContext.processPendingChanges()
    }
    waitForExpectations(timeout: 2)
  }

  func testObserveInsertionsOnDidChangeNotificationOnPrivateContext() throws {
    let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    privateContext.persistentStoreCoordinator = container.persistentStoreCoordinator
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let event = NSManagedObjectContext.ObservableEvents.didChange
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(privateContext), event: event) { (change, event, observedContext) in
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertTrue(observedContext === privateContext)
      XCTAssertEqual(change.insertedObjects.count, 1)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertTrue(change.updatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    privateContext.performAndWait {
      let car = Car(context: privateContext)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "1"
      car.maker = "123!"
      privateContext.processPendingChanges()
    }
    waitForExpectations(timeout: 5)
  }

  func testObserveInsertionsOnDidChangeNotificationOnMainContext() throws {
    let mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    mainContext.persistentStoreCoordinator = container.persistentStoreCoordinator
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let event = NSManagedObjectContext.ObservableEvents.didChange
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(mainContext), event: event) { (change, event, observedContext) in
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertTrue(observedContext === mainContext)
      XCTAssertEqual(change.insertedObjects.count, 1)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertTrue(change.updatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    mainContext.performAndWait {
      let car = Car(context: mainContext)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "1"
      car.maker = "123!"
      mainContext.processPendingChanges()
    }
    waitForExpectations(timeout: 5)
  }

  func testObserveRefreshedObjectsOnDidChangeNotification() throws {
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()
    let registeredObjectsCount = context.registeredObjects.count
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let event = NSManagedObjectContext.ObservableEvents.didChange
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(context), event: event) { (change, event, observedContext) in
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertTrue(observedContext === context)
      XCTAssertTrue(change.insertedObjects.isEmpty)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertEqual(change.refreshedObjects.count, registeredObjectsCount)
      XCTAssertTrue(change.updatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    context.refreshAllObjects()

    waitForExpectations(timeout: 5)
  }

  // MARK: - WillSave/DidSave Events

  func testObserveInsertionsOnWillSaveNotification() throws {
    let context = container.viewContext
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let event = NSManagedObjectContext.ObservableEvents.willSave
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(context), event: event) { (change, event, observedContext) in
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertTrue(observedContext === context)
      XCTAssertTrue(change.insertedObjects.isEmpty)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertTrue(change.updatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    let car = Car(context: context)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = "1"
    car.maker = "123!"

    try context.save()
    waitForExpectations(timeout: 2)
  }

  func testObserveInsertionsOnWillSaveNotifiationAreNotFired() throws {
    // context will be observed, backgroundContext will be used to inser a new object
    // since the changes happen in the backgroundContext, the observed context (viewContext) won't notify anything
    let context = container.viewContext
    let backgroundContext = container.newBackgroundContext()
    let expectation = self.expectation(description: "\(#function)\(#line)")
    expectation.isInverted = true
    let event = NSManagedObjectContext.ObservableEvents.willSave
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(context), event: event) { (change, event, observedContext) in
      // viewContext is observed, but changes happen in another context
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    try backgroundContext.performAndWaitResult { ctx in
      let car = Car(context: ctx)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "1"
      car.maker = "123!"
      try backgroundContext.save()
    }

    waitForExpectations(timeout: 2)
  }

  func testObserveInsertionsOnDidSaveNotification() throws {
    let context = container.viewContext
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let event = NSManagedObjectContext.ObservableEvents.didSave
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(context), event: event) { (change, event, observedContext) in
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertTrue(observedContext === context)
      XCTAssertEqual(change.insertedObjects.count, 1)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertTrue(change.updatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    let car = Car(context: context)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = "1"
    car.maker = "123!"

    try context.save()
    waitForExpectations(timeout: 2)
  }

  // probably it's not a valid test
  func testObserveOnlyInsertionsOnDidChangeUsingBackgroundContextsAndAutomaticallyMergesChangesFromParent() throws {
    let backgroundContext1 = container.newBackgroundContext()
    let backgroundContext2 = container.newBackgroundContext()
    backgroundContext2.automaticallyMergesChangesFromParent = true // This cause a change not a save, obviously

    // From Apple DTS:
    // Core Data triggers the didChange notification when the context is “indeed” changed, or the changes will have impact to you. Here is the logic:
    //  1. Merging new objects does change the context, so the notification is always triggered.
    //  2. Merging deleted objects changes the context when the deleted objects are in use (or in other word, are held by your code).
    //  3. Merging updated objects changes the context when the updated objects are in use and not faulted.

    let expectation = self.expectation(description: "\(#function)\(#line)")
    expectation.expectedFulfillmentCount = 1
    let event = NSManagedObjectContext.ObservableEvents.didChange
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(backgroundContext2), event: event) { (change, event, observedContext) in
      XCTAssertFalse(Thread.isMainThread)
      XCTAssertTrue(observedContext === backgroundContext2)
      XCTAssertEqual(change.insertedObjects.count, 1)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertTrue(change.updatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    try backgroundContext1.performSaveAndWait { context in
      let car = Car(context: backgroundContext1)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "1"
      car.maker = "123!"
    }

    // no objects are used (kept and materialized by backgroundContext2 so a delete notification will not be triggered)
    try backgroundContext1.performSaveAndWait { context in
      try Car.deleteAll(in: context)
    }

    waitForExpectations(timeout: 2)
  }

  func testObserveMultipleChangesOnMaterializedObjects() throws {
    let viewContext = container.newBackgroundContext()
    viewContext.automaticallyMergesChangesFromParent = true // This cause a change not a save, obviously

    let backgroundContext1 = container.newBackgroundContext()
    let backgroundContext2 = container.newBackgroundContext()

    let expectation1 = self.expectation(description: "Changes on Contex1")
    let expectation2 = self.expectation(description: "Changes on Contex2")
    let expectation3 = self.expectation(description: "New Changes on Contex1")

    // From Apple DTS:
    // Core Data triggers the didChange notification when the context is “indeed” changed, or the changes will have impact to you. Here is the logic:
    //  1. Merging new objects does change the context, so the notification is always triggered.
    //  2. Merging deleted objects changes the context when the deleted objects are in use (or in other word, are held by your code).
    //  3. Merging updated objects changes the context when the updated objects are in use and not faulted.

    var count = 0
    let lock = NSLock()
    var holds = Set<NSManagedObject>()
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(viewContext), event: .didChange) { (change, event, observedContext) in
      lock.lock()
      defer { lock.unlock() }

      XCTAssertTrue(observedContext === viewContext)

      switch count {
      case 0:
        XCTAssertFalse(Thread.isMainThread)
        XCTAssertEqual(change.insertedObjects.count, 1)
        XCTAssertTrue(change.deletedObjects.isEmpty)
        XCTAssertTrue(change.refreshedObjects.isEmpty)
        XCTAssertTrue(change.updatedObjects.isEmpty)
        XCTAssertTrue(change.invalidatedObjects.isEmpty)
        XCTAssertTrue(change.invalidatedAllObjects.isEmpty)

        // To register changes from other contexts, we need to materialize and keep object inserted from other contexts
        // otherwise you will receive notifications only for used objects (in this case there are used objects by context0)
        change.insertedObjects.forEach {
          $0.willAccessValue(forKey: nil)
          holds.insert($0)
        }
        count += 1
        expectation1.fulfill()
      case 1:
        XCTAssertFalse(Thread.isMainThread)
        XCTAssertEqual(change.refreshedObjects.count, 1)
        count += 1
        expectation2.fulfill()
      case 2:
        XCTAssertTrue(Thread.isMainThread)
        XCTAssertTrue(observedContext === viewContext)
        XCTAssertEqual(change.updatedObjects.count, 1)
        count += 1
        expectation3.fulfill()
      default:
        #if !targetEnvironment(macCatalyst)
        // Bug
        // from DTS
        // It seems like when ‘automaticallyMergesChangesFromParent’ is true, Core Data on macOS still merge the changes,
        // even though the changes are from the same context, which is not optimized.
        XCTFail("Unexpected change.")
        #endif
      }
    }
    _ = observer // remove unused warning...

    let numberPlate = "123!"
    try backgroundContext1.performSaveAndWait { context in
      let car = Car(context: context)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = numberPlate
    }

    wait(for: [expectation1], timeout: 5)

    try backgroundContext2.performSaveAndWait { context in
      guard let car = try Car.findUniqueOrFetch(in: context, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), numberPlate)) else {
        XCTFail("Car not found")
        return
      }
      car.model = "**Panda**"
    }

    wait(for: [expectation2], timeout: 5)

    try viewContext.performSaveAndWait { context in
      guard let car = try Car.findUniqueOrFetch(in: context, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), numberPlate)) else {
        XCTFail("Car not found")
        return
      }
      car.maker = "**FIAT**"
    }

    wait(for: [expectation3], timeout: 5)
  }

  func testObserveRefreshesOnMaterializedObjects() throws {
    let backgroundContext1 = container.newBackgroundContext()
    let backgroundContext2 = container.newBackgroundContext()

    // 10 Pandas are created on backgroundContext2
    try backgroundContext2.performSaveAndWait { context in
      (1...10).forEach { numberPlate in
        let car = Car(context: context)
        car.maker = "FIAT"
        car.model = "Panda"
        car.numberPlate = "\(numberPlate)"
      }
    }

    // From Apple DTS:
    // Core Data triggers the didChange notification when the context is “indeed” changed, or the changes will have impact to you. Here is the logic:
    //  1. Merging new objects does change the context, so the notification is always triggered.
    //  2. Merging deleted objects changes the context when the deleted objects are in use (or in other word, are held by your code).
    //  3. Merging updated objects changes the context when the updated objects are in use and not faulted.

    let viewContext = container.viewContext
    viewContext.automaticallyMergesChangesFromParent = true // This cause a change not a save, obviously

    // We fetch and materialize only 2 Pandas: changes are expected only when they impact these two cars.
    let fetch = Car.newFetchRequest()
    fetch.predicate = NSPredicate(format: "%K IN %@", #keyPath(Car.numberPlate), ["1", "2"] )
    let cars = try viewContext.fetch(fetch)
    cars.forEach { $0.willAccessValue(forKey: nil) }
    XCTAssertEqual(cars.count, 2)

    let expectation1 = self.expectation(description: "DidChange for Panda with number plate: 2")
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(viewContext), event: .didChange) { (change, event, observedContext) in
      XCTAssertTrue(change.insertedObjects.isEmpty)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertEqual(change.refreshedObjects.count, 1)
      XCTAssertTrue(change.updatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation1.fulfill()
    }
    _ = observer // remove unused warning...

    // car with n. 3, doesn't impact the didChange because it's not materialized in context0
    try backgroundContext2.performSaveAndWait { context in
      guard let car = try Car.findUniqueOrFetch(in: context, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), "3")) else {
        XCTFail("Car not found")
        return
      }
      car.model = "**Panda**"
    }

    // car with n. 6, doesn't impact the didChange because it's not materialized in context0
    try backgroundContext1.performSaveAndWait { context in
      guard let car = try Car.findUniqueOrFetch(in: context, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), "6")) else {
        XCTFail("Car not found")
        return
      }
      car.delete()
    }

    // car with n. 2, impact the didChange because it's materialized in context0
    try backgroundContext2.performSaveAndWait { context in
      guard let car = try Car.findUniqueOrFetch(in: context, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), "2")) else {
        XCTFail("Car not found")
        return
      }
      car.model = "**Panda**"
    }

    waitForExpectations(timeout: 5)
  }

  func testObserveInsertionsUpdatesAndDeletesOnDidSaveNotification() throws {
    let context = container.viewContext
    let expectation = self.expectation(description: "\(#function)\(#line)")

    let car1 = Car(context: context)
    car1.maker = "FIAT"
    car1.model = "Panda"
    car1.numberPlate = UUID().uuidString
    car1.maker = "maker"

    let car2 = Car(context: context)
    car2.maker = "FIAT"
    car2.model = "Punto"
    car2.numberPlate = UUID().uuidString
    car2.maker = "maker"

    try context.save()

    let event = NSManagedObjectContext.ObservableEvents.didSave
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(context), event: event) { (change, event, observedContext) in
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertTrue(observedContext === context)
      XCTAssertEqual(change.insertedObjects.count, 2)
      XCTAssertEqual(change.deletedObjects.count, 1)
      XCTAssertEqual(change.updatedObjects.count, 1)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    // 2 inserts
    let car3 = Car(context: context)
    car3.maker = "FIAT"
    car3.model = "Qubo"
    car3.numberPlate = UUID().uuidString
    car3.maker = "maker"

    let car4 = Car(context: context)
    car4.maker = "FIAT"
    car4.model = "500"
    car4.numberPlate = UUID().uuidString
    car4.maker = "maker"

    // 1 update
    car1.model = "new Panda"
    // 1 delete
    car2.delete()

    try context.save()
    waitForExpectations(timeout: 2)
  }

  func testObserveMultipleChangesUsingPersistentStoreCoordinatorWithChildAndParentContexts() throws {
    // Given
    let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
    let storeURL = URL.newDatabaseURL(withID: UUID())
    try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)

    let parentContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    parentContext.persistentStoreCoordinator = psc

    let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    childContext.parent = parentContext

    let childContext2 = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    childContext2.parent = parentContext

    let expectation = self.expectation(description: "\(#function)\(#line)")
    let expectation2 = self.expectation(description: "\(#function)\(#line)")

    let car1Plate = UUID().uuidString
    let car2Plate = UUID().uuidString

    // When, Then
    try childContext.performAndWaitResult { context in
      let car1 = Car(context: context)
      let car2 = Car(context: context)
      car1.maker = "FIAT"
      car1.model = "Panda"
      car1.numberPlate = car1Plate
      car1.maker = "maker"

      car2.maker = "FIAT"
      car2.model = "Punto"
      car2.numberPlate = car2Plate
      car2.maker = "maker"
      try context.save()
    }

    try parentContext.performAndWaitResult { context in
      try context.save()
    }

    // Changes are propagated from the child to the parent during the save.
    var count = 0
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(parentContext), event: .didChange) { (change, event, observedContext) in
      XCTAssertTrue(Thread.isMainThread)
      if count == 0 {
        XCTAssertTrue(observedContext === parentContext)
        XCTAssertEqual(change.insertedObjects.count, 2)
        XCTAssertTrue(change.deletedObjects.isEmpty)
        XCTAssertTrue(change.updatedObjects.isEmpty)
        XCTAssertTrue(change.refreshedObjects.isEmpty)
        XCTAssertTrue(change.invalidatedObjects.isEmpty)
        XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
        count += 1
      } else if count == 1 {
        XCTAssertTrue(observedContext === parentContext)
        XCTAssertTrue(change.insertedObjects.isEmpty)
        XCTAssertTrue(change.deletedObjects.isEmpty)
        XCTAssertEqual(change.updatedObjects.count, 1)
        XCTAssertTrue(change.refreshedObjects.isEmpty)
        XCTAssertTrue(change.invalidatedObjects.isEmpty)
        XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
        count += 1
      } else if count == 2 {
        XCTAssertTrue(observedContext === parentContext)
        XCTAssertTrue(change.insertedObjects.isEmpty)
        XCTAssertEqual(change.deletedObjects.count, 1)
        XCTAssertTrue(change.updatedObjects.isEmpty)
        XCTAssertTrue(change.refreshedObjects.isEmpty)
        XCTAssertTrue(change.invalidatedObjects.isEmpty)
        XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
        count += 1
      } else if count == 3 {
        XCTAssertTrue(observedContext === parentContext)
        XCTAssertEqual(change.insertedObjects.count, 1)
        XCTAssertTrue(change.deletedObjects.isEmpty)
        XCTAssertTrue(change.updatedObjects.isEmpty)
        XCTAssertTrue(change.refreshedObjects.isEmpty)
        XCTAssertTrue(change.invalidatedObjects.isEmpty)
        XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
        expectation.fulfill()
      }
    }

    let observer2 = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(parentContext), event: .didSave) { (change, event, observedContext) in
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertTrue(observedContext === parentContext)
      XCTAssertEqual(change.insertedObjects.count, 3)
      XCTAssertEqual(change.deletedObjects.count, 1)
      XCTAssertEqual(change.updatedObjects.count, 1)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation2.fulfill()
    }

    // remove unused warning...
    _ = observer
    _ = observer2

    try childContext.performSaveAndWait { context in
      // 2 inserts
      let car3 = Car(context: context)
      car3.maker = "FIAT"
      car3.model = "Qubo"
      car3.numberPlate = UUID().uuidString

      let car4 = Car(context: context)
      car4.maker = "FIAT"
      car4.model = "500"
      car4.numberPlate = UUID().uuidString
      // the save triggers the didChange event
    }

    try childContext.performSaveAndWait { context in
      guard let car1 = try Car.findUniqueOrFetch(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", car1Plate)) else {
        XCTFail("Car not found.")
        return
      }
      car1.model = "Panda 1**"
      car1.maker = "FIAT**"
      car1.numberPlate = "111**"
    }

    try childContext.performSaveAndWait { context in
      guard let car2 = try Car.findUniqueOrFetch(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", car2Plate)) else {
        XCTFail("Car not found.")
        return
      }
      car2.delete()
    }

    try childContext2.performSaveAndWait { context in
      let car5 = Car(context: context)
      car5.maker = "FIAT"
      car5.model = "500"
      car5.numberPlate = UUID().uuidString
    }

    try parentContext.performAndWaitResult { context in
      try context.save() // triggers the didSave event
    }

    waitForExpectations(timeout: 10)


    // cleaning stuff
    let store = psc.persistentStores.first!
    try psc.remove(store)
    try NSPersistentStoreCoordinator.destroyStore(at: storeURL)
  }

  func testObserveDeletesOnDidSaveNotificationAreNotFiredIfObserverFromWrongContext() throws {
    let context = container.viewContext
    let expectation = self.expectation(description: "\(#function)\(#line)")
    expectation.isInverted = true
    let car1 = Car(context: context)
    car1.maker = "FIAT"
    car1.model = "Panda"
    car1.numberPlate = UUID().uuidString
    car1.maker = "maker"

    try context.save()
    let wrongContext = container.newBackgroundContext()
    wrongContext.automaticallyMergesChangesFromParent = true

    let event = NSManagedObjectContext.ObservableEvents.didSave
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(wrongContext), event: event) { (change, event, observedContext) in
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    car1.delete()

    try context.save()
    waitForExpectations(timeout: 2)
  }
}
