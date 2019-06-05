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

  func testInsertedOnChangeEvent() {
    let context = container.viewContext
    let observedEvent = ObservedManagedObjectContextEvent.didChange
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let observer = EntityObserver<SportCar>(context: context, event: observedEvent) { (change, event) in
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(change.inserted.count, 1)
      XCTAssertTrue(change.deleted.isEmpty)
      XCTAssertTrue(change.refreshed.isEmpty)
      XCTAssertTrue(change.updated.isEmpty)
      XCTAssertTrue(change.invalidated.isEmpty)
      XCTAssertTrue(change.invalidatedAll.isEmpty)
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

  func testUpdatedOnChangeEvent() throws {
    let context = container.viewContext
    let observedEvent = ObservedManagedObjectContextEvent.didChange
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
      XCTAssertTrue(change.inserted.isEmpty)
      XCTAssertTrue(change.deleted.isEmpty)
      XCTAssertTrue(change.refreshed.isEmpty)
      XCTAssertEqual(change.updated.count, 1)
      XCTAssertTrue(change.invalidated.isEmpty)
      XCTAssertTrue(change.invalidatedAll.isEmpty)
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

  func testInsertedAndUpdatedOnChangeEvent() throws {
    let context = container.viewContext
    let observedEvent = ObservedManagedObjectContextEvent.didChange
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
      XCTAssertEqual(change.inserted.count, 1)
      XCTAssertTrue(change.deleted.isEmpty)
      XCTAssertTrue(change.refreshed.isEmpty)
      XCTAssertEqual(change.updated.count, 1)
      XCTAssertTrue(change.invalidated.isEmpty)
      XCTAssertTrue(change.invalidatedAll.isEmpty)
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

  func testDeleteOnChangeEvent() throws {
    let context = container.viewContext
    let observedEvent = ObservedManagedObjectContextEvent.didChange
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
      XCTAssertTrue(change.inserted.isEmpty)
      XCTAssertEqual(change.deleted.count, 1)
      XCTAssertTrue(change.deleted.first === sportCar)
      XCTAssertTrue(change.refreshed.isEmpty)
      XCTAssertEqual(change.updated.count, 1)
      XCTAssertTrue(change.updated.first === sportCar2)
      XCTAssertTrue(change.invalidated.isEmpty)
      XCTAssertTrue(change.invalidatedAll.isEmpty)
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


  func testRefreshedOnChangeEvent() throws {
    let context = container.viewContext
    let observedEvent = ObservedManagedObjectContextEvent.didChange
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
      XCTAssertTrue(change.inserted.isEmpty)
      XCTAssertTrue(change.deleted.isEmpty)
      XCTAssertEqual(change.refreshed.count, 2)
      XCTAssertEqual(change.updated.count, 1)
      XCTAssertTrue(change.updated.first === sportCar1)
      XCTAssertTrue(change.invalidated.isEmpty)
      XCTAssertTrue(change.invalidatedAll.isEmpty)
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

  func testInvalidatedAllOnChangeEvent() throws {
    let context = container.viewContext
    let observedEvent = ObservedManagedObjectContextEvent.didChange
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
      XCTAssertTrue(change.inserted.isEmpty)
      XCTAssertTrue(change.deleted.isEmpty)
      XCTAssertTrue(change.refreshed.isEmpty)
      XCTAssertTrue(change.updated.isEmpty)
      XCTAssertTrue(change.invalidated.isEmpty)
      XCTAssertEqual(change.invalidatedAll.count, 2) // sportCar1 and sportCar2
      XCTAssertTrue(change.invalidatedAll.contains(sportCar1.objectID))
      XCTAssertTrue(change.invalidatedAll.contains(sportCar2.objectID))
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

  func testRelationshipUpdatedOnChangeEvent() throws {
    let context = container.viewContext
    let observedEvent = ObservedManagedObjectContextEvent.didChange
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
      XCTAssertTrue(change.inserted.isEmpty)
      XCTAssertTrue(change.deleted.isEmpty)
      XCTAssertTrue(change.refreshed.isEmpty)
      XCTAssertEqual(change.updated.count, 2)
      XCTAssertTrue(change.invalidated.isEmpty)
      XCTAssertTrue(change.invalidatedAll.isEmpty)
      expectation1.fulfill()
    }
    XCTAssertEqual(observer.event, observedEvent)

    person1.cars = [sportCar1, sportCar2]
    expensiveSportCar1.numberPlate = expensiveSportCar1.numberPlate + " Updated"

    waitForExpectations(timeout: 2)
  }

  // MARK: - Save Event

  func testInsertedOnSaveEvent() throws {
    let context = container.viewContext
    let observedEvent = ObservedManagedObjectContextEvent.didSave
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let observer = EntityObserver<SportCar>(context: context, event: observedEvent) { (change, event) in
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(change.inserted.count, 2)
      XCTAssertTrue(change.deleted.isEmpty)
      XCTAssertTrue(change.refreshed.isEmpty)
      XCTAssertTrue(change.updated.isEmpty)
      XCTAssertTrue(change.invalidated.isEmpty)
      XCTAssertTrue(change.invalidatedAll.isEmpty)
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

  func testInsertedWithoutSavingOnSaveEvent() {
    let context = container.viewContext
    let observedEvent = ObservedManagedObjectContextEvent.didSave

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

  func testRelationshipUpdatedOnSaveEvent() throws {
    let context = container.viewContext
    let observedEvent = ObservedManagedObjectContextEvent.didSave
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
      XCTAssertTrue(change.inserted.isEmpty)
      XCTAssertTrue(change.deleted.isEmpty)
      XCTAssertTrue(change.refreshed.isEmpty)
      XCTAssertEqual(change.updated.count, 2)
      for (_, car) in change.updated.enumerated() {
        XCTAssertTrue(car.owner === person1)
      }
      XCTAssertTrue(change.invalidated.isEmpty)
      XCTAssertTrue(change.invalidatedAll.isEmpty)
      expectation1.fulfill()
    }
    XCTAssertEqual(observer.event, observedEvent)

    person1.cars = [sportCar1, sportCar2]
    expensiveSportCar1.numberPlate = expensiveSportCar1.numberPlate + " Updated"

    try context.save()

    waitForExpectations(timeout: 2)
  }

  func testDeleteOnSaveEvent() throws {
    let context = container.viewContext
    let observedEvent = ObservedManagedObjectContextEvent.didSave
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
      XCTAssertTrue(change.inserted.isEmpty)
      XCTAssertEqual(change.deleted.count, 1)
      XCTAssertTrue(change.deleted.first === sportCar)
      XCTAssertTrue(change.refreshed.isEmpty)
      XCTAssertEqual(change.updated.count, 1)
      XCTAssertTrue(change.updated.first === sportCar2)
      XCTAssertTrue(change.invalidated.isEmpty)
      XCTAssertTrue(change.invalidatedAll.isEmpty)
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
    let observedEvent = ObservedManagedObjectContextEvent.all
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
        XCTAssertEqual(change.inserted.count, 1)
        XCTAssertEqual(change.deleted.count, 1)

        XCTAssertEqual(change.refreshed.count, 1)
        XCTAssertEqual(change.updated.count, 1)

        XCTAssertTrue(change.invalidated.isEmpty)
        XCTAssertTrue(change.invalidatedAll.isEmpty)
        expectation1.fulfill()

      } else if event == .didSave {
        XCTAssertEqual(change.inserted.count, 1)
        XCTAssertEqual(change.deleted.count, 1)

        XCTAssertEqual(change.refreshed.count, 0)
        XCTAssertEqual(change.updated.count, 1)

        XCTAssertTrue(change.invalidated.isEmpty)
        XCTAssertTrue(change.invalidatedAll.isEmpty)
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
    let observedEvent = ObservedManagedObjectContextEvent.all
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
        XCTAssertEqual(change.inserted.count, 1)
        XCTAssertEqual(change.deleted.count, 1)

        XCTAssertEqual(change.refreshed.count, 1)
        XCTAssertEqual(change.updated.count, 2)

        XCTAssertTrue(change.invalidated.isEmpty)
        XCTAssertTrue(change.invalidatedAll.isEmpty)
        expectation1.fulfill()

      } else if event == .didSave {
        XCTAssertEqual(change.inserted.count, 1)
        XCTAssertEqual(change.deleted.count, 1)

        XCTAssertEqual(change.refreshed.count, 0)
        XCTAssertEqual(change.updated.count, 2)

        XCTAssertTrue(change.invalidated.isEmpty)
        XCTAssertTrue(change.invalidatedAll.isEmpty)
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
