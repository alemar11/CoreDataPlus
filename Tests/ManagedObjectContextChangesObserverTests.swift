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

  // MARK: - DidChange Events

  func testObserveInsertChangeUsingViewContext() {
    let context = container.viewContext
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let event = ManagedObjectContextObservedEvent.didChange
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
    let event = ManagedObjectContextObservedEvent.didChange
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
    let event = ManagedObjectContextObservedEvent.didChange
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
    let event = ManagedObjectContextObservedEvent.didChange
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
    let event = ManagedObjectContextObservedEvent.didChange
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
    let event = ManagedObjectContextObservedEvent.didChange
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
    let event = ManagedObjectContextObservedEvent.didChange
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
    let event = ManagedObjectContextObservedEvent.didChange
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
    let event = ManagedObjectContextObservedEvent.didChange
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
    let event = ManagedObjectContextObservedEvent.didChange
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
    let event = ManagedObjectContextObservedEvent.willSave
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
    let event = ManagedObjectContextObservedEvent.willSave
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
    let event = ManagedObjectContextObservedEvent.didSave
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

}
