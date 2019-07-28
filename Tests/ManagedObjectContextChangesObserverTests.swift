//
// CoreDataPlus
//
// Copyright © 2016-2019 Tinrobots.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import XCTest
import CoreData
@testable import CoreDataPlus

class ManagedObjectContextChangesObserverTests: CoreDataPlusTestCase {
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
   2. Merging deleted objects changes the context when the deleted objects are in use (or in other word, are holded by your code).
   3. Merging updated objects changes the context when the updated objects are in use and not faulted.
   **/

  // MARK: - DidChange Events

  func testObserveInsertChangeUsingViewContext() {
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

  func testObservInserteChangeNotifiedOnADifferentQueueUsingViewContext() {
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

  func testObserveInsertChangeNotifiedOnADifferentQueueUsingViewContext2() {
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

  func testObserveInsertChangeUsingBackgroundContext() {
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let context = container.newBackgroundContext()
    let event = NSManagedObjectContext.ObservableEvents.didChange
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(context), event: event) { (change, event, observedContext) in
      XCTAssertTrue(Thread.isMainThread)
      XCTAssertTrue(context === observedContext)
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
      context.processPendingChanges()
    }
    waitForExpectations(timeout: 5)
  }

  /// Users perform instead of performAndWait
  func testObserveInsertChangeUsingBackgroundContextAndPerform() {
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let context = container.newBackgroundContext()
    let event = NSManagedObjectContext.ObservableEvents.didChange
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(context), event: event) { (change, event, observedContext) in
      XCTAssertFalse(Thread.isMainThread) // `perform` is async, and it is responsible for posting this notification.
      XCTAssertTrue(context === observedContext)
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
    context.perform {
      XCTAssertFalse(Thread.isMainThread)
      let car = Car(context: context)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "1"
      car.maker = "123!"
    }
    waitForExpectations(timeout: 5)
  }

  func testObserveInsertChangeUsingBackgroundContextAndDispatchQueue() {
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let context = container.newBackgroundContext()
    let event = NSManagedObjectContext.ObservableEvents.didChange
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(context), event: event) { (change, event, observedContext) in
      XCTAssertFalse(Thread.isMainThread)
      XCTAssertTrue(context === observedContext)
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
      context.performAndWait {
        XCTAssertFalse(Thread.isMainThread)
        (1...100).forEach({ i in
          let car = Car(context: context)
          car.maker = "FIAT"
          car.model = "Panda"
          car.numberPlate = UUID().uuidString
          car.maker = "123!"
          let person = Person(context: context)
          person.firstName = UUID().uuidString
          person.lastName = UUID().uuidString
          car.owner = person
        })
        XCTAssertTrue(context.hasChanges, "The context should have uncommitted changes.")
        context.processPendingChanges()
      }
    }

    waitForExpectations(timeout: 5)
  }

  func testObserveInsertChangeUsingBackgroundContextWithoutChanges() {
    let expectation = self.expectation(description: "\(#function)\(#line)")
    expectation.isInverted = true
    let context = container.newBackgroundContext()
    let event = NSManagedObjectContext.ObservableEvents.didChange
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(context), event: event) { (change, event, observedContext) in
      // The context doesn't have any changes so the notifcation shouldn't be issued.
      print(change)
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    context.performAndWait {
      context.processPendingChanges()
    }
    waitForExpectations(timeout: 2)
  }

  func testObserveInsertChangeUsingPrivateContext() throws {
    let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    context.persistentStoreCoordinator = container.persistentStoreCoordinator
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
      context.processPendingChanges()
    }
    waitForExpectations(timeout: 5)
  }

