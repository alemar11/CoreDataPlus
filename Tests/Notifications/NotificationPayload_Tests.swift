// CoreDataPlus

import Combine
import CoreData
import XCTest

@testable import CoreDataPlus

final class NotificationPayload_Tests: InMemoryTestCase {
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
   Instead, you pass the notification as an argument to mergeChangesFromContextDidSaveNotification: (which you send to the context on thread A).
   Using this method, the context is able to safely merge the changes.

   If you need finer-grained control, you can use the managed object context change notification, NSManagedObjectContextObjectsDidChangeNotification—the notification’s user info dictionary again contains arrays with the managed objects that were inserted, deleted, and updated. In this scenario, however, you register for the notification on thread B.
   When you receive the notification, the managed objects in the user info dictionary are associated with the same thread, so you can access their object IDs.
   You pass the object IDs to thread A by sending a suitable message to an object on thread A. Upon receipt, on thread A you can refetch the corresponding managed objects.

   Note that the change notification is sent in NSManagedObjectContext’s processPendingChanges method.
   The main thread is tied into the event cycle for the application so that processPendingChanges is invoked automatically after every user event on contexts owned by the main thread.
   This is not the case for background threads—when the method is invoked depends on both the platform and the release version, so you should not rely on particular timing.
   ▶️ If the secondary context is not on the main thread, you should call processPendingChanges yourself at appropriate junctures.
   (You need to establish your own notion of a work “cycle” for a background thread—for example, after every cluster of actions.)

   From Apple DTS (about automaticallyMergesChangesFromParent and didChange notification):

   Core Data triggers the didChange notification when the context is “indeed” changed, or the changes will have impact to you. Here is the logic:

   1. Merging new objects does change the context, so the notification is always triggered.
   2. Merging deleted objects changes the context when the deleted objects are in use (or in other word, are held by your code).
   3. Merging updated objects changes the context when the updated objects are in use and not faulted.
   */

  // MARK: - NSManagedObjectContextObjectsDidChange

  @MainActor
  func test_ObserveInsertionsAndInvalidationsOnDidChangeNotification() {
    // Invalidation causes:
    // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/TroubleshootingCoreData.html
    // Either you have removed the store for the fault you are attempting to fire, or the managed object's context has been sent a reset.
    let context = container.viewContext
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let expectation2 = self.expectation(description: "\(#function)\(#line)")

    var count = 0
    let cancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)
      .map { ManagedObjectContextObjectsDidChange(notification: $0) }
      .sink { payload in
        switch count {
        case 0:
          count += 1
          XCTAssertTrue(Thread.isMainThread)
          XCTAssertTrue(payload.managedObjectContext === context)
          XCTAssertEqual(payload.insertedObjects.count, 1)
          XCTAssertTrue(payload.deletedObjects.isEmpty)
          XCTAssertTrue(payload.refreshedObjects.isEmpty)
          XCTAssertTrue(payload.updatedObjects.isEmpty)
          XCTAssertTrue(payload.invalidatedObjects.isEmpty)
          XCTAssertTrue(payload.invalidatedAllObjects.isEmpty)
          expectation.fulfill()
        case 1:
          count += 1
          XCTAssertTrue(Thread.isMainThread)
          XCTAssertTrue(payload.managedObjectContext === context)
          XCTAssertTrue(payload.insertedObjects.isEmpty)
          XCTAssertTrue(payload.deletedObjects.isEmpty)
          XCTAssertTrue(payload.refreshedObjects.isEmpty)
          XCTAssertTrue(payload.updatedObjects.isEmpty)
          XCTAssertTrue(payload.invalidatedObjects.isEmpty)
          XCTAssertEqual(payload.invalidatedAllObjects.count, 1)
          expectation2.fulfill()
        default:
          XCTFail("Too many notifications.")
        }
      }

    context.performAndWait {
      let car = Car(context: context)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "1"
      context.processPendingChanges()
    }

    context.performAndWait {
      context.reset()
    }

