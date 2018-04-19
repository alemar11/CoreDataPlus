//
// CoreDataPlus
//
//  Copyright © 2016-2018 Tinrobots.
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

final class NSManagedObjectContextUtilsTests: XCTestCase {

  func testSinglePersistentStore() {
    // Given, When
    let stack = CoreDataStack.stack()
    // Then
    XCTAssertTrue(stack.mainContext.persistentStores.count == 1)
    XCTAssertNotNil(stack.mainContext.persistentStores.first)

  }

  func testMissingPersistentStoreCoordinator() {
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    XCTAssertTrue(context.persistentStores.isEmpty)
  }

  func testMetaData() {
    do {
      // Given
      let stack = CoreDataStack.stack(type: .sqlite)

      // When
      guard let firstPersistentStore = stack.mainContext.persistentStores.first else {
        XCTAssertNotNil(stack.mainContext.persistentStores.first)
        return
      }
      // Then
      let metaData = stack.mainContext.metaData(for: firstPersistentStore)
      XCTAssertNotNil((metaData["NSStoreModelVersionHashes"] as? [String: Any])?[Car.entityName])
      XCTAssertNotNil((metaData["NSStoreModelVersionHashes"] as? [String: Any])?[Person.entityName])
      XCTAssertNotNil(metaData["NSStoreType"] as? String)

      let addMetaDataExpectation = expectation(description: "Add MetaData Expectation")
      stack.mainContext.setMetaDataObject("Test", with: "testKey", for: firstPersistentStore){ error in
        XCTAssertNil(error)
        addMetaDataExpectation.fulfill()
      }
      waitForExpectations(timeout: 5.0, handler: nil)

      let updatedMetaData = stack.mainContext.metaData(for: firstPersistentStore)
      XCTAssertNotNil(updatedMetaData["testKey"])
      XCTAssertEqual(updatedMetaData["testKey"] as? String, "Test")

    }

    do {
      // Given
      let stack = CoreDataStack.stack(type: .sqlite)

      // When
      guard let firstPersistentStore = stack.mainContext.persistentStores.first else {
        XCTAssertNotNil(stack.mainContext.persistentStores.first)
        return
      }
      // Then
      let metaData = stack.mainContext.metaData(for: firstPersistentStore)
      XCTAssertNotNil((metaData["NSStoreModelVersionHashes"] as? [String: Any])?[Car.entityName])
      XCTAssertNotNil((metaData["NSStoreModelVersionHashes"] as? [String: Any])?[Person.entityName])
      XCTAssertNotNil(metaData["NSStoreType"] as? String)

      let addMetaDataExpectation = expectation(description: "Add MetaData Expectation")
      stack.mainContext.setMetaDataObject("Test", with: "testKey", for: firstPersistentStore){ error in
        XCTAssertNil(error)
        addMetaDataExpectation.fulfill()
      }
      waitForExpectations(timeout: 5.0, handler: nil)

      let updatedMetaData = stack.mainContext.metaData(for: firstPersistentStore)
      XCTAssertNotNil(updatedMetaData["testKey"])
      XCTAssertEqual(updatedMetaData["testKey"] as? String, "Test")

    }

  }

  func testEntityDescription() {
    // Given, When
    let stack = CoreDataStack.stack(type: .sqlite)

    // Then
    XCTAssertNotNil(stack.mainContext.entity(forEntityName: Car.entityName))
    XCTAssertNotNil(stack.mainContext.entity(forEntityName: Person.entityName))
    XCTAssertNil(stack.mainContext.entity(forEntityName: "FakeEntity"))
  }

  func testNewBackgroundContext() {
    // Given, When
    let stack = CoreDataStack.stack(type: .sqlite)

    // Then
    let backgroundContext = stack.mainContext.newBackgroundContext(asChildContext: true)
    XCTAssertEqual(backgroundContext.concurrencyType,.privateQueueConcurrencyType)
    XCTAssertEqual(backgroundContext.parent,stack.mainContext)

    let backgroundContext2 = stack.mainContext.newBackgroundContext()
    XCTAssertEqual(backgroundContext2.concurrencyType,.privateQueueConcurrencyType)
    XCTAssertNotEqual(backgroundContext2.parent,stack.mainContext)
  }

  func testSaveAndWaitWithReset() {
    let stack = CoreDataStack.stack(type: .sqlite)
    let context = stack.mainContext.newBackgroundContext()
    XCTAssertNoThrow(
      try context.performSaveAndWait {
        let person1 = Person(context: context)
        person1.firstName = "T1"
        person1.lastName = "R1"

        let person2 = Person(context: context)
        person2.firstName = "T2"
        person2.lastName = "R2"

        context.reset()
      }
    )

    XCTAssertTrue(context.registeredObjects.isEmpty)
  }

