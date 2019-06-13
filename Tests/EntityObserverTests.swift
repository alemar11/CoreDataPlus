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

final class EntityObserverTests: CoreDataPlusTestCase {

  // MARK: - Change Event

  func testInsertedOnDidChangeEvent() {
    let context = container.viewContext
    let observedEvent = ManagedObjectContextObservedEvent.didChange
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let observer = EntityObserver<SportCar>(context: context, event: observedEvent) { (change, event) in
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(change.insertedObjects.count, 1)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertTrue(change.updatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation1.fulfill()
    }
    XCTAssertEqual(observer.event, observedEvent)

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
  }

  func testUpdatedOnDidChangeEvent() throws {
    let context = container.viewContext
    let observedEvent = ManagedObjectContextObservedEvent.didChange
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let sportCar = SportCar(context: context)
    sportCar.maker = "McLaren"
    sportCar.model = "570GT"
    sportCar.numberPlate = "203"

    let car = Car(context: context)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = "1"

    try context.save()

    let observer = EntityObserver<SportCar>(context: context, event: observedEvent) { (change, event) in
      XCTAssertEqual(observedEvent, event)
      XCTAssertTrue(change.insertedObjects.isEmpty)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertEqual(change.updatedObjects.count, 1)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation1.fulfill()
    }
    XCTAssertEqual(observer.event, observedEvent)

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    car.numberPlate = car.numberPlate + " Updated"
    sportCar.numberPlate = sportCar.numberPlate + " Updated"

    waitForExpectations(timeout: 2)
  }

  func testInsertedAndUpdatedOnDidChangeEvent() throws {
    let context = container.viewContext
    let observedEvent = ManagedObjectContextObservedEvent.didChange
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let sportCar1 = SportCar(context: context)
    sportCar1.maker = "McLaren"
    sportCar1.model = "570GT"
    sportCar1.numberPlate = "203"

    let car = Car(context: context)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = "1"

    try context.save()

    let observer = EntityObserver<SportCar>(context: context, event: observedEvent) { (change, event) in
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(change.insertedObjects.count, 1)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertEqual(change.updatedObjects.count, 1)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation1.fulfill()
    }
    XCTAssertEqual(observer.event, observedEvent)

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    let sportCar2 = SportCar(context: context)
    sportCar2.maker = "Lamborghini "
    sportCar2.model = "Aventador LP750-4"
    sportCar2.numberPlate = "204"

    car.numberPlate = car.numberPlate + " Updated"
    sportCar1.numberPlate = sportCar1.numberPlate + " Updated"

    waitForExpectations(timeout: 2)
  }

  func testDeleteOnDidChangeEvent() throws {
    let context = container.viewContext
    let observedEvent = ManagedObjectContextObservedEvent.didChange
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let sportCar = SportCar(context: context)
    sportCar.maker = "McLaren"
    sportCar.model = "570GT"
    sportCar.numberPlate = "203"

    let sportCar2 = SportCar(context: context)
    sportCar2.maker = "Lamborghini "
    sportCar2.model = "Aventador LP750-4"
    sportCar2.numberPlate = "204"

    let car = Car(context: context)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = "1"

    try context.save()

    let observer = EntityObserver<SportCar>(context: context, event: observedEvent) { (change, event) in
      XCTAssertEqual(observedEvent, event)
      XCTAssertTrue(change.insertedObjects.isEmpty)
      XCTAssertEqual(change.deletedObjects.count, 1)
      XCTAssertTrue(change.deletedObjects.first === sportCar)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertEqual(change.updatedObjects.count, 1)
      XCTAssertTrue(change.updatedObjects.first === sportCar2)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation1.fulfill()
    }
    XCTAssertEqual(observer.event, observedEvent)

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    car.numberPlate = car.numberPlate + " Updated"
    sportCar.numberPlate = sportCar.numberPlate + " Updated"
    sportCar2.numberPlate = sportCar.numberPlate + " Updated"
    context.delete(sportCar)

    waitForExpectations(timeout: 2)
  }


  func testRefreshedOnDidChangeEvent() throws {
    let context = container.viewContext
    let observedEvent = ManagedObjectContextObservedEvent.didChange
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let sportCar1 = SportCar(context: context)
    sportCar1.maker = "McLaren"
    sportCar1.model = "570GT"
    sportCar1.numberPlate = "203"

    let sportCar2 = SportCar(context: context)
    sportCar2.maker = "Lamborghini "
    sportCar2.model = "Aventador LP750-4"
    sportCar2.numberPlate = "204"

    let expensiveSportCar1 = ExpensiveSportCar(context: context)
    expensiveSportCar1.maker = "BMW"
    expensiveSportCar1.model = "M6 Coupe"
    expensiveSportCar1.numberPlate = "300"
    expensiveSportCar1.isLimitedEdition = true

    let car1 = Car(context: context)
    car1.maker = "FIAT"
    car1.model = "Panda"
    car1.numberPlate = "1"

    try context.save()

    let observer = EntityObserver<SportCar>(context: context, event: observedEvent) { (change, event) in
      XCTAssertEqual(observedEvent, event)
      XCTAssertTrue(change.insertedObjects.isEmpty)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertEqual(change.refreshedObjects.count, 2)
      XCTAssertEqual(change.updatedObjects.count, 1)
      XCTAssertTrue(change.updatedObjects.first === sportCar1)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation1.fulfill()
    }
    XCTAssertEqual(observer.event, observedEvent)

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    context.delete(car1)
    sportCar1.numberPlate = sportCar1.numberPlate + " Updated"
    sportCar2.numberPlate = sportCar2.numberPlate + " Updated"
    expensiveSportCar1.numberPlate = expensiveSportCar1.numberPlate + " Updated"

    /// 2 objects are refreshed
    /// sportCar1 will be updated too
    sportCar1.refresh(mergeChanges: true)
    sportCar2.refresh(mergeChanges: false)

    waitForExpectations(timeout: 2)
  }

  func testInvalidatedAllOnDidChangeEvent() throws {
    let context = container.viewContext
    let observedEvent = ManagedObjectContextObservedEvent.didChange
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let sportCar1 = SportCar(context: context)
    sportCar1.maker = "McLaren"
    sportCar1.model = "570GT"
    sportCar1.numberPlate = "203"

    let sportCar2 = SportCar(context: context)
    sportCar2.maker = "Lamborghini "
    sportCar2.model = "Aventador LP750-4"
    sportCar2.numberPlate = "204"

    let expensiveSportCar1 = ExpensiveSportCar(context: context)
    expensiveSportCar1.maker = "BMW"
    expensiveSportCar1.model = "M6 Coupe"
    expensiveSportCar1.numberPlate = "300"
    expensiveSportCar1.isLimitedEdition = true

    let car1 = Car(context: context)
    car1.maker = "FIAT"
    car1.model = "Panda"
    car1.numberPlate = "1"

    try context.save()

    let observer = EntityObserver<SportCar>(context: context, event: observedEvent) { (change, event) in
      XCTAssertEqual(observedEvent, event)
      XCTAssertTrue(change.insertedObjects.isEmpty)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertTrue(change.updatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertEqual(change.invalidatedAllObjects.count, 2) // sportCar1 and sportCar2
      XCTAssertTrue(change.invalidatedAllObjects.contains(sportCar1.objectID))
      XCTAssertTrue(change.invalidatedAllObjects.contains(sportCar2.objectID))
      expectation1.fulfill()
    }
    XCTAssertEqual(observer.event, observedEvent)

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    context.delete(car1)
    sportCar1.numberPlate = sportCar1.numberPlate + " Updated"
    sportCar2.numberPlate = sportCar2.numberPlate + " Updated"
    expensiveSportCar1.numberPlate = expensiveSportCar1.numberPlate + " Updated"

    /// 2 objects are refreshed
    /// sportCar1 will be updated too
    sportCar1.refresh(mergeChanges: true)
    sportCar2.refresh(mergeChanges: false)

    context.reset()

    waitForExpectations(timeout: 2)
  }

  func testRelationshipUpdatedOnDidChangeEvent() throws {
    let context = container.viewContext
    let observedEvent = ManagedObjectContextObservedEvent.didChange
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let sportCar1 = SportCar(context: context)
    sportCar1.maker = "McLaren"
    sportCar1.model = "570GT"
    sportCar1.numberPlate = "203"

    let sportCar2 = SportCar(context: context)
    sportCar2.maker = "Lamborghini "
    sportCar2.model = "Aventador LP750-4"
    sportCar2.numberPlate = "204"

    let expensiveSportCar1 = ExpensiveSportCar(context: context)
    expensiveSportCar1.maker = "BMW"
    expensiveSportCar1.model = "M6 Coupe"
    expensiveSportCar1.numberPlate = "300"
    expensiveSportCar1.isLimitedEdition = true

    let car1 = Car(context: context)
    car1.maker = "FIAT"
    car1.model = "Panda"
    car1.numberPlate = "1"

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    try context.save()

    let observer = EntityObserver<SportCar>(context: context, event: observedEvent) { (change, event) in
      XCTAssertEqual(observedEvent, event)
      XCTAssertTrue(change.insertedObjects.isEmpty)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertEqual(change.updatedObjects.count, 2)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation1.fulfill()
    }
    XCTAssertEqual(observer.event, observedEvent)

    person1.cars = [sportCar1, sportCar2]
    expensiveSportCar1.numberPlate = expensiveSportCar1.numberPlate + " Updated"

    waitForExpectations(timeout: 2)
  }

  // MARK: - Save Event

  func testInsertedOnDidSaveEvent() throws {
    let context = container.viewContext
    let observedEvent = ManagedObjectContextObservedEvent.didSave
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let observer = EntityObserver<SportCar>(context: context, event: observedEvent) { (change, event) in
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(change.insertedObjects.count, 2)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertTrue(change.updatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation1.fulfill()
    }
    XCTAssertEqual(observer.event, observedEvent)

    let sportCar = SportCar(context: context)
    sportCar.maker = "McLaren"
    sportCar.model = "570GT"
    sportCar.numberPlate = "203"

    let sportCar2 = SportCar(context: context)
    sportCar2.maker = "Lamborghini "
    sportCar2.model = "Aventador LP750-4"
    sportCar2.numberPlate = "204"

    let car = Car(context: context)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = "1"

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    try context.save()

    waitForExpectations(timeout: 2)
  }

  func testInsertedWithoutSavingOnDidSaveEvent() {
    let context = container.viewContext
    let observedEvent = ManagedObjectContextObservedEvent.didSave

    let expectation1 = expectation(description: "\(#function)\(#line)")
    expectation1.isInverted = true

    let observer = EntityObserver<SportCar>(context: context, event: observedEvent) { (change, event) in
      expectation1.fulfill()
    }
    XCTAssertEqual(observer.event, observedEvent)

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
  }

  func testRelationshipUpdatedOnDidSaveEvent() throws {
    let context = container.viewContext
    let observedEvent = ManagedObjectContextObservedEvent.didSave
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let sportCar1 = SportCar(context: context)
    sportCar1.maker = "McLaren"
    sportCar1.model = "570GT"
    sportCar1.numberPlate = "203"

    let sportCar2 = SportCar(context: context)
    sportCar2.maker = "Lamborghini "
    sportCar2.model = "Aventador LP750-4"
    sportCar2.numberPlate = "204"

    let expensiveSportCar1 = ExpensiveSportCar(context: context)
    expensiveSportCar1.maker = "BMW"
    expensiveSportCar1.model = "M6 Coupe"
    expensiveSportCar1.numberPlate = "300"
    expensiveSportCar1.isLimitedEdition = true

    let car1 = Car(context: context)
    car1.maker = "FIAT"
    car1.model = "Panda"
    car1.numberPlate = "1"

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    try context.save()

    let observer = EntityObserver<SportCar>(context: context, event: observedEvent) { (change, event) in
      XCTAssertEqual(observedEvent, event)
      XCTAssertTrue(change.insertedObjects.isEmpty)
      XCTAssertTrue(change.deletedObjects.isEmpty)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertEqual(change.updatedObjects.count, 2)
      for (_, car) in change.updatedObjects.enumerated() {
        XCTAssertTrue(car.owner === person1)
      }
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation1.fulfill()
    }
    XCTAssertEqual(observer.event, observedEvent)

    person1.cars = [sportCar1, sportCar2]
    expensiveSportCar1.numberPlate = expensiveSportCar1.numberPlate + " Updated"

    try context.save()

    waitForExpectations(timeout: 2)
  }

  func testDeleteOnDidSaveEvent() throws {
    let context = container.viewContext
    let observedEvent = ManagedObjectContextObservedEvent.didSave
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let sportCar = SportCar(context: context)
    sportCar.maker = "McLaren"
    sportCar.model = "570GT"
    sportCar.numberPlate = "203"

    let sportCar2 = SportCar(context: context)
    sportCar2.maker = "Lamborghini "
    sportCar2.model = "Aventador LP750-4"
    sportCar2.numberPlate = "204"

    let car = Car(context: context)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = "1"

    try context.save()

    let observer = EntityObserver<SportCar>(context: context, event: observedEvent) { (change, event) in
      XCTAssertEqual(observedEvent, event)
      XCTAssertTrue(change.insertedObjects.isEmpty)
      XCTAssertEqual(change.deletedObjects.count, 1)
      XCTAssertTrue(change.deletedObjects.first === sportCar)
      XCTAssertTrue(change.refreshedObjects.isEmpty)
      XCTAssertEqual(change.updatedObjects.count, 1)
      XCTAssertTrue(change.updatedObjects.first === sportCar2)
      XCTAssertTrue(change.invalidatedObjects.isEmpty)
      XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
      expectation1.fulfill()
    }
    XCTAssertEqual(observer.event, observedEvent)

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    car.numberPlate = car.numberPlate + " Updated"
    sportCar.numberPlate = sportCar.numberPlate + " Updated"
    sportCar2.numberPlate = sportCar.numberPlate + " Updated"
    context.delete(sportCar)

    try context.save()

    waitForExpectations(timeout: 2)
  }

  // MARK: - Change and Save Event

  func testMixChangesOnUpdateAndOnSave() throws {
    let context = container.viewContext
    let observedEvent: ManagedObjectContextObservedEvent = [.didChange, .didSave]
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")

    let sportCar1 = SportCar(context: context)
    sportCar1.maker = "McLaren"
    sportCar1.model = "570GT"
    sportCar1.numberPlate = "203"

    let sportCar2 = SportCar(context: context)
    sportCar2.maker = "Lamborghini "
    sportCar2.model = "Aventador LP750-4"
    sportCar2.numberPlate = "204"

    let car = Car(context: context)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = "1"

    try context.save()

    let observer = EntityObserver<SportCar>(context: context, event: observedEvent) { (change, event) in
      XCTAssertNotEqual(observedEvent, event)
      if event == .didChange {
        XCTAssertEqual(change.insertedObjects.count, 1)
        XCTAssertEqual(change.deletedObjects.count, 1)

        XCTAssertEqual(change.refreshedObjects.count, 1)
        XCTAssertEqual(change.updatedObjects.count, 1)

        XCTAssertTrue(change.invalidatedObjects.isEmpty)
        XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
        expectation1.fulfill()

      } else if event == .didSave {
        XCTAssertEqual(change.insertedObjects.count, 1)
        XCTAssertEqual(change.deletedObjects.count, 1)

        XCTAssertEqual(change.refreshedObjects.count, 0)
        XCTAssertEqual(change.updatedObjects.count, 1)

        XCTAssertTrue(change.invalidatedObjects.isEmpty)
        XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
        expectation2.fulfill()
      } else {
        XCTFail("The observed event doesn't exists.")
      }

    }
    XCTAssertEqual(observer.event, observedEvent)

    // Update sportCar1 and refreshed with merge
    // Delete sportCar2
    // Insert SportCar3

    sportCar1.numberPlate! += "Updated"
    sportCar1.refresh()
    context.delete(sportCar2)
    let sportCar3 = SportCar(context: context)
    sportCar3.maker = "Maserati"
    sportCar3.model = "GranTurismo MC"
    sportCar3.numberPlate = "202"

    car.numberPlate = "11111" // This is ignored because the observed entity is SportCar

    try context.save()
    waitForExpectations(timeout: 2)
  }

  func testMixChangesOnUpdateAndOnSaveInSubEntities() throws {
    let context = container.viewContext
    let observedEvent: ManagedObjectContextObservedEvent = [.didChange, .didSave]
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")

    let sportCar1 = SportCar(context: context)
    sportCar1.maker = "McLaren"
    sportCar1.model = "570GT"
    sportCar1.numberPlate = "203"

    let sportCar2 = SportCar(context: context)
    sportCar2.maker = "Lamborghini "
    sportCar2.model = "Aventador LP750-4"
    sportCar2.numberPlate = "204"

    let car = Car(context: context)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = "1"

    try context.save()

    let observer = EntityObserver<Car>(context: context, event: observedEvent, observeSubEntities: true) { (change, event) in
      XCTAssertNotEqual(observedEvent, event)
      if event == .didChange {
        XCTAssertEqual(change.insertedObjects.count, 1)
        XCTAssertEqual(change.deletedObjects.count, 1)

        XCTAssertEqual(change.refreshedObjects.count, 1)
        XCTAssertEqual(change.updatedObjects.count, 2)

        XCTAssertTrue(change.invalidatedObjects.isEmpty)
        XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
        expectation1.fulfill()

      } else if event == .didSave {
        XCTAssertEqual(change.insertedObjects.count, 1)
        XCTAssertEqual(change.deletedObjects.count, 1)

        XCTAssertEqual(change.refreshedObjects.count, 0)
        XCTAssertEqual(change.updatedObjects.count, 2)

        XCTAssertTrue(change.invalidatedObjects.isEmpty)
        XCTAssertTrue(change.invalidatedAllObjects.isEmpty)
        expectation2.fulfill()
      } else {
        XCTFail("The observed event doesn't exists.")
      }

    }
    XCTAssertEqual(observer.event, observedEvent)

    // Update sportCar1 and refreshed with merge
    // Delete sportCar2
    // Insert SportCar3
    // Update car

    sportCar1.numberPlate! += "Updated"
    sportCar1.refresh()
    context.delete(sportCar2)
    let sportCar3 = SportCar(context: context)
    sportCar3.maker = "Maserati"
    sportCar3.model = "GranTurismo MC"
    sportCar3.numberPlate = "202"

    car.numberPlate = "11111"

    try context.save()
    waitForExpectations(timeout: 2)
  }

}
