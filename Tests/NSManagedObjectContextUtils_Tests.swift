// CoreDataPlus

import CoreData
import XCTest

@testable import CoreDataPlus

final class NSManagedObjectContextUtils_Tests: InMemoryTestCase {
  func test_HasPersistentChanges() throws {
    let viewContext = container.viewContext
    XCTAssertFalse(viewContext.hasPersistentChanges)
    let car = Car(context: viewContext)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = UUID().uuidString
    car.currentDrivingSpeed = 50

    XCTAssertTrue(viewContext.hasPersistentChanges)
    XCTAssertEqual(viewContext.persistentChangesCount, 1)
    try viewContext.save()
    XCTAssertFalse(viewContext.hasPersistentChanges)
    XCTAssertEqual(car.currentDrivingSpeed, 50)
    car.currentDrivingSpeed = 10
    XCTAssertTrue(car.hasChanges)
    XCTAssertFalse(car.hasPersistentChangedValues)
    XCTAssertEqual(viewContext.persistentChangesCount, 0)
    XCTAssertEqual(viewContext.changesCount, 1)
    XCTAssertFalse(
      viewContext.hasPersistentChanges,
      "viewContext shouldn't have committable changes because only transients properties are changed.")
  }

  func test_HasPersistentChangesInParentChildContextRelationship() throws {
    let viewContext = container.viewContext
    let backgroundContext = viewContext.newBackgroundContext(asChildContext: true)

    backgroundContext.performAndWait {
      XCTAssertFalse(backgroundContext.hasPersistentChanges)
      XCTAssertEqual(backgroundContext.persistentChangesCount, 0)
      XCTAssertEqual(backgroundContext.changesCount, 0)
      XCTAssertEqual(viewContext.persistentChangesCount, 0)
      XCTAssertEqual(viewContext.changesCount, 0)
      let car = Car(context: backgroundContext)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = UUID().uuidString
      XCTAssertTrue(backgroundContext.hasPersistentChanges)
      XCTAssertEqual(backgroundContext.persistentChangesCount, 1)
      XCTAssertEqual(backgroundContext.changesCount, 1)

      try! backgroundContext.save()

      XCTAssertFalse(backgroundContext.hasPersistentChanges)
      XCTAssertEqual(backgroundContext.persistentChangesCount, 0)
      XCTAssertEqual(car.currentDrivingSpeed, 0)
      car.currentDrivingSpeed = 50
      XCTAssertTrue(car.hasChanges)
      XCTAssertFalse(car.hasPersistentChangedValues)
      XCTAssertFalse(backgroundContext.hasPersistentChanges)
      XCTAssertEqual(backgroundContext.persistentChangesCount, 0)
      XCTAssertEqual(backgroundContext.changesCount, 1)

      try! backgroundContext.save()  // pushing the transient value up to the parent context
    }

    let car = try XCTUnwrap(try Car.fetchOneObject(in: viewContext, where: NSPredicate(value: true)))
    XCTAssertEqual(car.currentDrivingSpeed, 50)
    XCTAssertTrue(viewContext.hasChanges, "The viewContext should have uncommitted changes after the child save.")
    XCTAssertTrue(
      viewContext.hasPersistentChanges, "The viewContext should have uncommitted changes after the child save.")
    XCTAssertEqual(viewContext.persistentChangesCount, 1)
    XCTAssertEqual(viewContext.changesCount, 1)
    try viewContext.save()

    backgroundContext.performAndWait {
      do {
        let car = try XCTUnwrap(try Car.fetchOneObject(in: backgroundContext, where: NSPredicate(value: true)))
        XCTAssertEqual(car.currentDrivingSpeed, 0)
        car.currentDrivingSpeed = 30
        XCTAssertTrue(backgroundContext.hasChanges)
        XCTAssertFalse(
          backgroundContext.hasPersistentChanges,
          "backgroundContext shouldn't have committable changes because only transients properties are changed.")
        XCTAssertEqual(backgroundContext.persistentChangesCount, 0)
        XCTAssertEqual(backgroundContext.changesCount, 1)
        try backgroundContext.save()
      } catch let error as NSError {
        XCTFail(error.description)
      }
    }

    XCTAssertTrue(viewContext.hasChanges, "The transient property has changed")
    XCTAssertEqual(car.currentDrivingSpeed, 30)
    XCTAssertFalse(
      viewContext.hasPersistentChanges,
      "viewContext shouldn't have committable changes because only transients properties are changed.")
    XCTAssertEqual(viewContext.persistentChangesCount, 0)
    XCTAssertEqual(viewContext.changesCount, 1)
  }