    waitForExpectations(timeout: 2)
    cancellable.cancel()
  }

  @MainActor
  func test_ObserveInsertionsOnDidChangeNotificationOnBackgroundContext() {
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let backgroundContext = container.newBackgroundContext()
    let cancellable = NotificationCenter.default.publisher(
      for: .NSManagedObjectContextObjectsDidChange, object: backgroundContext
    )
    .map { ManagedObjectContextObjectsDidChange(notification: $0) }
    .sink { payload in
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertTrue(payload.managedObjectContext === backgroundContext)
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertEqual(payload.insertedObjects.count, 1)
      XCTAssertTrue(payload.deletedObjects.isEmpty)
      XCTAssertTrue(payload.refreshedObjects.isEmpty)
      XCTAssertTrue(payload.updatedObjects.isEmpty)
      XCTAssertTrue(payload.invalidatedObjects.isEmpty)
      XCTAssertTrue(payload.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }

    // on a background context, processPendingChanges() must be called to trigger the notification
    backgroundContext.performAndWait {
      let car = Car(context: backgroundContext)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "1"
      car.maker = "123!"
      backgroundContext.processPendingChanges()
    }
    waitForExpectations(timeout: 5)
    cancellable.cancel()
  }

  @MainActor
  func test_ObserveAsyncInsertionsOnDidChangeNotificationOnBackgroundContext() {
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let backgroundContext = container.newBackgroundContext()
    let cancellable = NotificationCenter.default.publisher(
      for: .NSManagedObjectContextObjectsDidChange, object: backgroundContext
    )
    .map { ManagedObjectContextObjectsDidChange(notification: $0) }
    .sink { payload in
      XCTAssertFalse(Thread.isMainThread)
      XCTAssertTrue(payload.managedObjectContext === backgroundContext)
      XCTAssertFalse(Thread.isMainThread)  // `perform` is async, and it is responsible for posting this notification.
      XCTAssertEqual(payload.insertedObjects.count, 1)
      XCTAssertTrue(payload.deletedObjects.isEmpty)
      XCTAssertTrue(payload.refreshedObjects.isEmpty)
      XCTAssertTrue(payload.updatedObjects.isEmpty)
      XCTAssertTrue(payload.invalidatedObjects.isEmpty)
      XCTAssertTrue(payload.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }

    // perform, as stated in the documentation, calls internally processPendingChanges
    backgroundContext.perform {
      XCTAssertFalse(Thread.isMainThread)
      let car = Car(context: backgroundContext)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "1"
      car.maker = "123!"
    }
    waitForExpectations(timeout: 5)
    cancellable.cancel()
  }

  @MainActor
  func test_ObserveAsyncInsertionsOnDidChangeNotificationOnBackgroundContextAndDispatchQueue() {
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let backgroundContext = container.newBackgroundContext()
    let cancellable = NotificationCenter.default.publisher(
      for: .NSManagedObjectContextObjectsDidChange, object: backgroundContext
    )
    .map { ManagedObjectContextObjectsDidChange(notification: $0) }
    .sink { payload in
      XCTAssertFalse(Thread.isMainThread)
      XCTAssertTrue(payload.managedObjectContext === backgroundContext)
      XCTAssertFalse(Thread.isMainThread)  // `perform` is async, and it is responsible for posting this notification.
      XCTAssertEqual(payload.insertedObjects.count, 200)
      XCTAssertTrue(payload.deletedObjects.isEmpty)
      XCTAssertTrue(payload.refreshedObjects.isEmpty)
      XCTAssertTrue(payload.updatedObjects.isEmpty)
      XCTAssertTrue(payload.invalidatedObjects.isEmpty)
      XCTAssertTrue(payload.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }

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
    cancellable.cancel()
  }

  @MainActor
  func test_ObserveInsertionsOnDidChangeNotificationOnPrivateContext() throws {
    let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    privateContext.persistentStoreCoordinator = container.persistentStoreCoordinator
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let cancellable = NotificationCenter.default.publisher(
      for: .NSManagedObjectContextObjectsDidChange, object: privateContext
    )
    .map { ManagedObjectContextObjectsDidChange(notification: $0) }
    .sink { payload in
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertTrue(payload.managedObjectContext === privateContext)
      XCTAssertEqual(payload.insertedObjects.count, 1)
      XCTAssertTrue(payload.deletedObjects.isEmpty)
      XCTAssertTrue(payload.refreshedObjects.isEmpty)
      XCTAssertTrue(payload.updatedObjects.isEmpty)
      XCTAssertTrue(payload.invalidatedObjects.isEmpty)
      XCTAssertTrue(payload.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }

    privateContext.performAndWait {
      let car = Car(context: privateContext)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "1"
      car.maker = "123!"
      privateContext.processPendingChanges()
    }
    waitForExpectations(timeout: 5)
    cancellable.cancel()
  }

  @MainActor
  func test_ObserveRefreshedObjectsOnDidChangeNotification() throws {
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()
    let registeredObjectsCount = context.registeredObjects.count
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let cancellable = NotificationCenter.default.publisher(
      for: .NSManagedObjectContextObjectsDidChange, object: context
    )
    .map { ManagedObjectContextObjectsDidChange(notification: $0) }
    .sink { payload in
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertTrue(payload.managedObjectContext === context)
      XCTAssertTrue(payload.insertedObjects.isEmpty)
      XCTAssertTrue(payload.deletedObjects.isEmpty)
      XCTAssertEqual(payload.refreshedObjects.count, registeredObjectsCount)
      XCTAssertTrue(payload.updatedObjects.isEmpty)
      XCTAssertTrue(payload.invalidatedObjects.isEmpty)
      XCTAssertTrue(payload.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }

    context.refreshAllObjects()

    waitForExpectations(timeout: 5)
    cancellable.cancel()
  }

  // probably it's not a valid test
  @MainActor
  func test_ObserveOnlyInsertionsOnDidChangeUsingBackgroundContextsAndAutomaticallyMergesChangesFromParent() throws {
    let backgroundContext1 = container.newBackgroundContext()
    let backgroundContext2 = container.newBackgroundContext()
    backgroundContext2.automaticallyMergesChangesFromParent = true  // This cause a change not a save, obviously

    // From Apple DTS:
    // Core Data triggers the didChange notification when the context is “indeed” changed, or the changes will have impact to you. Here is the logic:
    //  1. Merging new objects does change the context, so the notification is always triggered.
    //  2. Merging deleted objects changes the context when the deleted objects are in use (or in other word, are held by your code).
    //  3. Merging updated objects changes the context when the updated objects are in use and not faulted.

    let expectation = self.expectation(description: "\(#function)\(#line)")
    expectation.expectedFulfillmentCount = 1
    let cancellable = NotificationCenter.default.publisher(
      for: .NSManagedObjectContextObjectsDidChange, object: backgroundContext2
    )
    .map { ManagedObjectContextObjectsDidChange(notification: $0) }
    .sink { payload in
      XCTAssertFalse(Thread.isMainThread)
      XCTAssertTrue(payload.managedObjectContext === backgroundContext2)
      XCTAssertEqual(payload.insertedObjects.count, 1)
      XCTAssertTrue(payload.deletedObjects.isEmpty)
      XCTAssertTrue(payload.refreshedObjects.isEmpty)
      XCTAssertTrue(payload.updatedObjects.isEmpty)
      XCTAssertTrue(payload.invalidatedObjects.isEmpty)
      XCTAssertTrue(payload.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }

    try backgroundContext1.performAndWait { _ in
      let car = Car(context: backgroundContext1)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "1"
      car.maker = "123!"
      try backgroundContext1.save()
    }

    // no objects are used (kept and materialized by backgroundContext2) so a delete notification will not be triggered
    try backgroundContext1.performAndWait { _ in
      try Car.delete(in: backgroundContext1)
      try backgroundContext1.save()
    }

    waitForExpectations(timeout: 2)
    cancellable.cancel()
  }

  func test_ObserveMultipleChangesOnMaterializedObjects() throws {
    let viewContext = container.newBackgroundContext()
    viewContext.automaticallyMergesChangesFromParent = true  // This cause a change not a save, obviously

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
    var holds = Set<NSManagedObject>()
    let cancellable = NotificationCenter.default.publisher(
      for: .NSManagedObjectContextObjectsDidChange, object: viewContext
    )
    .map { ManagedObjectContextObjectsDidChange(notification: $0) }
    .sink { payload in
      XCTAssertTrue(payload.managedObjectContext === viewContext)
      switch count {
      case 0:
        XCTAssertFalse(Thread.isMainThread)
        XCTAssertEqual(payload.insertedObjects.count, 1)
        XCTAssertTrue(payload.deletedObjects.isEmpty)
        XCTAssertTrue(payload.refreshedObjects.isEmpty)
        XCTAssertTrue(payload.updatedObjects.isEmpty)
        XCTAssertTrue(payload.invalidatedObjects.isEmpty)
        XCTAssertTrue(payload.invalidatedAllObjects.isEmpty)

        // To register changes from other contexts, we need to materialize and keep object inserted from other contexts
        // otherwise you will receive notifications only for used objects (in this case there are used objects by context0)
        for object in payload.insertedObjects {
          object.willAccessValue(forKey: nil)
          holds.insert(object)
        }
        count += 1
        expectation1.fulfill()
      case 1:
        XCTAssertFalse(Thread.isMainThread)
        XCTAssertEqual(payload.refreshedObjects.count, 1)
        count += 1
        expectation2.fulfill()
      case 2:
        XCTAssertTrue(Thread.isMainThread)
        XCTAssertEqual(payload.updatedObjects.count, 1)
        count += 1
        expectation3.fulfill()
      default:
        #if !targetEnvironment(macCatalyst)
          // DTS:
          // It seems like when ‘automaticallyMergesChangesFromParent’ is true, Core Data on macOS still merge the changes,
          // even though the changes are from the same context, which is not optimized.
          //
          // FB:
          // There are subtle differences in behavior of the runloop between UIApplication and NSApplication.
          // Observing just change notifications makes no promises about how many there may be because change notifications are
          // posted at the end of the run loop and whenever CoreData feels like it (the application lifecycle spins the main run loop).
          // Save notifications get called once per save.
          XCTFail("Unexpected change.")
        #endif
      }
    }

    let numberPlate = "123!"
    try backgroundContext1.performAndWait { _ in
      let car = Car(context: backgroundContext1)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = numberPlate
      try backgroundContext1.save()
    }

    wait(for: [expectation1], timeout: 5)

    try backgroundContext2.performAndWait { _ in
      let uniqueCar = try Car.fetchUniqueObject(
        in: backgroundContext2, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), numberPlate))
      guard let car = uniqueCar else {
        XCTFail("Car not found")
        return
      }
      car.model = "**Panda**"
      try backgroundContext2.save()
    }

    wait(for: [expectation2], timeout: 5)

    try viewContext.performAndWait { _ in
      let uniqueCar = try Car.fetchUniqueObject(
        in: viewContext, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), numberPlate))
      guard let car = uniqueCar else {
        XCTFail("Car not found")
        return
      }
      car.maker = "**FIAT**"
      try viewContext.save()
    }

    wait(for: [expectation3], timeout: 5)
    cancellable.cancel()
  }

  @MainActor
  func test_ObserveRefreshesOnMaterializedObjects() throws {
    let backgroundContext1 = container.newBackgroundContext()
    let backgroundContext2 = container.newBackgroundContext()

    // 10 Pandas are created on backgroundContext2
    try backgroundContext2.performAndWait { _ in
      for numberPlate in 1...10 {
        let car = Car(context: backgroundContext2)
        car.maker = "FIAT"
        car.model = "Panda"
        car.numberPlate = "\(numberPlate)"
        try backgroundContext2.save()
      }
    }

    // From Apple DTS:
    // Core Data triggers the didChange notification when the context is “indeed” changed, or the changes will have impact to you. Here is the logic:
    //  1. Merging new objects does change the context, so the notification is always triggered.
    //  2. Merging deleted objects changes the context when the deleted objects are in use (or in other word, are held by your code).
    //  3. Merging updated objects changes the context when the updated objects are in use and not faulted.

    let viewContext = container.viewContext
    viewContext.automaticallyMergesChangesFromParent = true  // This cause a change not a save, obviously

    // We fetch and materialize only 2 Pandas: changes are expected only when they impact these two cars.
    let fetch = Car.newFetchRequest()
    fetch.predicate = NSPredicate(format: "%K IN %@", #keyPath(Car.numberPlate), ["1", "2"])
    let cars = try viewContext.fetch(fetch)

    for car in cars {
      car.willAccessValue(forKey: nil)
    }

    XCTAssertEqual(cars.count, 2)

    let expectation1 = self.expectation(description: "DidChange for Panda with number plate: 2")
    let cancellable = NotificationCenter.default.publisher(
      for: .NSManagedObjectContextObjectsDidChange, object: viewContext
    )
    .map { ManagedObjectContextObjectsDidChange(notification: $0) }
    .sink { payload in
      XCTAssertTrue(payload.managedObjectContext === viewContext)
      XCTAssertTrue(payload.insertedObjects.isEmpty)
      XCTAssertTrue(payload.deletedObjects.isEmpty)
      XCTAssertEqual(payload.refreshedObjects.count, 1)
      XCTAssertTrue(payload.updatedObjects.isEmpty)
      XCTAssertTrue(payload.invalidatedObjects.isEmpty)
      XCTAssertTrue(payload.invalidatedAllObjects.isEmpty)
      expectation1.fulfill()
    }

    // car with n. 3, doesn't impact the didChange because it's not materialized in context0
    try backgroundContext2.performAndWait { _ in
      let uniqueCar = try Car.fetchUniqueObject(
        in: backgroundContext2, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), "3"))
      guard let car = uniqueCar else {
        XCTFail("Car not found")
        return
      }
      car.model = "**Panda**"
      try backgroundContext2.save()
    }

    // car with n. 6, doesn't impact the didChange because it's not materialized in context0
    try backgroundContext1.performAndWait { _ in
      let uniqueCar = try Car.fetchUniqueObject(
        in: backgroundContext1, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), "6"))
      guard let car = uniqueCar else {
        XCTFail("Car not found")
        return
      }
      car.delete()
      try backgroundContext1.save()
    }

    // car with n. 2, impact the didChange because it's materialized in context0
    try backgroundContext2.performAndWait { _ in
      let uniqueCar = try Car.fetchUniqueObject(
        in: backgroundContext2, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), "2"))
      guard let car = uniqueCar else {
        XCTFail("Car not found")
        return
      }
      car.model = "**Panda**"
      try backgroundContext2.save()
    }

    waitForExpectations(timeout: 5)
    cancellable.cancel()
  }

  // MARK: - NSManagedObjectContextWillSave and NSManagedObjectContextDidSave

  @MainActor
  func test_ObserveInsertionsOnWillSaveNotification() throws {
    let context = container.viewContext
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let cancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextWillSave, object: context)
      .map { ManagedObjectContextWillSaveObjects(notification: $0) }
      .sink { payload in
        XCTAssertTrue(Thread.isMainThread)
        XCTAssertTrue(payload.managedObjectContext === context)
        expectation.fulfill()
      }

    let car = Car(context: context)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = "1"
    car.maker = "123!"

    try context.save()
    waitForExpectations(timeout: 2)
    cancellable.cancel()
  }

  @MainActor
  func test_ObserveInsertionsOnDidSaveNotification() throws {
    let context = container.viewContext
    var cancellables = [AnyCancellable]()

    let expectation = self.expectation(description: "\(#function)\(#line)")
    expectation.assertForOverFulfill = false
    NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: context)
      .map { ManagedObjectContextDidSaveObjects(notification: $0) }
      .sink { payload in
        XCTAssertTrue(Thread.isMainThread)
        XCTAssertTrue(payload.managedObjectContext === context)
        XCTAssertEqual(payload.insertedObjects.count, 2)
        XCTAssertTrue(payload.deletedObjects.isEmpty)
        XCTAssertTrue(payload.updatedObjects.isEmpty)
        XCTAssertNil(payload.queryGenerationToken, "Query Generation Token is available only on SQLite stores.")
        expectation.fulfill()
      }
      .store(in: &cancellables)

    let expectation2 = self.expectation(description: "\(#function)\(#line)")
    expectation2.assertForOverFulfill = false
    NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSaveObjectIDs, object: context)
      .map { ManagedObjectContextDidSaveObjectIDs(notification: $0) }
      .sink { payload in
        XCTAssertTrue(payload.managedObjectContext === context)
        XCTAssertEqual(payload.insertedObjectIDs.count, 2)
        XCTAssertTrue(payload.deletedObjectIDs.isEmpty)
        XCTAssertTrue(payload.updatedObjectIDs.isEmpty)
        expectation2.fulfill()
      }
      .store(in: &cancellables)

    let car = Car(context: context)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = "1"

    let car2 = Car(context: context)
    car2.maker = "FIAT"
    car2.model = "Panda"
    car2.numberPlate = "2"

    try context.save()
    waitForExpectations(timeout: 2)

    for cancellable in cancellables {
      cancellable.cancel()
    }
  }

  @MainActor
  func test_ObserveInsertionsUpdatesAndDeletesOnDidSaveNotification() throws {
    let context = container.viewContext
    var cancellables = [AnyCancellable]()

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

    let expectation = self.expectation(description: "\(#function)\(#line)")

    NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: context)
      .map { ManagedObjectContextDidSaveObjects(notification: $0) }
      .sink { payload in
        XCTAssertTrue(Thread.isMainThread)
        XCTAssertTrue(payload.managedObjectContext === context)
        XCTAssertEqual(payload.insertedObjects.count, 2)
        XCTAssertEqual(payload.deletedObjects.count, 1)
        XCTAssertEqual(payload.updatedObjects.count, 1)
        expectation.fulfill()
      }
      .store(in: &cancellables)

    let expectation2 = self.expectation(description: "\(#function)\(#line)")
    expectation2.assertForOverFulfill = false
    NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSaveObjectIDs, object: context)
      .map { ManagedObjectContextDidSaveObjectIDs(notification: $0) }
      .sink { payload in
        XCTAssertTrue(payload.managedObjectContext === context)
        XCTAssertEqual(payload.insertedObjectIDs.count, 2)
        XCTAssertEqual(payload.deletedObjectIDs.count, 1)
        XCTAssertEqual(payload.updatedObjectIDs.count, 1)
        expectation2.fulfill()
      }
      .store(in: &cancellables)

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

    for cancellable in cancellables {
      cancellable.cancel()
    }
  }

  @MainActor
  func test_ObserveMultipleChangesUsingPersistentStoreCoordinatorWithChildAndParentContexts() throws {
    // Given
    let psc = NSPersistentStoreCoordinator(managedObjectModel: model1)
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
    try childContext.performAndWait { context in
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

    try parentContext.performAndWait { context in
      try context.save()
    }

    // Changes are propagated from the child to the parent during the save.
    var count = 0
    let cancellable = NotificationCenter.default.publisher(
      for: .NSManagedObjectContextObjectsDidChange, object: parentContext
    )
    .map { ManagedObjectContextObjectsDidChange(notification: $0) }
    .sink { payload in
      XCTAssertTrue(Thread.isMainThread)
      if count == 0 {
        XCTAssertTrue(payload.managedObjectContext === parentContext)
        XCTAssertEqual(payload.insertedObjects.count, 2)
        XCTAssertTrue(payload.deletedObjects.isEmpty)
        XCTAssertTrue(payload.updatedObjects.isEmpty)
        XCTAssertTrue(payload.refreshedObjects.isEmpty)
        XCTAssertTrue(payload.invalidatedObjects.isEmpty)
        XCTAssertTrue(payload.invalidatedAllObjects.isEmpty)
        count += 1
      } else if count == 1 {
        XCTAssertTrue(payload.managedObjectContext === parentContext)
        XCTAssertTrue(payload.insertedObjects.isEmpty)
        XCTAssertTrue(payload.deletedObjects.isEmpty)
        XCTAssertEqual(payload.updatedObjects.count, 1)
        XCTAssertTrue(payload.refreshedObjects.isEmpty)
        XCTAssertTrue(payload.invalidatedObjects.isEmpty)
        XCTAssertTrue(payload.invalidatedAllObjects.isEmpty)
        count += 1
      } else if count == 2 {
        XCTAssertTrue(payload.managedObjectContext === parentContext)
        XCTAssertTrue(payload.insertedObjects.isEmpty)
        XCTAssertEqual(payload.deletedObjects.count, 1)
        XCTAssertTrue(payload.updatedObjects.isEmpty)
        XCTAssertTrue(payload.refreshedObjects.isEmpty)
        XCTAssertTrue(payload.invalidatedObjects.isEmpty)
        XCTAssertTrue(payload.invalidatedAllObjects.isEmpty)
        count += 1
      } else if count == 3 {
        XCTAssertTrue(payload.managedObjectContext === parentContext)
        XCTAssertEqual(payload.insertedObjects.count, 1)
        XCTAssertTrue(payload.deletedObjects.isEmpty)
        XCTAssertTrue(payload.updatedObjects.isEmpty)
        XCTAssertTrue(payload.refreshedObjects.isEmpty)
        XCTAssertTrue(payload.invalidatedObjects.isEmpty)
        XCTAssertTrue(payload.invalidatedAllObjects.isEmpty)
        expectation.fulfill()
      }
    }

    let cancellable2 = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: parentContext)
      .map { ManagedObjectContextDidSaveObjects(notification: $0) }
      .sink { payload in
        XCTAssertTrue(Thread.isMainThread)
        XCTAssertTrue(payload.managedObjectContext === parentContext)
        XCTAssertEqual(payload.insertedObjects.count, 3)
        XCTAssertEqual(payload.deletedObjects.count, 1)
        XCTAssertEqual(payload.updatedObjects.count, 1)
        expectation2.fulfill()
      }

    try childContext.performAndWait { _ in
      // 2 inserts
      let car3 = Car(context: childContext)
      car3.maker = "FIAT"
      car3.model = "Qubo"
      car3.numberPlate = UUID().uuidString

      let car4 = Car(context: childContext)
      car4.maker = "FIAT"
      car4.model = "500"
      car4.numberPlate = UUID().uuidString
      // the save triggers the didChange event
      try childContext.save()
    }

    try childContext.performAndWait { _ in
      let uniqueCar1 = try Car.fetchUniqueObject(
        in: childContext, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), car1Plate))
      guard let car1 = uniqueCar1 else {
        XCTFail("Car not found.")
        return
      }
      car1.model = "Panda 1**"
      car1.maker = "FIAT**"
      car1.numberPlate = "111**"
      try childContext.save()
    }

    try childContext.performAndWait { _ in
      let uniqueCar2 = try Car.fetchUniqueObject(
        in: childContext, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), car2Plate))
      guard let car2 = uniqueCar2 else {
        XCTFail("Car not found.")
        return
      }
      car2.delete()
      try childContext.save()
    }

    try childContext2.performAndWait { childContext2 in
      let car5 = Car(context: childContext2)
      car5.maker = "FIAT"
      car5.model = "500"
      car5.numberPlate = UUID().uuidString
      try childContext2.save()
    }

    try parentContext.performAndWait { _ in
      try parentContext.save()  // triggers the didSave event
    }

    waitForExpectations(timeout: 10)

    // cleaning stuff
    let store = psc.persistentStores.first!
    try psc.remove(store)
    try NSPersistentStoreCoordinator.destroyStore(at: storeURL)
    cancellable.cancel()
    cancellable2.cancel()
  }

  // MARK: - Entity Observer Example

  @MainActor
  func test_ObserveInsertedOnDidChangeEventForSpecificEntities() {
    let context = container.viewContext
    let expectation1 = expectation(description: "\(#function)\(#line)")

    // Attention: sometimes entity() returns nil due to a CoreData bug occurring in the Unit Test targets or when Generics are used.
    // let entity = NSEntityDescription.entity(forEntityName: type.entity().name!, in: context)!

    func findObjectsOfType<T: NSManagedObject>(
      _ type: T.Type, in objects: Set<NSManagedObject>, observeSubEntities: Bool = true
    ) -> Set<T> {
      let entity = type.entity()
      if observeSubEntities {
        return objects.filter { $0.entity.isDescendantEntity(of: entity, recursive: true) || $0.entity == entity }
          as? Set<T> ?? []
      } else {
        return objects.filter { $0.entity == entity } as? Set<T> ?? []
      }
    }

    let cancellable = NotificationCenter.default.publisher(
      for: Notification.Name.NSManagedObjectContextObjectsDidChange, object: context
    )
    .map { ManagedObjectContextObjectsDidChange(notification: $0) }
    .sink { payload in
      let inserts = findObjectsOfType(SportCar.self, in: payload.insertedObjects, observeSubEntities: true)
      let inserts2 = findObjectsOfType(Car.self, in: payload.insertedObjects, observeSubEntities: true)
      let inserts3 = findObjectsOfType(Car.self, in: payload.insertedObjects, observeSubEntities: false)
      let deletes = findObjectsOfType(SportCar.self, in: payload.deletedObjects, observeSubEntities: true)
      let udpates = findObjectsOfType(SportCar.self, in: payload.updatedObjects, observeSubEntities: true)
      let refreshes = findObjectsOfType(SportCar.self, in: payload.refreshedObjects, observeSubEntities: true)
      let invalidates = findObjectsOfType(SportCar.self, in: payload.invalidatedObjects, observeSubEntities: true)
      let invalidatesAll = payload.invalidatedAllObjects.filter { $0.entity == SportCar.entity() }

      XCTAssertEqual(inserts.count, 1)
      XCTAssertEqual(inserts2.count, 2)
      XCTAssertEqual(inserts3.count, 1)
      XCTAssertTrue(deletes.isEmpty)
      XCTAssertTrue(udpates.isEmpty)
      XCTAssertTrue(refreshes.isEmpty)
      XCTAssertTrue(invalidates.isEmpty)
      XCTAssertTrue(invalidatesAll.isEmpty)
      expectation1.fulfill()
    }

    let sportCar = SportCar(context: context)
    sportCar.maker = "McLaren"
    sportCar.model = "570GT"
    sportCar.numberPlate = "203"

    let car = Car(context: context)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = "1"

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    waitForExpectations(timeout: 2)
    cancellable.cancel()
  }

  // MARK: - NSPersistentStoreRemoteChange

  @MainActor
  func test_InvestigationPersistentStoreRemoteChangeAndSave() throws {
    // Cross coordinators change notifications:

    let id = UUID()
    let container1 = OnDiskPersistentContainer.makeNew(id: id)
    let container2 = OnDiskPersistentContainer.makeNew(id: id)

    // Given
    let viewContext1 = container1.viewContext
    viewContext1.name = "viewContext1"
    viewContext1.transactionAuthor = "author1"

    let expectation1 = expectation(description: "NSPersistentStoreRemoteChange Notification sent by container1")
    let cancellable1 = NotificationCenter.default.publisher(
      for: .NSPersistentStoreRemoteChange, object: container1.persistentStoreCoordinator
    )
    .map { PersistentStoreRemoteChange(notification: $0) }
    .sink { payload in
      XCTAssertNotNil(payload.historyToken)
      XCTAssertNotNil(payload.storeUUID)
      let uuidString = container1.persistentStoreCoordinator.persistentStores.first?.metadata[NSStoreUUIDKey] as? String
      XCTAssertNotNil(uuidString)
      XCTAssertEqual(uuidString!, payload.storeUUID.uuidString)
      XCTAssertEqual(payload.storeURL, container1.persistentStoreCoordinator.persistentStores.first?.url)
      expectation1.fulfill()
    }

    let expectation2 = expectation(description: "NSPersistentStoreRemoteChange Notification sent by container2")
    let cancellable2 = NotificationCenter.default.publisher(
      for: .NSPersistentStoreRemoteChange, object: container2.persistentStoreCoordinator
    )
    .map { PersistentStoreRemoteChange(notification: $0) }
    .sink { payload in
      XCTAssertNotNil(payload.historyToken)
      XCTAssertNotNil(payload.storeUUID)
      let uuidString = container2.persistentStoreCoordinator.persistentStores.first?.metadata[NSStoreUUIDKey] as? String
      XCTAssertNotNil(uuidString)
      XCTAssertEqual(uuidString!, payload.storeUUID.uuidString)
      XCTAssertEqual(payload.storeURL, container2.persistentStoreCoordinator.persistentStores.first?.url)
      expectation2.fulfill()
    }

    let car = Car(context: viewContext1)
    car.maker = "FIAT"
    car.numberPlate = "123"
    car.model = "Panda"
    try viewContext1.save()

    waitForExpectations(timeout: 5, handler: nil)
    cancellable1.cancel()
    cancellable2.cancel()
  }

  @MainActor
  func test_InvestigationPersistentStoreRemoteChangeAndBatchOperations() throws {
    // Cross coordinators change notifications:
    // This notification notifies when history has been made even when batch operations are done.

    let id = UUID()
    let container1 = OnDiskPersistentContainer.makeNew(id: id)
    let container2 = OnDiskPersistentContainer.makeNew(id: id)

    // Given
    let viewContext1 = container1.viewContext
    viewContext1.name = "viewContext1"
    viewContext1.transactionAuthor = "author1"

    let expectation1 = expectation(description: "NSPersistentStoreRemoteChange Notification sent by container1")
    let cancellable1 = NotificationCenter.default.publisher(
      for: .NSPersistentStoreRemoteChange, object: container1.persistentStoreCoordinator
    )
    .map { PersistentStoreRemoteChange(notification: $0) }
    .sink { payload in
      XCTAssertNotNil(payload.historyToken)
      XCTAssertNotNil(payload.storeUUID)
      let uuidString = container1.persistentStoreCoordinator.persistentStores.first?.metadata[NSStoreUUIDKey] as? String
      XCTAssertNotNil(uuidString)
      XCTAssertEqual(uuidString!, payload.storeUUID.uuidString)
      XCTAssertEqual(payload.storeURL, container1.persistentStoreCoordinator.persistentStores.first?.url)
      expectation1.fulfill()
    }

    let expectation2 = expectation(description: "NSPersistentStoreRemoteChange Notification sent by container2")
    let cancellable2 = NotificationCenter.default.publisher(
      for: .NSPersistentStoreRemoteChange, object: container2.persistentStoreCoordinator
    )
    .map { PersistentStoreRemoteChange(notification: $0) }
    .sink { payload in
      XCTAssertNotNil(payload.historyToken)
      XCTAssertNotNil(payload.storeUUID)
      let uuidString = container2.persistentStoreCoordinator.persistentStores.first?.metadata[NSStoreUUIDKey] as? String
      XCTAssertNotNil(uuidString)
      XCTAssertEqual(uuidString!, payload.storeUUID.uuidString)
      XCTAssertEqual(payload.storeURL, container2.persistentStoreCoordinator.persistentStores.first?.url)
      expectation2.fulfill()
    }

    let object = [
      #keyPath(Car.maker): "FIAT",
      #keyPath(Car.numberPlate): "123",
      #keyPath(Car.model): "Panda",
    ]

    let result = try Car.batchInsert(using: viewContext1, resultType: .count, objects: [object])
    XCTAssertEqual(result.count!, 1)

    waitForExpectations(timeout: 5, handler: nil)
    cancellable1.cancel()
    cancellable2.cancel()
  }
}

