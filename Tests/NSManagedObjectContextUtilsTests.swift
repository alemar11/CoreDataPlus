//
// CoreDataPlus
//
//  Copyright © 2016-2020 Tinrobots.
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

final class NSManagedObjectContextUtilsTests: CoreDataPlusInMemoryTestCase {
  func testSinglePersistentStore() {
    XCTAssertTrue(container.viewContext.persistentStores.count == 1)
    XCTAssertNotNil(container.viewContext.persistentStores.first)
  }

  func testMissingPersistentStoreCoordinator() {
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    XCTAssertTrue(context.persistentStores.isEmpty)
  }

  func testMetaData() {
    // When
    guard let firstPersistentStore = container.viewContext.persistentStores.first else {
      XCTAssertNotNil(container.viewContext.persistentStores.first)
      return
    }
    // Then
    let metaData = container.viewContext.metaData(for: firstPersistentStore)
    XCTAssertNotNil((metaData["NSStoreModelVersionHashes"] as? [String: Any])?[Car.entityName])
    XCTAssertNotNil((metaData["NSStoreModelVersionHashes"] as? [String: Any])?[Person.entityName])
    XCTAssertNotNil(metaData["NSStoreType"] as? String)

    let addMetaDataExpectation = expectation(description: "Add MetaData Expectation")
    container.viewContext.setMetaDataObject("Test", with: "testKey", for: firstPersistentStore){ error in
      XCTAssertNil(error)
      addMetaDataExpectation.fulfill()
    }
    waitForExpectations(timeout: 5.0, handler: nil)

    let updatedMetaData = container.viewContext.metaData(for: firstPersistentStore)
    XCTAssertNotNil(updatedMetaData["testKey"])
    XCTAssertEqual(updatedMetaData["testKey"] as? String, "Test")
  }

  func testEntityDescription() {
    XCTAssertNotNil(container.viewContext.entity(forEntityName: Car.entityName))
    XCTAssertNotNil(container.viewContext.entity(forEntityName: Person.entityName))
    XCTAssertNil(container.viewContext.entity(forEntityName: "FakeEntity"))
  }

  func testNewBackgroundContext() {
    let backgroundContext = container.viewContext.newBackgroundContext(asChildContext: true)
    XCTAssertEqual(backgroundContext.concurrencyType,.privateQueueConcurrencyType)
    XCTAssertEqual(backgroundContext.parent,container.viewContext)

    let backgroundContext2 = container.viewContext.newBackgroundContext()
    XCTAssertEqual(backgroundContext2.concurrencyType,.privateQueueConcurrencyType)
    XCTAssertNotEqual(backgroundContext2.parent,container.viewContext)
  }

  func testMultipleSaveAndWait() throws {
    // Given, When
    let context = container.viewContext.newBackgroundContext()

    // Then
    XCTAssertNoThrow(
      try context.performSaveAndWait { context in
        let person = Person(context: context)
        person.firstName = "T"
        person.lastName = "R"

        let person2 = Person(context: context)
        person2.firstName = "T2"
        person2.lastName = "R2"

        let car3 = Car(context: context)
        car3.maker = "FIAT"
        car3.model = "Punto"
        car3.numberPlate = "3"

        person2.cars = [car3]

        XCTAssertEqual(context.registeredObjects.count, 3)
      })

    XCTAssertNoThrow(
      try context.performSaveAndWait { context in
        let person = Person(context: context)
        person.firstName = "Tin"
        person.lastName = "Robots"
      })

  }

  func testSaveAndWaitWithoutChanges() throws {
    let context = container.viewContext.newBackgroundContext()
    try context.performSaveAndWait { _ in
      // no changes
    }
  }

  func testSaveWithoutChanges() {
    let context = container.viewContext.newBackgroundContext()
    let expectation1 = self.expectation(description: "\(#function)\(#line)")
    context.performSave(after: { _ in
      // no changes here
    }, completion: { error in
      XCTAssertNil(error)
      expectation1.fulfill()
    })

    waitForExpectations(timeout: 5, handler: nil)
  }

  func testSaveAndWait() {
    // Given, When
    let context = container.viewContext.newBackgroundContext()

    // Then
    XCTAssertNoThrow(
      try context.performSaveAndWait { context in
        let person = Person(context: context)
        person.firstName = "T"
        person.lastName = "R"

        let person2 = Person(context: context)
        person2.firstName = "T2"
        person2.lastName = "R2"

        let car3 = Car(context: context)
        car3.maker = "FIAT"
        car3.model = "Punto"
        car3.numberPlate = "3"

        person2.cars = [car3]
      }
    )

    XCTAssertNoThrow(
      try context.performSaveAndWait { context in
        let person = Person(context: context)
        person.firstName = "Tin"
        person.lastName = "Robots"
      }
    )

    XCTAssertThrowsError(
      try context.performSaveAndWait { context in
        let car1 = Car(context: context)
        car1.maker = "FIAT"
        car1.model = "Panda"
        car1.numberPlate = "1"

        let car2 = Car(context: context)
        car2.maker = "FIAT"
        car2.model = "Punto"
        car2.numberPlate = "2"

        let person = Person(context: context)
        person.firstName = "Tin"
        person.lastName = "Robots"
        person.cars = [car1, car2]

      }
    ) { (error) in
      context.performAndWait {
        XCTAssertNotNil(error)
      }
    }

    context.performAndWait {
      context.rollback() // discards all the failing changes
    }

    XCTAssertNoThrow(
      try context.performSaveAndWait { context in
        let person = Person(context: context)
        person.firstName = "Tin_"
        person.lastName = "Robots_"
      }
    )
  }