  func testSaveAndWait() {
    // Given, When
    let stack = CoreDataStack.stack(type: .sqlite)
    let context = stack.mainContext.newBackgroundContext()

    // Then

    XCTAssertNoThrow(
      try context.performSaveAndWait {
        let person = Person(context: context)
        person.firstName = "T"
        person.lastName = "R"
      }
    )

    XCTAssertNoThrow(
      try context.performSaveAndWait { })

    XCTAssertNoThrow(
      try context.performSaveAndWait {
        let person = Person(context: context)
        person.firstName = "Tin"
        person.lastName = "Robots"
      }
    )

    XCTAssertThrowsError(
      try context.performSaveAndWait {
        let person = Person(context: context)
        person.firstName = "Tin"
        person.lastName = "Robots"
      }
    ) { (error) in
      XCTAssertNotNil(error)
    }

    XCTAssertNoThrow(
      try context.performSaveAndWait {
        let person = Person(context: context)
        person.firstName = "Tin_"
        person.lastName = "Robots"
      }
    )

    XCTAssertNoThrow(
      try context.performSaveAndWait {
        let person = Person(context: context)
        person.firstName = "Tin"
        person.lastName = "Robots_"
      }
    )
  }

  func testSaveAndWaitWithThrow() {
    let stack = CoreDataStack.stack(type: .sqlite)
    let context = stack.mainContext.newBackgroundContext()
    let expectation1 = expectation(description: "\(#function)\(#line)")

    do {
      try context.performSaveAndWait {
        let person = Person(context: context)
        person.firstName = "Tin1"
        person.lastName = "Robots1"
        throw NSError(domain: "test", code: 1, userInfo: nil)
      }
    } catch let catchedError {
      if case CoreDataPlusError.executionFailed(error: let error) = catchedError {
        let nsError = error as NSError
        XCTAssertEqual(nsError.code, 1)
        XCTAssertEqual(nsError.domain, "test")

      } else {
        XCTFail("Wrong error type.")
      }
      expectation1.fulfill()
    }
    waitForExpectations(timeout: 2)

    XCTAssertTrue(context.registeredObjects.isEmpty)

  }

  func testSaveAndThrow() {
    let stack = CoreDataStack.stack(type: .sqlite)
    let context = stack.mainContext.newBackgroundContext()

    let expectation1 = expectation(description: "\(#function)\(#line)")
    context.performSave(after: {
      let person = Person(context: context)
      person.firstName = "T"
      person.lastName = "R"
      throw NSError(domain: "test", code: 1, userInfo: nil)

    }) { catchedError in
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

    XCTAssertTrue(context.registeredObjects.isEmpty)
  }

  func testSave() {
    // Given, When
    let stack = CoreDataStack.stack(type: .sqlite)
    let context = stack.mainContext.newBackgroundContext()
    // Then
    let saveExpectation1 = expectation(description: "Save 1")
    context.performSave(after: {
      let person = Person(context: context)
      person.firstName = "T"
      person.lastName = "R"
    }) { error in
      XCTAssertNil(error)
      saveExpectation1.fulfill()
    }

    wait(for: [saveExpectation1], timeout: 10)

    let saveExpectation2 = expectation(description: "Save 2")
    context.performSave(after: {
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
    context.performSave(after: {
      let person = Person(context: context)
      person.firstName = "Tin"
      person.lastName = "Robots"
    }) { error in
      XCTAssertNotNil(error)
      saveExpectation3.fulfill()
    }

    wait(for: [saveExpectation3], timeout: 10)

    let saveExpectation4 = expectation(description: "Save 4")
    context.performSave(after: {
      let person = Person(context: context)
      person.firstName = "Tin_"
      person.lastName = "Robots"
    }) { error in
      XCTAssertNil(error)
      saveExpectation4.fulfill()
    }

    wait(for: [saveExpectation4], timeout: 10)

    let saveExpectation5 = expectation(description: "Save 5")
    context.performSave(after: {
      let person = Person(context: context)
      person.firstName = "Tin"
      person.lastName = "Robots_"
    }) { error in
      XCTAssertNil(error)
      saveExpectation5.fulfill()
    }

    wait(for: [saveExpectation5], timeout: 10)

    let saveExpectation6 = expectation(description: "Save 6")
    context.performSave(after: {
      let car = Car(context: context)
      car.numberPlate = "100"
    }) { error in
      XCTAssertNil(error)
      saveExpectation6.fulfill()
    }

    wait(for: [saveExpectation6], timeout: 10)

    let saveExpectation7 = expectation(description: "Save 7")
    context.performSave(after: {
      let car = SportCar(context: context)
      car.numberPlate = "200"
    }) { error in
      XCTAssertNil(error)
      saveExpectation7.fulfill()
    }

    wait(for: [saveExpectation7], timeout: 10)

    /// saving error
    let saveExpectation8 = expectation(description: "Save 7")
    context.performSave(after: {
      let car = SportCar(context: context)
      car.numberPlate = "200" // same numberPlate
    }) { error in
      XCTAssertNotNil(error)
      saveExpectation8.fulfill()
    }

    wait(for: [saveExpectation8], timeout: 10)
  }

  func testPerformAndWait() throws {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    context.fillWithSampleData()

    let cars = try context.performAndWait { (_context) -> [Car] in
      return try Car.fetch(in: _context)
    }

    XCTAssertFalse(cars.isEmpty)
  }

}

