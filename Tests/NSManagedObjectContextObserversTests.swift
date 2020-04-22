//
// CoreDataPlus
//
// Copyright © 2016-2020 Tinrobots.
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

// Readings:
// http://mikeabdullah.net/merging-saved-changes-betwe.html
// http://www.mlsite.net/blog/?p=518

import XCTest
import CoreData
@testable import CoreDataPlus

final class NSManagedObjectContextObserversTests: CoreDataPlusInMemoryTestCase {
  /// This is a very generic test case
  func testObservers() throws {
    let context = container.viewContext

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")

    let notificationCenter = NotificationCenter.default

    let token1 = context.addManagedObjectContextWillSaveNotificationObserver() { notification in
      expectation1.fulfill()
    }

    let token2 = context.addManagedObjectContextDidSaveNotificationObserver() { notification in
      if #available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *) {
        XCTAssertNil(notification.historyToken) // nil token for in memory db
      }
      expectation2.fulfill()
    }

    let token3 = context.addManagedObjectContextObjectsDidChangeNotificationObserver() { notification in
      expectation3.fulfill()
    }

    context.fillWithSampleData()
    try context.save()

    waitForExpectations(timeout: 2)
    XCTAssertFalse(context.hasChanges)

    notificationCenter.removeObserver(token1)
    notificationCenter.removeObserver(token2)
    notificationCenter.removeObserver(token3)
  }

  func testInvalidatedAllObjects() throws {
    let context = container.newBackgroundContext()
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let notificationCenter = NotificationCenter.default

    let token1 = context.addManagedObjectContextObjectsDidChangeNotificationObserver() { notification in
      XCTAssertTrue(!notification.invalidatedAllObjects.isEmpty)
      XCTAssertEqual(notification.invalidatedAllObjects.count, 2)
      XCTAssertEqual(notification.invalidatedObjects.count, 0)
      expectation1.fulfill()
    }

    context.performAndWait {
      let person1_inserted: Person = Person(context: context)
      person1_inserted.firstName = "Edythe"
      person1_inserted.lastName = "Moreton"

      let person2_inserted = Person(context: context)
      person2_inserted.firstName = "Ellis"
      person2_inserted.lastName = "Khoury"

      context.reset()
    }

    waitForExpectations(timeout: 2)
    context.performAndWait {
      XCTAssertFalse(context.hasChanges)
    }

    notificationCenter.removeObserver(token1)
  }

  func testObserversWithoutSaving() throws {
    let context = container.viewContext

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")

    expectation1.isInverted = true
    expectation2.isInverted = true

    let notificationCenter = NotificationCenter.default

    let token1 = context.addManagedObjectContextWillSaveNotificationObserver() { notification in
      expectation1.fulfill()
    }

    let token2 = context.addManagedObjectContextDidSaveNotificationObserver() { notification in
      expectation2.fulfill()
    }

    let token3 = context.addManagedObjectContextObjectsDidChangeNotificationObserver() { notification in
      expectation3.fulfill()
    }

    context.fillWithSampleData()

    waitForExpectations(timeout: 2)
    XCTAssertTrue(context.hasChanges)

    notificationCenter.removeObserver(token1)
    notificationCenter.removeObserver(token2)
    notificationCenter.removeObserver(token3)
  }

  func testObserversWhenWorkingOnAnotherContext() throws {
    let context = container.viewContext
    let anotherContext = container.viewContext.newBackgroundContext(asChildContext: false)

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")

    expectation1.isInverted = true
    expectation2.isInverted = true
    expectation3.isInverted = true

    let notificationCenter = NotificationCenter.default

    let token1 = context.addManagedObjectContextWillSaveNotificationObserver() { notification in
      expectation1.fulfill()
    }

    let token2 = context.addManagedObjectContextDidSaveNotificationObserver() { notification in
      expectation2.fulfill()
    }

    let token3 = context.addManagedObjectContextObjectsDidChangeNotificationObserver() { notification in
      expectation3.fulfill()
    }

    try anotherContext.performSaveAndWait {
      $0.fillWithSampleData()
    }

    waitForExpectations(timeout: 2)

    XCTAssertFalse(context.hasChanges)
    anotherContext.performAndWait {
      XCTAssertFalse(anotherContext.hasChanges)
    }

    notificationCenter.removeObserver(token1)
    notificationCenter.removeObserver(token2)
    notificationCenter.removeObserver(token3)
  }

  func testObserversWhenWorkingWithChildContext() throws {
    let context = container.viewContext
    let anotherContext = container.viewContext.newBackgroundContext(asChildContext: true)

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")

    expectation1.isInverted = true
    expectation2.isInverted = true

    let notificationCenter = NotificationCenter.default

    let token1 = context.addManagedObjectContextWillSaveNotificationObserver() { notification in
      expectation1.fulfill()
    }

    let token2 = context.addManagedObjectContextDidSaveNotificationObserver() { notification in
      expectation2.fulfill()
    }

    let token3 = context.addManagedObjectContextObjectsDidChangeNotificationObserver() { notification in
      expectation3.fulfill()
    }

    try anotherContext.performSaveAndWait {
      $0.fillWithSampleData()
    }

    waitForExpectations(timeout: 2)
    XCTAssertTrue(context.hasChanges) // dirtied by the parent-child relationship
    anotherContext.performAndWait {
      XCTAssertFalse(anotherContext.hasChanges)
    }

    notificationCenter.removeObserver(token1)
    notificationCenter.removeObserver(token2)
    notificationCenter.removeObserver(token3)
  }

  func testObserverEvaluatingChangedObjects() throws {
    let context = container.viewContext

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let notificationCenter = NotificationCenter.default

    // Add and save some data in the context

    /// Elements to be deleted: 1 Person + 1 Car
    let person1_deleted = Person(context: context)
    person1_deleted.firstName = "Alessandro"
    person1_deleted.lastName = "Marzoli "

    let car1_deleted = Car(context: context)
    car1_deleted.maker = "Alfa Romeo"
    car1_deleted.model = "Giulietta"
    car1_deleted.numberPlate = "00011"

    person1_deleted._cars = Set([car1_deleted])

    /// Elements to be updated: 3 Person + 1 Car
    let person1_updated = Person(context: context)
    person1_updated.firstName = "Andrea"
    person1_updated.lastName = "Marzoli"

    let person2_updated = Person(context: context)
    person2_updated.firstName = "Valdemaro"
    person2_updated.lastName = "Marzoli"

    let person3_updated = Person(context: context)
    person3_updated.firstName = "Primetto"
    person3_updated.lastName = "Marzoli"

    let car1_updated = Car(context: context)
    car1_updated.maker = "Alfa Romeo"
    car1_updated.model = "Giulia"
    car1_updated.numberPlate = "000"

    person1_updated._cars = Set([car1_updated])

    /// Elements to be refreshed: 1 Person
    let person1_refreshed = Person(context: context)
    person1_updated.firstName = "Tin"
    person1_updated.lastName = "Robots"

    try context.save()

    var deletedObjects = 0
    var insertedObjects = 0
    var updatedObjects = 0
    var refreshedObjects = 0
    var invalidatedObjects = 0
    var invalidatedAllObjects = 0

    var didSaveDeletedObjects = 0
    var didSaveInsertedObjects = 0
    var didSaveUpdatedObjects = 0

    let token1 = context.addManagedObjectContextWillSaveNotificationObserver() { notification in
      XCTAssertEqual(notification.managedObjectContext, context)
      expectation1.fulfill()
    }

    let token2 = context.addManagedObjectContextDidSaveNotificationObserver() { notification in
      XCTAssertEqual(notification.managedObjectContext, context)

      debugPrint(notification)

      didSaveDeletedObjects += notification.deletedObjects.count
      didSaveInsertedObjects += notification.insertedObjects.count
      didSaveUpdatedObjects += notification.updatedObjects.count

    }

    let token3 = context.addManagedObjectContextObjectsDidChangeNotificationObserver() { notification in
      XCTAssertEqual(notification.managedObjectContext, context)

      debugPrint(notification)

      deletedObjects += notification.deletedObjects.count
      insertedObjects += notification.insertedObjects.count
      updatedObjects += notification.updatedObjects.count
      refreshedObjects += notification.refreshedObjects.count
      invalidatedObjects += notification.invalidatedObjects.count
      invalidatedAllObjects += notification.invalidatedAllObjects.count
    }

    let person1_inserted = Person(context: context)
    person1_inserted.firstName = "Edythe"
    person1_inserted.lastName = "Moreton"

    let person2_inserted = Person(context: context)
    person2_inserted.firstName = "Ellis"
    person2_inserted.lastName = "Khoury"

    let person3_inserted = Person(context: context)
    person3_inserted.firstName = "Faron"
    person3_inserted.lastName = "Moreton"

    let car1_inserted = Car(context: context)
    car1_inserted.maker = "Alfa Romeo"
    car1_inserted.model = "Giulietta"
    car1_inserted.numberPlate = "4"

    let car2_inserted = ExpensiveSportCar(context: context)
    car2_inserted.maker = "McLaren"
    car2_inserted.model = "570GT"
    car2_inserted.numberPlate = "303"
    car2_inserted.isLimitedEdition = false

    let car3_inserted = ExpensiveSportCar(context: context)
    car3_inserted.maker = "Lamborghini"
    car3_inserted.model = "Aventador LP750-4"
    car3_inserted.numberPlate = "304"
    car3_inserted.isLimitedEdition = false

    let car4_inserted = Car(context: context)
    car4_inserted.maker = "Renault"
    car4_inserted.model = "Clio"
    car4_inserted.numberPlate = "14"

    let car5_inserted = Car(context: context)
    car5_inserted.maker = "Renault"
    car5_inserted.model = "Megane"
    car5_inserted.numberPlate = "15"

    let car6_inserted = SportCar(context: context)
    car6_inserted.maker = "BMW"
    car6_inserted.model = "M6 Coupe"
    car6_inserted.numberPlate = "200"

    person1_inserted._cars = Set([car1_inserted])
    person2_inserted._cars = Set([car2_inserted, car3_inserted])
    person3_inserted._cars = Set([car4_inserted, car5_inserted, car6_inserted])

    context.delete(person1_deleted)
    context.delete(car1_deleted)

    person1_updated.firstName += " Updated"
    person2_updated.firstName += " Updated"
    person3_updated.firstName += " Updated"
    car1_updated.numberPlate! += " Updated"

    person1_refreshed.refresh()

    try context.save()

    XCTAssertEqual(deletedObjects, 2)
    XCTAssertEqual(insertedObjects, 9)
    XCTAssertEqual(updatedObjects, 4)
    XCTAssertEqual(refreshedObjects, 1)
    XCTAssertEqual(invalidatedObjects, 0)
    XCTAssertEqual(invalidatedAllObjects, 0)
    XCTAssertEqual(didSaveDeletedObjects, 2)
    XCTAssertEqual(didSaveInsertedObjects, 9)
    XCTAssertEqual(didSaveUpdatedObjects, 4)

    waitForExpectations(timeout: 2)

    notificationCenter.removeObserver(token1)
    notificationCenter.removeObserver(token2)
    notificationCenter.removeObserver(token3)
  }

  func testInvestigationRegisteredObjects() throws {
    // By default, a managed object context only keeps a strong reference to managed objects that have pending changes.
    // This means that objects your code doesn’t have a strong reference to, will be removed from the context’s registeredObjects set and be deallocated
    let viewContext = container.viewContext

    viewContext.performAndWait {
      let person = Person(context: viewContext)
      person.firstName = "One"
      person.lastName = "One"
    }

    XCTAssertEqual(viewContext.registeredObjects.count, 1)
    XCTAssertEqual(viewContext.insertedObjects.count, 1)
    try! viewContext.save()
    XCTAssertEqual(viewContext.insertedObjects.count, 0)
    XCTAssertEqual(viewContext.registeredObjects.count, 1)

    viewContext.performAndWait {
      let person = Person(context: viewContext)
      person.firstName = "Two"
      person.lastName = "Two"
      XCTAssertEqual(viewContext.registeredObjects.count, 2)
      XCTAssertEqual(viewContext.insertedObjects.count, 1)
      try! viewContext.save()
      XCTAssertEqual(viewContext.insertedObjects.count, 0)
      XCTAssertEqual(viewContext.registeredObjects.count, 2)
      // no more pending changes when we exit from this block, the registered objects will be back to the first person only
    }

    XCTAssertEqual(viewContext.registeredObjects.count, 1)
    try! viewContext.save()
    XCTAssertEqual(viewContext.registeredObjects.count, 1)
    let registeredPerson = viewContext.registeredObjects.first as? Person
    XCTAssertEqual(registeredPerson?.firstName, "One")
    XCTAssertEqual(registeredPerson?.lastName, "One")

    let people = try Person.fetch(in: viewContext)
    XCTAssertEqual(people.count, 2)
    XCTAssertEqual(viewContext.registeredObjects.count, 2)
  }

  func testInvestigationMergeChanges() throws {
    // see: testInvesigationRegisteredObjects
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let viewContext = container.viewContext

    let person = Person(context: viewContext)
    person.firstName = "Alessandro"
    person.lastName = "Marzoli"
    let person2 = Person(context: viewContext)
    person2.firstName = "Andrea"
    person2.lastName = "Marzoli"
    XCTAssertEqual(viewContext.registeredObjects.count, 2)
    try! viewContext.save()

    XCTAssertEqual(viewContext.registeredObjects.count, 2)

    func findRegisteredPersonByFirstName(_ name: String, in context: NSManagedObjectContext) -> Person? {
      var person: Person?
      context.performAndWait {
        person = context.registeredObjects.first { object in
          if let person = object as? Person {
            return person.firstName == name
          }
          return false
          } as? Person
      }
      return person
    }

    let backgroundContext = container.viewContext.newBackgroundContext(asChildContext: false)
    let token1 = backgroundContext.addManagedObjectContextDidSaveNotificationObserver() { notification in
      XCTAssertEqual(notification.insertedObjects.count, 1)
      XCTAssertEqual(notification.updatedObjects.count, 1)
      XCTAssertEqual(notification.deletedObjects.count, 1)

      XCTAssertEqual(viewContext.registeredObjects.count, 2)
      XCTAssertEqual(viewContext.deletedObjects.count, 0)

      let updatedPersonBefore = findRegisteredPersonByFirstName("Andrea", in: viewContext)
      XCTAssertNotNil(updatedPersonBefore)

      viewContext.mergeChanges(fromContextDidSave: notification.notification)

      let updatedPersonAfter =  findRegisteredPersonByFirstName("Andrea", in: viewContext)
      XCTAssertNil(updatedPersonAfter)
      let updatedPersonAfterCorrect =  findRegisteredPersonByFirstName("Andrea**", in: viewContext)
      XCTAssertNotNil(updatedPersonAfterCorrect)

      XCTAssertEqual(viewContext.registeredObjects.count, 2)
      XCTAssertEqual(viewContext.insertedObjects.count, 0)  // no objects have been inserted (but not yet saved) in this context
      XCTAssertEqual(viewContext.deletedObjects.count, 1)   // a previously registered object has been deleted from this context
      expectation1.fulfill()
    }

    try backgroundContext.performSaveAndWait {
      try Person.deleteAll(in: $0, where: NSPredicate(format: "%K == %@", #keyPath(Person.firstName), "Alessandro"))
      let person = Person(context: $0)
      person.firstName = "Edythe"
      person.lastName = "Moreton"

      let person2 = backgroundContext.object(with: person2.objectID) as! Person
      person2.firstName += "**"
    }

    self.waitForExpectations(timeout: 2)
    NotificationCenter.default.removeObserver(token1)
    //NotificationCenter.default.removeObserver(token2)
  }

  func testMerge() throws {
    let viewContext = container.viewContext
    let backgroundContext = container.viewContext.newBackgroundContext(asChildContext: false)

    let person1_inserted = Person(context: viewContext)
    person1_inserted.firstName = "Edythe"
    person1_inserted.lastName = "Moreton"

    let person2_inserted = Person(context: viewContext)
    person2_inserted.firstName = "Ellis"
    person2_inserted.lastName = "Khoury"

    try viewContext.save()

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    let expectation5 = expectation(description: "\(#function)\(#line)")

    let notificationCenter = NotificationCenter.default

    // [4] observer
    let token1 = backgroundContext.addManagedObjectContextWillSaveNotificationObserver() { notification in
      expectation1.fulfill()
    }

    // [1] observer
    let token2 = backgroundContext.addManagedObjectContextDidSaveNotificationObserver() { notification in
      XCTAssertEqual(notification.updatedObjects.count, 2)
      XCTAssertEqual(notification.insertedObjects.count, 1)

      // Merging a did-save notification into a context will:
      // - refresh the registered objects that have been changed,
      // - remove the ones that have been deleted
      // - fault in the ones that have been newly inserted.
      // Then the context you’re merging into will send its own objects-did-change notification containing all the changes to the context’s objects:”.

      // In this case:
      // merging "backgroundContext" changes into the "viewContext" will:
      // show "backgroundContext" updatedObjects as NSRefreshedObjectsKey changes in the "viewContext" objects-did-change notification
      // show "backgroundContext" insertedObjects as NSInsertedObjectsKey changes in the "viewContext" objects-did-change notification
      viewContext.performAndWaitMergeChanges(from: notification) // fires [2]

      viewContext.performAndWait {
        // Before saving, we didn't change anything: we don't expect any changes in the  objects-did-save notification listened by [3] observer.
        // see: testInvesigationMergeChanges()
        try! viewContext.save() // fires [3]
      }
      expectation2.fulfill()
    }

    // [0] observer
    let token3 = backgroundContext.addManagedObjectContextObjectsDidChangeNotificationObserver() { notification in
      XCTAssertEqual(notification.updatedObjects.count, 2)
      XCTAssertEqual(notification.insertedObjects.count, 1)
      XCTAssertEqual(notification.refreshedObjects.count, 0)
      expectation3.fulfill()
    }

    // [2] observer
    let token4 = viewContext.addManagedObjectContextObjectsDidChangeNotificationObserver() { notification in
      // updates in "backgroundContext" are represented as refreshed objects in "viewContext",
      // inserts are represented as inserts in both contexts.
      XCTAssertEqual(notification.refreshedObjects.count, 2)
      XCTAssertEqual(notification.updatedObjects.count, 0)
      XCTAssertEqual(notification.insertedObjects.count, 1)
      expectation4.fulfill()
    }

    // [3] observer
    let token5 = viewContext.addManagedObjectContextDidSaveNotificationObserver() { notification in
      XCTAssertEqual(notification.insertedObjects.count, 0)
      XCTAssertEqual(notification.updatedObjects.count, 0)
      XCTAssertEqual(notification.deletedObjects.count, 0)
      expectation5.fulfill()
    }

    try backgroundContext.performAndWaitResult { _ in
      let persons = try Person.fetch(in: backgroundContext)

      for person in persons {
        person.firstName += " Updated"
      }

      let person3_inserted = Person(context: backgroundContext)
      person3_inserted.firstName = "Alessandro"
      person3_inserted.lastName = "Marzoli"

      try! backgroundContext.save() // fires [0], [4] and then [1]
    }

    waitForExpectations(timeout: 20)
    XCTAssertFalse(viewContext.hasChanges)

    try backgroundContext.performAndWaitResult { _ in
      XCTAssertFalse(backgroundContext.hasChanges)
      XCTAssertEqual(try Person.count(in: backgroundContext), 3)
    }

    notificationCenter.removeObserver(token1)
    notificationCenter.removeObserver(token2)
    notificationCenter.removeObserver(token3)
    notificationCenter.removeObserver(token4)
    notificationCenter.removeObserver(token5)
  }

  func testAsyncMerge() throws {
    let context = container.viewContext
    let anotherContext = container.viewContext.newBackgroundContext(asChildContext: false)

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")

    let notificationCenter = NotificationCenter.default

    let token1 = anotherContext.addManagedObjectContextWillSaveNotificationObserver() { notification in
      expectation1.fulfill()
    }

    let token2 = anotherContext.addManagedObjectContextDidSaveNotificationObserver() { notification in
      context.performMergeChanges(from: notification, completion: {
        expectation2.fulfill()
      })

    }

    let token3 = anotherContext.addManagedObjectContextObjectsDidChangeNotificationObserver() { notification in
      expectation3.fulfill()
    }

    let person1_inserted = Person(context: context)
    person1_inserted.firstName = "Edythe"
    person1_inserted.lastName = "Moreton"

    let person2_inserted = Person(context: context)
    person2_inserted.firstName = "Ellis"
    person2_inserted.lastName = "Khoury"

    try context.save()

    try anotherContext.performAndWaitResult {_ in
      let persons = try Person.fetch(in: anotherContext)

      for person in persons {
        person.firstName += " Updated"
      }

      let person3_inserted = Person(context: anotherContext)
      person3_inserted.firstName = "Alessandro"
      person3_inserted.lastName = "Marzoli"

      try anotherContext.save()
    }


    waitForExpectations(timeout: 2)
    XCTAssertFalse(context.hasChanges)
    try anotherContext.performAndWaitResult { _ in
      XCTAssertFalse(anotherContext.hasChanges)
      XCTAssertEqual(try Person.count(in: anotherContext), 3)
    }

    notificationCenter.removeObserver(token1)
    notificationCenter.removeObserver(token2)
    notificationCenter.removeObserver(token3)
  }

  func testNSFetchedResultController() throws {
    let context = container.viewContext

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    let person2 = Person(context: context)
    person2.firstName = "Ellis"
    person2.lastName = "Khoury"

    let car1 = Car(context: context)
    car1.maker = "Renault"
    car1.model = "Clio"
    car1.numberPlate = "14"

    try context.save()

    let request = Person.fetchRequest()
    // request.addSortDescriptors([NSSortDescriptor(key: "firstName", ascending: false)]) // with a descriptors the context will materialize all the Person objects
    request.addSortDescriptors([])

    let delegate = FetchedResultsControllerMockDelegate()
    let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    frc.delegate = delegate
    try frc.performFetch()

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let notificationCenter = NotificationCenter.default
    let anotherContext = container.viewContext.newBackgroundContext(asChildContext: false)

    let token1 = anotherContext.addManagedObjectContextDidSaveNotificationObserver() { notification in
      XCTAssertEqual(notification.insertedObjects.count, 2) // 1 person and 1 car
      XCTAssertEqual(notification.updatedObjects.count, 1) // 1 person

      context.performAndWaitMergeChanges(from: notification)
      expectation1.fulfill()
    }

    var person3ObjectId: NSManagedObjectID?

    try anotherContext.performAndWaitResult { _ in
      let persons = try Person.fetch(in: anotherContext)

      // Insert a new car object on anohterContext
      let car2 = SportCar(context: anotherContext)
      car2.maker = "BMW"
      car2.model = "M6 Coupe"
      car2.numberPlate = "200"

      // Insert a new person object on anohterContext
      let person3 = Person(context: anotherContext)
      person3.firstName = "Alessandro"
      person3.lastName = "Marzoli"

      // Update a faulted relationship
      let firstPerson = persons.filter { $0.firstName == person1.firstName }.first!
      firstPerson._cars = Set([car2])

      try anotherContext.save()
      person3ObjectId = person3.objectID
    }

    waitForExpectations(timeout: 5)

    XCTAssertEqual(delegate.updatedObjects.count + delegate.movedObjects.count, 1)
    XCTAssertEqual(delegate.insertedObjects.count, 1) // the FRC monitors only for Person objects

    XCTAssertEqual(context.registeredObjects.count, 4)

    let expectedIds = Set([person1.objectID, person2.objectID, person3ObjectId!, car1.objectID])
    let foundIds = Set(context.registeredObjects.compactMap { $0.objectID })

    XCTAssertEqual(expectedIds, foundIds)
    notificationCenter.removeObserver(token1)
  }

  func testNSFetchedResultControllerWithContextReset() throws {
    let context = container.viewContext

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    let person2 = Person(context: context)
    person2.firstName = "Ellis"
    person2.lastName = "Khoury"

    let car1 = Car(context: context)
    car1.maker = "Renault"
    car1.model = "Clio"
    car1.numberPlate = "14"

    try context.save()
    let request = Person.fetchRequest()
    request.addSortDescriptors([])

    let delegate = FetchedResultsControllerMockDelegate()
    let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    frc.delegate = delegate
    try frc.performFetch()

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let notificationCenter = NotificationCenter.default

    let token1 = context.addManagedObjectContextDidSaveNotificationObserver() { notification in
      XCTAssertEqual(notification.insertedObjects.count, 0)
      XCTAssertEqual(notification.updatedObjects.count, 0)
      XCTAssertEqual(notification.deletedObjects.count, 0)

      context.performAndWaitMergeChanges(from: notification)
      expectation1.fulfill()
    }

    let token2 = context.addManagedObjectContextObjectsDidChangeNotificationObserver { notification in
      XCTAssertFalse(notification.invalidatedAllObjects.isEmpty)
      expectation2.fulfill()
    }

    let persons = try Person.fetch(in: context)

    // Insert a new car object on anohterContext
    let car2 = SportCar(context: context)
    car2.maker = "BMW"
    car2.model = "M6 Coupe"
    car2.numberPlate = "200"

    // Insert a new person object on anohterContext
    let person3 = Person(context: context)
    person3.firstName = "Alessandro"
    person3.lastName = "Marzoli"

    // Update a faulted relationship
    let firstPerson = persons.filter { $0.firstName == person1.firstName }.first!
    firstPerson._cars = Set([car2])

    context.reset()
    try context.save() // the command will do nothing, the FRC delegate is exepcted to have 0 changed objects

    waitForExpectations(timeout: 5)

    XCTAssertEqual(delegate.updatedObjects.count, 0)
    XCTAssertEqual(delegate.deletedObjects.count, 0)
    XCTAssertEqual(delegate.insertedObjects.count, 0)
    XCTAssertEqual(delegate.movedObjects.count, 0)

    notificationCenter.removeObserver(token1)
    notificationCenter.removeObserver(token2)
  }

  /**
   NSFetchedResultsController: Handling Object Invalidation

   https://developer.apple.com/documentation/coredata/nsfetchedresultscontroller

   When a managed object context notifies the fetched results controller that individual objects are invalidated, the controller treats these as deleted objects and sends the proper delegate calls.

   It’s possible for all the objects in a managed object context to be invalidated simultaneously.
   (For example, as a result of calling reset(), or if a store is removed from the the persistent store coordinator.).
   When this happens, NSFetchedResultsController does not invalidate all objects, nor does it send individual notifications for object deletions.
   Instead, you must call performFetch() to reset the state of the controller then reload the data in the table view (reloadData()).
   **/
  class FetchedResultsControllerMockDelegate: NSObject, NSFetchedResultsControllerDelegate {
    var updatedObjects = [Any]()
    var insertedObjects = [Any]()
    var movedObjects = [Any]()
    var deletedObjects = [Any]()

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
      switch (type) {
      case .delete:
        deletedObjects.append(anObject)
      case .insert:
        insertedObjects.append(anObject)
      case .move:
        movedObjects.append(anObject)
      case .update:
        updatedObjects.append(anObject)
      @unknown default:
        fatalError("not implemented")
      }
    }
  }
}