final class NotificationPayloadOnDiskTests: OnDiskTestCase {
  @MainActor
  func test_ObserveInsertionsOnDidSaveNotification() throws {
    let context = container.viewContext
    try context.setQueryGenerationFrom(.current)
    var cancellables = [AnyCancellable]()

    let expectation = self.expectation(description: "\(#function)\(#line)")
    expectation.assertForOverFulfill = false
    NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: context)
      .map { ManagedObjectContextDidSaveObjects(notification: $0) }
      .sink { payload in
        XCTAssertTrue(Thread.isMainThread)
        XCTAssertTrue(payload.managedObjectContext === context)
        XCTAssertEqual(payload.insertedObjects.count, 2)
        XCTAssertTrue(payload.deletedObjects.isEmpty)
        XCTAssertTrue(payload.updatedObjects.isEmpty)
        // This test is primarly used to test the queryGenerationToken object in the notification payload
        XCTAssertNotNil(payload.queryGenerationToken)
        expectation.fulfill()
      }
      .store(in: &cancellables)

    let expectation2 = self.expectation(description: "\(#function)\(#line)")
    expectation2.assertForOverFulfill = false
    NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSaveObjectIDs, object: context)
      .map { ManagedObjectContextDidSaveObjectIDs(notification: $0) }
      .sink { payload in
        XCTAssertTrue(payload.managedObjectContext === context)
        XCTAssertEqual(payload.insertedObjectIDs.count, 2)
        XCTAssertTrue(payload.deletedObjectIDs.isEmpty)
        XCTAssertTrue(payload.updatedObjectIDs.isEmpty)
        XCTAssertTrue(payload.insertedObjectIDs.allSatisfy { !$0.isTemporaryID })
        expectation2.fulfill()
      }
      .store(in: &cancellables)

    let car = Car(context: context)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = "1"

    let car2 = Car(context: context)
    car2.maker = "FIAT"
    car2.model = "Panda"
    car2.numberPlate = "2"

    //print(car.objectID, car2.objectID)

    try context.save()
    waitForExpectations(timeout: 2)

    for cancellable in cancellables {
      cancellable.cancel()
    }
  }

  @MainActor
  func test_InvestigationInsertionsInChildContextOnDidSaveNotification() throws {
    // the scope of this test is to verify wheter or not a NSManagedObjectContextDidSaveObjectIDs notification
    // fired in a child context will have insertedObjectIDs with temporary IDs (expected)
    let context = container.viewContext
    let childViewContext = context.newChildContext(concurrencyType: .mainQueueConcurrencyType)
    var cancellables = [AnyCancellable]()

    let expectation2 = self.expectation(description: "\(#function)\(#line)")
    expectation2.assertForOverFulfill = false
    NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSaveObjectIDs, object: childViewContext)
      .map {
        ManagedObjectContextDidSaveObjectIDs(notification: $0)
      }
      .sink { payload in
        XCTAssertTrue(payload.managedObjectContext === childViewContext)
        XCTAssertEqual(payload.insertedObjectIDs.count, 2)
        XCTAssertTrue(payload.deletedObjectIDs.isEmpty)
        // we expect to have temporary IDs in the notification
        XCTAssertTrue(payload.insertedObjectIDs.allSatisfy { $0.isTemporaryID })
        expectation2.fulfill()
      }
      .store(in: &cancellables)

    let car = Car(context: childViewContext)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = "1"

    let car2 = Car(context: childViewContext)
    car2.maker = "FIAT"
    car2.model = "Panda"
    car2.numberPlate = "2"

    try childViewContext.save()
    waitForExpectations(timeout: 5)

    for cancellable in cancellables {
      cancellable.cancel()
    }
  }

  func test_InvestigationNSPersistentStoreCoordinatorStoresNotifications() throws {
    let psc = NSPersistentStoreCoordinator(managedObjectModel: model1)
    let initialStoreURL = URL.newDatabaseURL(withID: UUID())
    let finalStoreURL = URL.newDatabaseURL(withID: UUID())
    var cancellables = [AnyCancellable]()

    NotificationCenter.default.publisher(for: .NSPersistentStoreCoordinatorStoresWillChange, object: nil)
      .sink { notification in
        XCTFail("AFAIK this notification is sent only for deprecated settings for CoreDataUbiquitySupport.")
        //         Sample of a notification.userInfo (generated from anothr project):
        //
        //         ▿ 3 elements
        //         ▿ 0 : 2 elements
        //         ▿ key : AnyHashable("removed")
        //         - value : "removed"
        //         ▿ value : 1 element
        //         - 0 : <NSSQLCore: 0x11de25700> (URL: file:///var/mobile/Containers/Data/Application/A926CA73-AF4D-44E8-ADE5-246ED7F20D7B/Documents/CoreDataUbiquitySupport/mobile~18720936-2A3A-4C6F-BF8E-DF042ED5A917/MY_NAME/D26F608C-F8AC-4E51-AF6C-007B7DC56B7E/store/db.sqlite)
        //         ▿ 1 : 2 elements
        //         ▿ key : AnyHashable("NSPersistentStoreUbiquitousTransitionTypeKey")
        //         - value : "NSPersistentStoreUbiquitousTransitionTypeKey"
        //         - value : 4
        //         ▿ 2 : 2 elements
        //         ▿ key : AnyHashable("added")
        //         - value : "added"
        //         ▿ value : 1 element
        //         - 0 : <NSSQLCore: 0x11de25700> (URL: file:///var/mobile/Containers/Data/Application/A926CA73-AF4D-44E8-ADE5-246ED7F20D7B/Documents/CoreDataUbiquitySupport/mobile~18720936-2A3A-4C6F-BF8E-DF042ED5A917/MY_NAME/D26F608C-F8AC-4E51-AF6C-007B7DC56B7E/store/db.sqlite)
      }.store(in: &cancellables)

    NotificationCenter.default.publisher(for: .NSPersistentStoreCoordinatorStoresDidChange, object: nil)
      .sink { notification in
        let payload = PersistentStoreCoordinatorStoresDidChange(notification: notification)

        if let addedStore = payload.addedStores.first {
          if addedStore.url == initialStoreURL {
            // 1
            // print(1)
          } else if addedStore.url == finalStoreURL {
            // 2
            // print(2)
          }
        } else if let changedStore = payload.uuidChangedStore {
          // 5
          // print(5)

          XCTAssertEqual(changedStore.oldStore.url, initialStoreURL)
          XCTAssertEqual(changedStore.newStore.url, finalStoreURL)
          XCTAssertEqual(changedStore.migratedIDs.count, 4)

          // Sample Log
          // ➡️ ObjectIDs after save in the old store
          // 0xc4549980eaebab6a <x-coredata://1996EEB5-8536-4968-8725-FBC0D06A3F72/Person/p1> // A
          // 0xc4549980eae7ab6a <x-coredata://1996EEB5-8536-4968-8725-FBC0D06A3F72/Person/p2> // B
          // ➡️  ObjectIDs returned as third element by the NSPersistentStoreCoordinatorStoresDidChange
          // It contains both the old and new ObjectIds in sequence.
          // 0xc4549980eaebab6a <x-coredata://1996EEB5-8536-4968-8725-FBC0D06A3F72/Person/p1> // A
          // 0xc4549980eae7ab6e <x-coredata://0E12C804-B3CA-4CC3-9CD0-A98A473C3C3C/Person/p2> // A1
          // 0xc4549980eae7ab6a <x-coredata://1996EEB5-8536-4968-8725-FBC0D06A3F72/Person/p2> // B
          // 0xc4549980eaebab6e <x-coredata://0E12C804-B3CA-4CC3-9CD0-A98A473C3C3C/Person/p1> // B1
          // ➡️ ObjectIDs after fetch with the new store
          // 0xc4549980eae7ab6e <x-coredata://0E12C804-B3CA-4CC3-9CD0-A98A473C3C3C/Person/p2> // A1
          // 0xc4549980eaebab6e <x-coredata://0E12C804-B3CA-4CC3-9CD0-A98A473C3C3C/Person/p1> // B1

        } else if let removedStore = payload.removedStores.first {
          if removedStore.url == initialStoreURL {
            // 6
            // print(6)
          } else if removedStore.url == finalStoreURL {
            // 7
            // print(7)
          }
        } else {
          XCTFail("Unexpected use case.")
        }
      }.store(in: &cancellables)

    NotificationCenter.default.publisher(for: .NSPersistentStoreCoordinatorWillRemoveStore, object: nil)
      .sink { notification in
        let payload = PersistentStoreCoordinatorWillRemoveStore(notification: notification)
        let store = payload.store
        if store.url == initialStoreURL {
          // 3
          // print(3)
        } else if store.url == finalStoreURL {
          // 4
          // print(4)
        } else {
          XCTFail("Unexpected use case.")
        }
      }.store(in: &cancellables)

    // triggers a NSPersistentStoreCoordinatorStoresDidChange (1)
    try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: initialStoreURL, options: nil)

    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = psc

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    let person2 = Person(context: context)
    person2.firstName = "Alessandro"
    person2.lastName = "Marzoli"
    try context.save()
    context.reset()

    // triggers a NSPersistentStoreCoordinatorStoresDidChange (2)
    // triggers a NSPersistentStoreCoordinatorWillRemoveStore (3) for initial URL
    // triggers a NSPersistentStoreCoordinatorWillRemoveStore (4) for final URL
    // triggers a NSPersistentStoreCoordinatorStoresDidChange with a NSUUIDChangedPersistentStoresKey (5)
    // triggers a NSPersistentStoreCoordinatorWillRemoveStore (3) for initial URL
    // triggers a NSPersistentStoreCoordinatorStoresDidChange (6)

    for store in psc.persistentStores {
      try psc.migratePersistentStore(store, to: finalStoreURL, options: nil, withType: NSSQLiteStoreType)
    }

    // let people = try Person.fetch(in: context) { $0.sortDescriptors = [NSSortDescriptor(key: #keyPath(Person.firstName), ascending: false)] } // used only to create the sample log

    // triggers a NSPersistentStoreCoordinatorWillRemoveStore (4) for final URL
    // triggers a NSPersistentStoreCoordinatorStoresDidChange (7)
    for store in psc.persistentStores {
      try psc.remove(store)
    }

    context._fix_sqlite_warning_when_destroying_a_store()
    try FileManager.default.removeItem(at: initialStoreURL)
    try FileManager.default.removeItem(at: finalStoreURL)
  }
}
