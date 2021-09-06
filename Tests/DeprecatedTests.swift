// CoreDataPlus


import XCTest
import CoreData
@testable import CoreDataPlus

//final class DeprecatedTestsInMemory: InMemoryTestCase {
//  func testPerformSaveUpToTheLastParentContextAndWait() throws {
//    let mainContext = container.viewContext
//    let backgroundContext = mainContext.newBackgroundContext(asChildContext: true) // main context child
//    let childBackgroundContext = backgroundContext.newBackgroundContext(asChildContext: true) // background context child
//
//    childBackgroundContext.performAndWait { context in
//      let person = Person(context: context)
//      person.firstName = "Alessandro"
//      person.lastName = "Marzoli"
//    }
//
//    try childBackgroundContext.performSaveUpToTheLastParentContextAndWait()
//    try backgroundContext.performAndWait {
//      let count = try Person.count(in: $0)
//      XCTAssertEqual(count, 1)
//    }
//
//    let count = try Person.count(in: mainContext)
//    XCTAssertEqual(count, 1)
//  }
//
//  func testPerformSaveUpToTheLastParentContextAndWaitWithoutChanges() throws {
//    let mainContext = container.viewContext
//    let backgroundContext = mainContext.newBackgroundContext(asChildContext: true) // main context children
//    let childBackgroundContext = backgroundContext.newBackgroundContext(asChildContext: true) // background context children
//
//    try childBackgroundContext.performSaveUpToTheLastParentContextAndWait()
//    try backgroundContext.performAndWait { _ in
//      let count = try Person.count(in: backgroundContext)
//      XCTAssertEqual(count, 0)
//    }
//
//    let count = try Person.count(in: mainContext)
//    XCTAssertEqual(count, 0)
//  }
//  
//  func testMultipleSaveAndWait() throws {
//    // Given, When
//    let context = container.viewContext.newBackgroundContext()
//
//    // Then
//    XCTAssertNoThrow(
//      try context.performSaveAndWait { context in
//        let person = Person(context: context)
//        person.firstName = "T"
//        person.lastName = "R"
//
//        let person2 = Person(context: context)
//        person2.firstName = "T2"
//        person2.lastName = "R2"
//
//        let car3 = Car(context: context)
//        car3.maker = "FIAT"
//        car3.model = "Punto"
//        car3.numberPlate = "3"
//
//        person2.cars = [car3]
//
//        XCTAssertEqual(context.registeredObjects.count, 3)
//      })
//
//    XCTAssertNoThrow(
//      try context.performSaveAndWait { context in
//        let person = Person(context: context)
//        person.firstName = "Tin"
//        person.lastName = "Robots"
//      })
//  }
//
//  func testSaveAndWaitWithoutChanges() throws {
//    let context = container.viewContext.newBackgroundContext()
//    try context.performSaveAndWait { _ in
//      // no changes
//    }
//  }
//
//  func testSaveWithoutChanges() {
//    let context = container.viewContext.newBackgroundContext()
//    let expectation1 = self.expectation(description: "\(#function)\(#line)")
//    context.performSave(after: { _ in
//      // no changes here
//    }, completion: { error in
//      XCTAssertNil(error)
//      expectation1.fulfill()
//    })
//
//    waitForExpectations(timeout: 5, handler: nil)
//  }
//
//  func testSaveAndWait() {
//    // Given, When
//    let context = container.viewContext.newBackgroundContext()
//
//    // Then
//    XCTAssertNoThrow(
//      try context.performSaveAndWait { context in
//        let person = Person(context: context)
//        person.firstName = "T"
//        person.lastName = "R"
//
//        let person2 = Person(context: context)
//        person2.firstName = "T2"
//        person2.lastName = "R2"
//
//        let car3 = Car(context: context)
//        car3.maker = "FIAT"
//        car3.model = "Punto"
//        car3.numberPlate = "3"
//
//        person2.cars = [car3]
//      }
//    )
//
//    XCTAssertNoThrow(
//      try context.performSaveAndWait { context in
//        let person = Person(context: context)
//        person.firstName = "Tin"
//        person.lastName = "Robots"
//      }
//    )
//
//    XCTAssertThrowsError(
//      try context.performSaveAndWait { context in
//        let car1 = Car(context: context)
//        car1.maker = "FIAT"
//        car1.model = "Panda"
//        car1.numberPlate = "1"
//
//        let car2 = Car(context: context)
//        car2.maker = "FIAT"
//        car2.model = "Punto"
//        car2.numberPlate = "2"
//
//        let person = Person(context: context)
//        person.firstName = "Tin"
//        person.lastName = "Robots"
//        person.cars = [car1, car2]
//
//      }
//    ) { (error) in
//      context.performAndWait {
//        XCTAssertNotNil(error)
//      }
//    }
//
//    context.performAndWait {
//      context.rollback() // discards all the failing changes
//    }
//
//    XCTAssertNoThrow(
//      try context.performSaveAndWait { context in
//        let person = Person(context: context)
//        person.firstName = "Tin_"
//        person.lastName = "Robots_"
//      }
//    )
//  }
//
//  func testSaveAndWaitWithReset() {
//    let context = container.viewContext.newBackgroundContext()
//    XCTAssertNoThrow(
//      try context.performSaveAndWait { context in
//        let person1 = Person(context: context)
//        person1.firstName = "T1"
//        person1.lastName = "R1"
//
//        let person2 = Person(context: context)
//        person2.firstName = "T2"
//        person2.lastName = "R2"
//
//        context.reset()
//      }
//    )
//
//    context.performAndWait {
//      XCTAssertTrue(context.registeredObjects.isEmpty)
//    }
//  }
//
//  func testSaveAndWaitWithThrow() {
//    let context = container.viewContext.newBackgroundContext()
//    let expectation1 = expectation(description: "\(#function)\(#line)")
//
//    do {
//      try context.performSaveAndWait { context in
//        let person = Person(context: context)
//        person.firstName = "Tin1"
//        person.lastName = "Robots1"
//        throw NSError(domain: "test", code: 1, userInfo: nil)
//      }
//    } catch let catchedError as NSError {
//      XCTAssertEqual(catchedError.code, 1)
//      XCTAssertEqual(catchedError.domain, "test")
//      expectation1.fulfill()
//    } catch {
//      XCTFail("Wrong error type.")
//    }
//    waitForExpectations(timeout: 2)
//  }
//
//  func testSaveAndWaitWithAContextSaveDoneBeforeTheThrow() throws {
//    let context = container.viewContext.newBackgroundContext()
//
//    context.performAndWait {
//      let person = Person(context: context)
//      person.firstName = "Alessandro"
//      person.lastName = "Test"
//      try! context.save()
//    }
//
//    let expectation1 = expectation(description: "\(#function)\(#line)")
//
//    do {
//      try context.performSaveAndWait { context in
//        let person = Person(context: context)
//        person.firstName = "Tin1"
//        person.lastName = "Robots1"
//        throw NSError(domain: "test", code: 1, userInfo: nil)
//      }
//    } catch let catchedError as NSError {
//      XCTAssertEqual(catchedError.code, 1)
//      XCTAssertEqual(catchedError.domain, "test")
//      expectation1.fulfill()
//    } catch {
//      XCTFail("Wrong error type.")
//    }
//    waitForExpectations(timeout: 2)
//  }
//
//  func testSaveAndThrow() {
//    let context = container.viewContext.newBackgroundContext()
//    let expectation1 = expectation(description: "\(#function)\(#line)")
//
//    context.performSave(after: { context in
//      let person = Person(context: context)
//      person.firstName = "T"
//      person.lastName = "R"
//      throw NSError(domain: "test", code: 1, userInfo: nil)
//
//    }, completion: { error in
//      if let error = error {
//        XCTAssertEqual(error.code, 1)
//        XCTAssertEqual(error.domain, "test")
//      } else {
//        XCTFail("Wrong error type.")
//      }
//      expectation1.fulfill()
//    })
//
//    waitForExpectations(timeout: 2)
//  }
//
//  func testSave() {
//    // Given, When
//    let context = container.viewContext.newBackgroundContext()
//
//    // Then
//    let saveExpectation1 = expectation(description: "Save 1")
//    context.performSave(after: { context in
//      let person = Person(context: context)
//      person.firstName = "T"
//      person.lastName = "R"
//    }) { error in
//      XCTAssertNil(error)
//      saveExpectation1.fulfill()
//    }
//
//    wait(for: [saveExpectation1], timeout: 10)
//
//    let saveExpectation2 = expectation(description: "Save 2")
//    context.performSave(after: { context in
//      let person = Person(context: context)
//      person.firstName = "Tin"
//      person.lastName = "Robots"
//    }) { error in
//      XCTAssertNil(error)
//      saveExpectation2.fulfill()
//    }
//
//    wait(for: [saveExpectation2], timeout: 10)
//
//    /// saving error
//    let saveExpectation3 = expectation(description: "Save 3")
//    context.performSave(after: { context in
//      let person = Person(context: context)
//      person.firstName = "Tin"
//      person.lastName = "Robots"
//    }) { error in
//      XCTAssertNotNil(error)
//      saveExpectation3.fulfill()
//    }
//
//    wait(for: [saveExpectation3], timeout: 10)
//    context.performAndWait {
//      context.rollback() // remove not valid changes
//    }
//
//    let saveExpectation4 = expectation(description: "Save 4")
//    context.performSave(after: { context in
//      let person = Person(context: context)
//      person.firstName = "Tin_"
//      person.lastName = "Robots"
//    }) { error in
//      XCTAssertNil(error)
//      saveExpectation4.fulfill()
//    }
//
//    wait(for: [saveExpectation4], timeout: 10)
//
//    let saveExpectation5 = expectation(description: "Save 5")
//    context.performSave(after: { context in
//      let person = Person(context: context)
//      person.firstName = "Tin"
//      person.lastName = "Robots_"
//    }) { error in
//      XCTAssertNil(error)
//      saveExpectation5.fulfill()
//    }
//
//    wait(for: [saveExpectation5], timeout: 10)
//
//    let saveExpectation6 = expectation(description: "Save 6")
//    context.performSave(after: { context in
//      let car = Car(context: context)
//      car.numberPlate = "100"
//    }) { error in
//      XCTAssertNil(error)
//      saveExpectation6.fulfill()
//    }
//
//    wait(for: [saveExpectation6], timeout: 10)
//
//    let saveExpectation7 = expectation(description: "Save 7")
//    context.performSave(after: { context in
//      let car = SportCar(context: context)
//      car.numberPlate = "200"
//    }) { error in
//      XCTAssertNil(error)
//      saveExpectation7.fulfill()
//    }
//
//    wait(for: [saveExpectation7], timeout: 10)
//
//    /// saving error
//    let saveExpectation8 = expectation(description: "Save 7")
//    context.performSave(after: { context in
//      let car = SportCar(context: context)
//      car.numberPlate = "200" // same numberPlate
//    }) { error in
//      XCTAssertNotNil(error)
//      saveExpectation8.fulfill()
//    }
//
//    wait(for: [saveExpectation8], timeout: 10)
//  }
//}
//
//final class DeprecatedTestsOnDisk: OnDiskTestCase {
//  func testFindOneOrCreate() throws {
//    let context = container.viewContext
//    
//    context.performAndWait {
//      context.fillWithSampleData()
//      try! context.save()
//    }
//    
//    /// existing object
//    do {
//      let car = try Car.findOneOrCreate(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")) { car in
//        XCTAssertNotNil(car.numberPlate)
//      }
//      XCTAssertNotNil(car)
//      XCTAssertTrue(car.maker == "Lamborghini")
//      XCTAssertFalse(car.objectID.isTemporaryID)
//    }
//    
//    /// new object
//    do {
//      let car = try Car.findOneOrCreate(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304-new"), with: { car in
//        XCTAssertNil(car.numberPlate)
//        car.numberPlate = "304-new"
//        car.model = "test"
//      })
//      XCTAssertNotNil(car)
//      XCTAssertNil(car.maker)
//      XCTAssertEqual(car.numberPlate, "304-new")
//      XCTAssertEqual(car.model, "test")
//      XCTAssertTrue(car.objectID.isTemporaryID)
//      context.delete(car)
//    }
//    
//    /// new object added in the context before the fetch
//    
//    // first we materialiaze all cars
//    XCTAssertNoThrow(try Car.fetch(in: context) { request in request.returnsObjectsAsFaults = false })
//    let car = Car(context: context)
//    car.numberPlate = "304"
//    car.maker = "fake-maker"
//    car.model = "fake-model"
//    
//    /// At this point we have two car with the same 304 number plate in the context, so the method will fetch one of these two.
//    do {
//      let car = try Car.findOneOrCreate(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304"), with: { car in
//        XCTAssertNil(car.numberPlate)
//      })
//      XCTAssertNotNil(car)
//      if car.objectID.isTemporaryID {
//        XCTAssertEqual(car.maker, "fake-maker")
//      } else {
//        XCTAssertEqual(car.maker, "Lamborghini")
//      }
//      
//      let car304 = context.registeredObjects.filter{ $0 is Car } as! Set<Car>
//      
//      XCTAssertTrue(car304.filter { $0.numberPlate == "304" }.count == 2)
//    }
//    
//    context.refreshAllObjects()
//    context.reset()
//    
//    /// multiple objects, the first one matching the condition is returned
//    do {
//      let car = try Car.findOneOrCreate(in: context, where: NSPredicate(value: true), with: { car in
//        XCTAssertNotNil(car.numberPlate)
//      })
//      XCTAssertNotNil(car)
//      XCTAssertFalse(car.objectID.isTemporaryID)
//    }
//  }
//}
