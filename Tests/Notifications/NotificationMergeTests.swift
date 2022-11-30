// CoreDataPlus
//
// Readings:
// http://mikeabdullah.net/merging-saved-changes-betwe.html
// http://www.mlsite.net/blog/?p=518

import XCTest
import CoreData
import Combine
@testable import CoreDataPlus

@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
final class NotificationMergeTests: InMemoryTestCase {
  func testInvestigationRegisteredObjects() throws {
    try XCTSkipIf(!ProcessInfo.processInfo.environment.keys.contains("XCODE_TESTS"), "This test should be run via Xcode and not using Swift test.")
    try XCTSkipIf(ProcessInfo.processInfo.arguments.contains("zombieObjectsEnabled"), "Testing with Zombie Objects enabled")

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

    let people = try Person.fetchObjects(in: viewContext)
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
    let cancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: backgroundContext)
      .map { ManagedObjectContextDidSaveObjects(notification: $0) }
      .sink { payload in
        XCTAssertEqual(payload.insertedObjects.count, 1)
        XCTAssertEqual(payload.updatedObjects.count, 1)
        XCTAssertEqual(payload.deletedObjects.count, 1)

        XCTAssertEqual(viewContext.registeredObjects.count, 2)
        XCTAssertEqual(viewContext.deletedObjects.count, 0)

        let updatedPersonBefore = findRegisteredPersonByFirstName("Andrea", in: viewContext)
        XCTAssertNotNil(updatedPersonBefore)

        viewContext.mergeChanges(fromContextDidSavePayload: payload)

        let updatedPersonAfter =  findRegisteredPersonByFirstName("Andrea", in: viewContext)
        XCTAssertNil(updatedPersonAfter)
        let updatedPersonAfterCorrect =  findRegisteredPersonByFirstName("Andrea**", in: viewContext)
        XCTAssertNotNil(updatedPersonAfterCorrect)

        XCTAssertEqual(viewContext.registeredObjects.count, 2)
        XCTAssertEqual(viewContext.insertedObjects.count, 0)  // no objects have been inserted (but not yet saved) in this context
        XCTAssertEqual(viewContext.deletedObjects.count, 1)   // a previously registered object has been deleted from this context
        expectation1.fulfill()
      }

    try backgroundContext.performAndWait {
      try Person.delete(in: $0, where: NSPredicate(format: "%K == %@", #keyPath(Person.firstName), "Alessandro"))
      let person = Person(context: $0)
      person.firstName = "Edythe"
      person.lastName = "Moreton"

      let person2 = try XCTUnwrap(Person.object(with: person2.objectID, in: backgroundContext))
      person2.firstName += "**"
      try backgroundContext.save()
    }

    self.waitForExpectations(timeout: 2)
    cancellable.cancel()

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

    var cancellables = [AnyCancellable]()

    if #available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *) {
      // [6] observer
      let expectation6 = self.expectation(description: "\(#function)\(#line)")
      NotificationCenter.default.publisher(for: .NSManagedObjectContextDidMergeChangesObjectIDs, object: viewContext)
        .map { ManagedObjectContextDidMergeChangesObjectIDs(notification: $0) }
        .sink { payload in
          XCTAssertTrue(payload.managedObjectContext === viewContext)
          XCTAssertEqual(payload.insertedObjectIDs.count, 1)
          XCTAssertEqual(payload.updatedObjectIDs.count, 2)
          XCTAssertTrue(payload.deletedObjectIDs.isEmpty)
          XCTAssertEqual(payload.refreshedObjectIDs.count, 2)
          expectation6.fulfill()
        }
        .store(in: &cancellables)
    }

    // [4] observer
    NotificationCenter.default.publisher(for: .NSManagedObjectContextWillSave, object: backgroundContext)
      .sink { _ in
        expectation1.fulfill()
      }
      .store(in: &cancellables)

    // [1] observer
    NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: backgroundContext)
      .map { ManagedObjectContextDidSaveObjects(notification: $0) }
      .sink { payload in
        XCTAssertEqual(payload.updatedObjects.count, 2)
        XCTAssertEqual(payload.insertedObjects.count, 1)

        // Merging a did-save notification into a context will:
        // - refresh the registered objects that have been changed,
        // - remove the ones that have been deleted
        // - fault in the ones that have been newly inserted.
        // Then the context you’re merging into will send its own objects-did-change notification containing all the changes to the context’s objects:”.

        // In this case:
        // merging "backgroundContext" changes into the "viewContext" will:
        // show "backgroundContext" updatedObjects as NSRefreshedObjectsKey changes in the "viewContext" objects-did-change notification
        // show "backgroundContext" insertedObjects as NSInsertedObjectsKey changes in the "viewContext" objects-did-change notification
        viewContext.mergeChanges(fromContextDidSavePayload: payload) // fires [2] [6]

        viewContext.performAndWait {
          // Before saving, we didn't change anything: we don't expect any changes in the objects-did-save notification listened by [3] observer.
          // see: testInvesigationMergeChanges()
          try! viewContext.save() // fires [3]
        }
        expectation2.fulfill()
      }
      .store(in: &cancellables)