  func testObserveInsertChangeUsingMainContext() throws {
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = container.persistentStoreCoordinator
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
      context.processPendingChanges()
    }
    waitForExpectations(timeout: 5)
  }

  func testObserveRefreshChangeRefresh() throws {
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

  func testObserveInsertWillSaveUsingViewContext() throws {
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

  func testObserveInsertWillSaveUsingDifferentContext() throws {
    let context = container.viewContext
    let expectation = self.expectation(description: "\(#function)\(#line)")
    expectation.isInverted = true
    let event = NSManagedObjectContext.ObservableEvents.willSave
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(context), event: event) { (change, event, observedContext) in
      // viewContext is observer, but the changes happen in another context
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    let backgroundContext = container.newBackgroundContext()
    try backgroundContext.performAndWait { ctx in
      let car = Car(context: ctx)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "1"
      car.maker = "123!"
      try backgroundContext.save()
    }

    waitForExpectations(timeout: 2)
  }

  func testObserveInsertSaveUsingViewContext() throws {
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
  func testObserveOnlyInsertChangeUsingBackgroundContextsAndAutomaticallyMergesChangesFromParent() throws {
    let context1 = container.newBackgroundContext()
    let context2 = container.newBackgroundContext()
    context2.automaticallyMergesChangesFromParent = true // This cause a change not a save, obviously

    // From Apple DTS:
    // Core Data triggers the didChange notification when the context is “indeed” changed, or the changes will have impact to you. Here is the logic:
    //  1. Merging new objects does change the context, so the notification is always triggered.
    //  2. Merging deleted objects changes the context when the deleted objects are in use (or in other word, are holded by your code).
    //  3. Merging updated objects changes the context when the updated objects are in use and not faulted.

    let expectation = self.expectation(description: "\(#function)\(#line)")
    let event = NSManagedObjectContext.ObservableEvents.didChange
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(context2), event: event) { (change, event, observedContext) in
      XCTAssertFalse(Thread.isMainThread)
      XCTAssertTrue(observedContext === context2)
      XCTAssertEqual(change.insertedObjects.count, 1)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertTrue(change.updatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation.fulfill()
    }
    _ = observer // remove unused warning...

    try context1.performSaveAndWait { context in
      let car = Car(context: context1)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "1"
      car.maker = "123!"
    }

    // no objects are used (kept and materialized by context2 so a delete change will not be triggered)
    try context1.performSaveAndWait { context in
      try Car.deleteAll(in: context)
    }

    waitForExpectations(timeout: 2)
  }

  func testObserveChangesUsingBackgroundContextsAndAutomaticallyMergesChangesFromParent() throws {
    let context0 = container.newBackgroundContext()
    context0.automaticallyMergesChangesFromParent = true // This cause a change not a save, obviously

    let context1 = container.newBackgroundContext()
    let context2 = container.newBackgroundContext()

    let expectation1 = self.expectation(description: "Changes on Contex1")
    let expectation2 = self.expectation(description: "Changes on Contex2")
    let expectation3 = self.expectation(description: "New Changes on Contex1")

    // From Apple DTS:
    // Core Data triggers the didChange notification when the context is “indeed” changed, or the changes will have impact to you. Here is the logic:
    //  1. Merging new objects does change the context, so the notification is always triggered.
    //  2. Merging deleted objects changes the context when the deleted objects are in use (or in other word, are holded by your code).
    //  3. Merging updated objects changes the context when the updated objects are in use and not faulted.

    let event = NSManagedObjectContext.ObservableEvents.didChange
    var count = 0
    let lock = NSLock()
    var holds = Set<NSManagedObject>()
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(context0), event: event) { (change, event, observedContext) in
      lock.lock()
      defer { lock.unlock() }

      XCTAssertTrue(observedContext === context0)

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
        XCTAssertTrue(observedContext === context0)
        XCTAssertEqual(change.updatedObjects.count, 1)
        count += 1
        expectation3.fulfill()
      default:
        XCTFail("Unexpected change.")
      }
    }
    _ = observer // remove unused warning...

    let numberPlate = "123!"
    try context1.performSaveAndWait { context in
      let car = Car(context: context)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = numberPlate
    }

    wait(for: [expectation1], timeout: 5)

    try context2.performSaveAndWait { context in
      let cars = try Car.fetch(in: context)
      guard let car = try Car.findUniqueOrFetch(in: context, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), numberPlate)) else {
        XCTFail("Car not found")
        return
      }
      car.model = "**Panda**"
    }

    wait(for: [expectation2], timeout: 5)

    try context0.performSaveAndWait { context in
      guard let car = try Car.findUniqueOrFetch(in: context, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), numberPlate)) else {
        XCTFail("Car not found")
        return
      }
      car.maker = "**FIAT**"
    }

    wait(for: [expectation3], timeout: 5)
  }

  func testObserveChangesOnCurrentlyUsedObjectsUsingBackgroundContextsAndAutomaticallyMergesChangesFromParent() throws {
    let context1 = container.newBackgroundContext()
    let context2 = container.newBackgroundContext()

    // 10 Pandas are created on context2
    try context2.performSaveAndWait { context in
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
    //  2. Merging deleted objects changes the context when the deleted objects are in use (or in other word, are holded by your code).
    //  3. Merging updated objects changes the context when the updated objects are in use and not faulted.

    let context0 = container.viewContext
    context0.automaticallyMergesChangesFromParent = true // This cause a change not a save, obviously

    // We fetch and materialize only 2 Pandas: changes are expected only when they impact these two cars.
    let fetch = Car.newFetchRequest()
    fetch.predicate = NSPredicate(format: "%K IN %@", #keyPath(Car.numberPlate), ["1", "2"] )
    let cars = try context0.fetch(fetch)
    cars.forEach { $0.willAccessValue(forKey: nil) }
    XCTAssertEqual(cars.count, 2)

    let expectation1 = self.expectation(description: "")



    let event = NSManagedObjectContext.ObservableEvents.didChange

    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(context0), event: event) { (change, event, observedContext) in
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
    try context2.performSaveAndWait { context in
      let cars = try Car.fetch(in: context)
      guard let car = try Car.findUniqueOrFetch(in: context, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), "3")) else {
        XCTFail("Car not found")
        return
      }
      car.model = "**Panda**"
    }

    // car with n. 6, doesn't impact the didChange because it's not materialized in context0
    try context1.performSaveAndWait { context in
      let cars = try Car.fetch(in: context)
      guard let car = try Car.findUniqueOrFetch(in: context, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), "6")) else {
        XCTFail("Car not found")
        return
      }
      car.delete()
    }

    // car with n. 2, impact the didChange because it's materialized in context0
    try context2.performSaveAndWait { context in
      let cars = try Car.fetch(in: context)
      guard let car = try Car.findUniqueOrFetch(in: context, where: NSPredicate(format: "%K == %@", #keyPath(Car.numberPlate), "2")) else {
        XCTFail("Car not found")
        return
      }
      car.model = "**Panda**"
    }

    waitForExpectations(timeout: 5)
  }

  func testObserveInsertUpdateAndDeleteSaveUsingViewContext() throws {
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
    let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
    let storeURL = urls.last!.appendingPathComponent("\(UUID().uuidString).sqlite")
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

    try parentContext.performAndWait { context in
      try context.save() // triggers the didSave event
    }

    waitForExpectations(timeout: 10)

    try FileManager.default.removeItem(at: storeURL)
  }

  //  func testObserveMultipleChangesUsingPersistentStoreCoordinatorWithChildAndParentContexts2() throws {
  //    // Given
  //    let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
  //    let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
  //    let storeURL = urls.last!.appendingPathComponent("\(UUID().uuidString).sqlite")
  //    try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
  //
  //    let parentContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
  //    parentContext.persistentStoreCoordinator = psc
  //
  //    let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
  //    childContext.parent = parentContext
  //
  //    let numberPlate = UUID().uuidString
  //    try childContext.performSaveAndWait { context in
  //      let car1 = Car(context: context)
  //      car1.maker = "FIAT"
  //      car1.model = "Qubo"
  //      car1.numberPlate = numberPlate
  //    }
  //
  //    parentContext.refreshAllObjects()
  //
  //    let expectation = self.expectation(description: "\(#function)\(#line)")
  //
  //    // Changes are propagated from the child to the parent during the save.
  //
  //    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(parentContext), event: .didChange) { (change, event, observedContext) in
  //      XCTAssertTrue(Thread.isMainThread)
  //      expectation.fulfill()
  //    }
  //
  //    // remove unused warning...
  //    _ = observer
  //
  //    try childContext.performSaveAndWait { context in
  //      guard let car1 = try Car.findUniqueOrFetch(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", numberPlate)) else {
  //        XCTFail("Car not found.")
  //        return
  //      }
  //      car1.model = "**Qubo**"
  //    }
  //
  //    waitForExpectations(timeout: 10)
  //
  //    try FileManager.default.removeItem(at: storeURL)
  //  }

  func testObserveDeleteSaveUsingWrongObserverContext() throws {
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