  func test_NewBackgroundContext() {
    let backgroundContext = container.viewContext.newBackgroundContext(asChildContext: true)
    XCTAssertEqual(backgroundContext.concurrencyType, .privateQueueConcurrencyType)
    XCTAssertEqual(backgroundContext.parent, container.viewContext)

    let backgroundContext2 = container.viewContext.newBackgroundContext()
    XCTAssertEqual(backgroundContext2.concurrencyType, .privateQueueConcurrencyType)
    XCTAssertNotEqual(backgroundContext2.parent, container.viewContext)
  }

  func test_NewChildContext() {
    let childContext = container.viewContext.newChildContext()
    XCTAssertEqual(childContext.concurrencyType, container.viewContext.concurrencyType)
    XCTAssertTrue(childContext.parent === container.viewContext)
    let childContext2 = container.viewContext.newChildContext(concurrencyType: .privateQueueConcurrencyType)
    XCTAssertNotEqual(childContext2.concurrencyType, container.viewContext.concurrencyType)
    XCTAssertTrue(childContext2.parent === container.viewContext)
  }

  func test_PerformAndWait() throws {

    let context = container.viewContext
    context.fillWithSampleData()

    let cars = try context.performAndWait { (_context) -> [Car] in
      XCTAssertTrue(_context === context)
      return try Car.fetchObjects(in: _context)
    }

    XCTAssertFalse(cars.isEmpty)
  }

  @MainActor
  func test_PerformAndWaitWithThrow() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let context = container.viewContext
    context.fillWithSampleData()

    do {
      _ = try context.performAndWait { (_context) -> [Car] in
        XCTAssertTrue(_context === context)
        throw NSError(domain: "test", code: 1, userInfo: nil)
      }
    } catch let catchedError {
      XCTAssertNotNil(catchedError)
      if let nsError = catchedError as NSError? {
        XCTAssertEqual(nsError.code, 1)
        XCTAssertEqual(nsError.domain, "test")
      } else {
        XCTFail("Wrong error type.")
      }

      expectation1.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  func test_SaveIfNeededOrRollback() {
    let context = container.viewContext

    let car1 = Car(context: context)
    car1.maker = "FIAT"
    car1.model = "Panda"
    car1.numberPlate = "1"

    let person1 = Person(context: context)
    person1.firstName = "Tin"
    person1.lastName = "Robots"

    person1.cars = [car1]

    XCTAssertNoThrow(try context.saveIfNeededOrRollBack())

    XCTAssertEqual(context.registeredObjects.count, 2)  // person1 and car1 with a circular reference cycle

    let person2 = Person(context: context)
    person2.firstName = "Tin"
    person2.lastName = "Robots"
    person2.cars = nil

    XCTAssertEqual(context.registeredObjects.count, 3)

    XCTAssertThrowsError(try context.saveIfNeededOrRollBack())

    XCTAssertEqual(context.registeredObjects.count, 2)  // person2 is discarded because it cannot be saved
  }

  func test_CollectionDelete() throws {
    let context = container.viewContext
    let newContext = context.newBackgroundContext()

    let car1 = Car(context: context)
    car1.maker = "FIAT"
    car1.model = "Panda"
    car1.numberPlate = "1"

    let person1 = Person(context: context)
    person1.firstName = "Tin"
    person1.lastName = "Robots"

    /// This code will output: CoreData: error: CoreData: error: Failed to call designated initializer on NSManagedObject class 'Person'
    /// but it is fine for this test.
    let person2 = Person()
    person1.firstName = "Tin2"
    person1.lastName = "Robots2"

    let person3 = newContext.performAndWait { context -> Person in
      let person3 = Person(context: context)
      person3.firstName = "Tin"
      person3.lastName = "Robots"
      return person3
    }

    let list = [car1, person1, person2, person3]
    list.deleteManagedObjects()

    for mo in list {
      mo.managedObjectContext?.performAndWait {
        if mo === person2 {
          XCTAssertNil(mo.managedObjectContext)
        } else {
          XCTAssertTrue(mo.isDeleted)
        }
      }
    }
  }
}