  func testSaveAndWaitWithReset() {
    let context = container.viewContext.newBackgroundContext()
    XCTAssertNoThrow(
      try context.performSaveAndWait { context in
        let person1 = Person(context: context)
        person1.firstName = "T1"
        person1.lastName = "R1"

        let person2 = Person(context: context)
        person2.firstName = "T2"
        person2.lastName = "R2"

        context.reset()
      }
    )

    context.performAndWait {
      XCTAssertTrue(context.registeredObjects.isEmpty)
    }
  }

  func testSaveAndWaitWithThrow() {
    let context = container.viewContext.newBackgroundContext()
    let expectation1 = expectation(description: "\(#function)\(#line)")

    do {
      try context.performSaveAndWait { context in
        let person = Person(context: context)
        person.firstName = "Tin1"
        person.lastName = "Robots1"
        throw NSError(domain: "test", code: 1, userInfo: nil)
      }
    } catch let catchedError as NSError where catchedError.code == NSError.ErrorCode.saveFailed.rawValue {
      XCTAssertNotNil(catchedError.underlyingError)
      let nsError = catchedError.underlyingError! as NSError
      XCTAssertEqual(nsError.code, 1)
      XCTAssertEqual(nsError.domain, "test")
      expectation1.fulfill()
    } catch {
      XCTFail("Wrong error type.")
    }
    waitForExpectations(timeout: 2)
  }

  func testSaveAndWaitWithAContextSaveDoneBeforeTheThrow() throws {
    let context = container.viewContext.newBackgroundContext()

    context.performAndWait {
      let person = Person(context: context)
      person.firstName = "Alessandro"
      person.lastName = "Test"
      try! context.save()
    }

    let expectation1 = expectation(description: "\(#function)\(#line)")

    do {
      try context.performSaveAndWait { context in
        let person = Person(context: context)
        person.firstName = "Tin1"
        person.lastName = "Robots1"
        throw NSError(domain: "test", code: 1, userInfo: nil)
      }
    } catch let catchedError as NSError where catchedError.code == NSError.ErrorCode.saveFailed.rawValue {
      XCTAssertNotNil(catchedError.underlyingError)
      let nsError = catchedError.underlyingError! as NSError
      XCTAssertEqual(nsError.code, 1)
      XCTAssertEqual(nsError.domain, "test")
      expectation1.fulfill()
    } catch {
      XCTFail("Wrong error type.")
    }
    waitForExpectations(timeout: 2)
  }

  func testSaveAndThrow() {
    let context = container.viewContext.newBackgroundContext()
    let expectation1 = expectation(description: "\(#function)\(#line)")

    context.performSave(after: { context in
      let person = Person(context: context)
      person.firstName = "T"
      person.lastName = "R"
      throw NSError(domain: "test", code: 1, userInfo: nil)

    }, completion: { error in
      if let error = error, error.code == NSError.ErrorCode.saveFailed.rawValue {
        XCTAssertNotNil(error.underlyingError)
        let underlyingError = error.underlyingError! as NSError
        XCTAssertEqual(underlyingError.code, 1)
        XCTAssertEqual(underlyingError.domain, "test")
      } else {
        XCTFail("Wrong error type.")
      }
      expectation1.fulfill()
    })

    waitForExpectations(timeout: 2)
  }