    // [0] observer
    NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: backgroundContext)
      .map { ManagedObjectContextObjectsDidChange(notification: $0) }
      .sink { payload in
        XCTAssertEqual(payload.updatedObjects.count, 2)
        XCTAssertEqual(payload.insertedObjects.count, 1)
        XCTAssertEqual(payload.refreshedObjects.count, 0)
        expectation3.fulfill()
      }
      .store(in: &cancellables)

    // [2] observer
    NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewContext)
      .map { ManagedObjectContextObjectsDidChange(notification: $0) }
      .sink { payload in
        // updates in "backgroundContext" are represented as refreshed objects in "viewContext",
        // inserts are represented as inserts in both contexts.
        XCTAssertEqual(payload.refreshedObjects.count, 2)
        XCTAssertEqual(payload.updatedObjects.count, 0)
        XCTAssertEqual(payload.insertedObjects.count, 1)
        expectation4.fulfill()
      }
      .store(in: &cancellables)

    // [3] observer
    NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: viewContext)
      .map { ManagedObjectContextDidSaveObjects(notification: $0) }
      .sink { payload in
        XCTAssertEqual(payload.insertedObjects.count, 0)
        XCTAssertEqual(payload.updatedObjects.count, 0)
        XCTAssertEqual(payload.deletedObjects.count, 0)
        expectation5.fulfill()
      }
      .store(in: &cancellables)

    try backgroundContext.performAndWait { _ in
      let persons = try Person.fetchObjects(in: backgroundContext)

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

    try backgroundContext.performAndWait { _ in
      XCTAssertFalse(backgroundContext.hasChanges)
      XCTAssertEqual(try Person.count(in: backgroundContext), 3)
    }
  }

  func testAsyncMerge() throws {
    let context = container.viewContext
    let anotherContext = container.viewContext.newBackgroundContext(asChildContext: false)

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")

    let cancellable1 = NotificationCenter.default.publisher(for: .NSManagedObjectContextWillSave, object: anotherContext)
      .sink { _ in
        expectation1.fulfill()
      }

    let cancellable2 = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: anotherContext)
      .map { ManagedObjectContextDidSaveObjects(notification: $0) }
      .sink { payload in
        context.perform {
          context.mergeChanges(fromContextDidSavePayload: payload)
          expectation2.fulfill()
        }
      }

    let cancellable3 = NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: anotherContext)
      .sink { _ in
        expectation3.fulfill()
      }

    let person1_inserted = Person(context: context)
    person1_inserted.firstName = "Edythe"
    person1_inserted.lastName = "Moreton"

    let person2_inserted = Person(context: context)
    person2_inserted.firstName = "Ellis"
    person2_inserted.lastName = "Khoury"

    try context.save()

    try anotherContext.performAndWait {_ in
      let persons = try Person.fetchObjects(in: anotherContext)

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
    try anotherContext.performAndWait { _ in
      XCTAssertFalse(anotherContext.hasChanges)
      XCTAssertEqual(try Person.count(in: anotherContext), 3)
    }

    cancellable1.cancel()
    cancellable2.cancel()
    cancellable3.cancel()
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
    let anotherContext = container.viewContext.newBackgroundContext(asChildContext: false)

    let cancellable1 = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: anotherContext)
      .map { ManagedObjectContextDidSaveObjects(notification: $0) }
      .sink { payload in
        XCTAssertEqual(payload.insertedObjects.count, 2) // 1 person and 1 car
        XCTAssertEqual(payload.updatedObjects.count, 1) // 1 person
        context.perform {
          context.mergeChanges(fromContextDidSavePayload: payload)
          expectation1.fulfill()
        }
      }

    var person3ObjectId: NSManagedObjectID?

    try anotherContext.performAndWait { _ in
      let persons = try Person.fetchObjects(in: anotherContext)

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
    cancellable1.cancel()
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

    let cancellable1 = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: context)
      .map { ManagedObjectContextDidSaveObjects(notification: $0) }
      .sink { payload in
        XCTAssertEqual(payload.insertedObjects.count, 0)
        XCTAssertEqual(payload.updatedObjects.count, 0)
        XCTAssertEqual(payload.deletedObjects.count, 0)
        context.perform {
          context.mergeChanges(fromContextDidSavePayload: payload)
          expectation1.fulfill()
        }
      }

    let cancellable2 = NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
      .map { ManagedObjectContextObjectsDidChange(notification: $0) }
      .sink { payload in
        XCTAssertFalse(payload.invalidatedAllObjects.isEmpty)
        expectation2.fulfill()
      }

    let persons = try Person.fetchObjects(in: context)

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

    cancellable1.cancel()
    cancellable2.cancel()
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