  func testSave() {
    // Given, When
    let context = container.viewContext.newBackgroundContext()

    // Then
    let saveExpectation1 = expectation(description: "Save 1")
    context.performSave(after: { context in
      let person = Person(context: context)
      person.firstName = "T"
      person.lastName = "R"
    }) { error in
      XCTAssertNil(error)
      saveExpectation1.fulfill()
    }

    wait(for: [saveExpectation1], timeout: 10)

    let saveExpectation2 = expectation(description: "Save 2")
    context.performSave(after: { context in
      let person = Person(context: context)
      person.firstName = "Tin"
      person.lastName = "Robots"
    }) { error in
      XCTAssertNil(error)
      saveExpectation2.fulfill()
    }

    wait(for: [saveExpectation2], timeout: 10)

    /// saving error
    let saveExpectation3 = expectation(description: "Save 3")
    context.performSave(after: { context in
      let person = Person(context: context)
      person.firstName = "Tin"
      person.lastName = "Robots"
    }) { error in
      XCTAssertNotNil(error)
      saveExpectation3.fulfill()
    }

    wait(for: [saveExpectation3], timeout: 10)
    context.performAndWait {
      context.rollback() // remove not valid changes
    }

    let saveExpectation4 = expectation(description: "Save 4")
    context.performSave(after: { context in
      let person = Person(context: context)
      person.firstName = "Tin_"
      person.lastName = "Robots"
    }) { error in
      XCTAssertNil(error)
      saveExpectation4.fulfill()
    }

    wait(for: [saveExpectation4], timeout: 10)

    let saveExpectation5 = expectation(description: "Save 5")
    context.performSave(after: { context in
      let person = Person(context: context)
      person.firstName = "Tin"
      person.lastName = "Robots_"
    }) { error in
      XCTAssertNil(error)
      saveExpectation5.fulfill()
    }

    wait(for: [saveExpectation5], timeout: 10)

    let saveExpectation6 = expectation(description: "Save 6")
    context.performSave(after: { context in
      let car = Car(context: context)
      car.numberPlate = "100"
    }) { error in
      XCTAssertNil(error)
      saveExpectation6.fulfill()
    }

    wait(for: [saveExpectation6], timeout: 10)

    let saveExpectation7 = expectation(description: "Save 7")
    context.performSave(after: { context in
      let car = SportCar(context: context)
      car.numberPlate = "200"
    }) { error in
      XCTAssertNil(error)
      saveExpectation7.fulfill()
    }

    wait(for: [saveExpectation7], timeout: 10)

    /// saving error
    let saveExpectation8 = expectation(description: "Save 7")
    context.performSave(after: { context in
      let car = SportCar(context: context)
      car.numberPlate = "200" // same numberPlate
    }) { error in
      XCTAssertNotNil(error)
      saveExpectation8.fulfill()
    }

    wait(for: [saveExpectation8], timeout: 10)
  }

  func testPerformAndWait() throws {

    let context = container.viewContext
    context.fillWithSampleData()

    let cars = try context.performAndWaitResult { (_context) -> [Car] in
      XCTAssertTrue(_context === context )
      return try Car.fetch(in: _context)
    }

    XCTAssertFalse(cars.isEmpty)
  }

  func testPerformAndWaitWithThrow() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let context = container.viewContext
    context.fillWithSampleData()

    do {
      _ = try context.performAndWaitResult { (_context) -> [Car] in
        XCTAssertTrue(_context === context )
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

  func testSaveOrRollback() {
    let context = container.viewContext

    let car1 = Car(context: context)
    car1.maker = "FIAT"
    car1.model = "Panda"
    car1.numberPlate = "1"

    let person1 = Person(context: context)
    person1.firstName = "Tin"
    person1.lastName = "Robots"

    person1.cars = [car1]

    XCTAssertNoThrow(try context.saveOrRollBack())

    XCTAssertEqual(context.registeredObjects.count, 2) // person1 and car1 with a circular reference cycle

    let person2 = Person(context: context)
    person2.firstName = "Tin"
    person2.lastName = "Robots"
    person2.cars = nil

    XCTAssertEqual(context.registeredObjects.count, 3)

    XCTAssertThrowsError(try context.saveOrRollBack())

    XCTAssertEqual(context.registeredObjects.count, 2) // person2 is discarded because it cannot be saved
  }

  func testCollectionDelete() throws {
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

    let person3 = newContext.performAndWaitResult { context -> Person in
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

  func testPerformSaveUpToTheLastParentContextAndWait() throws {
    let mainContext = container.viewContext
    let backgroundContext = mainContext.newBackgroundContext(asChildContext: true) // main context children
    let childBackgroundContext = backgroundContext.newBackgroundContext(asChildContext: true) // background context children

    childBackgroundContext.performAndWaitResult { context in
      let person = Person(context: context)
      person.firstName = "Alessandro"
      person.lastName = "Marzoli"
    }

    try childBackgroundContext.performSaveUpToTheLastParentContextAndWait()
    try backgroundContext.performAndWaitResult { _ in
      let count = try Person.count(in: backgroundContext)
      XCTAssertEqual(count, 1)
    }

    let count = try Person.count(in: mainContext)
    XCTAssertEqual(count, 1)
  }

  func testPerformSaveUpToTheLastParentContextAndWaitWithoutChanges() throws {
    let mainContext = container.viewContext
    let backgroundContext = mainContext.newBackgroundContext(asChildContext: true) // main context children
    let childBackgroundContext = backgroundContext.newBackgroundContext(asChildContext: true) // background context children

    try childBackgroundContext.performSaveUpToTheLastParentContextAndWait()
    try backgroundContext.performAndWaitResult { _ in
      let count = try Person.count(in: backgroundContext)
      XCTAssertEqual(count, 0)
    }

    let count = try Person.count(in: mainContext)
    XCTAssertEqual(count, 0)
  }
}
