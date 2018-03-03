// 
// CoreDataPlus
//
// Copyright © 2016-2018 Tinrobots.
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

class EntityObserver2Tests: XCTestCase {

  // MARK: - Change Event

  func testInsertedOnChangeEvent() {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObservedEvent.onChange
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let observer = EntityObserver2<SportCar>(context: context, event: observedEvent) { (change, event) in
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(change.inserted.count, 1)
      XCTAssertTrue(change.deleted.isEmpty)
      XCTAssertTrue(change.refreshed.isEmpty)
      XCTAssertTrue(change.updated.isEmpty)
      XCTAssertTrue(change.invalidated.isEmpty)
      XCTAssertTrue(change.invalidatedAll.isEmpty)
      expectation1.fulfill()
    }
    XCTAssertEqual(observer.observedEntity, SportCar.entity())

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
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObservedEvent.onChange
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

    let observer = EntityObserver2<SportCar>(context: context, event: observedEvent) { (change, event) in
      XCTAssertEqual(observedEvent, event)
      XCTAssertTrue(change.inserted.isEmpty)
      XCTAssertTrue(change.deleted.isEmpty)
      XCTAssertTrue(change.refreshed.isEmpty)
      XCTAssertEqual(change.updated.count, 1)
      XCTAssertTrue(change.invalidated.isEmpty)
      XCTAssertTrue(change.invalidatedAll.isEmpty)
      expectation1.fulfill()
    }
    XCTAssertEqual(observer.observedEntity, SportCar.entity())

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    car.numberPlate = car.numberPlate + " Updated"
    sportCar.numberPlate = sportCar.numberPlate + " Updated"

    waitForExpectations(timeout: 2)
  }

  func testInsertedAndUpdatedOnChangeEvent() throws {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObservedEvent.onChange
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

    let observer = EntityObserver2<SportCar>(context: context, event: observedEvent) { (change, event) in
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(change.inserted.count, 1)
      XCTAssertTrue(change.deleted.isEmpty)
      XCTAssertTrue(change.refreshed.isEmpty)
      XCTAssertEqual(change.updated.count, 1)
      XCTAssertTrue(change.invalidated.isEmpty)
      XCTAssertTrue(change.invalidatedAll.isEmpty)
      expectation1.fulfill()
    }
    XCTAssertEqual(observer.observedEntity, SportCar.entity())

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
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObservedEvent.onChange
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

    let observer = EntityObserver2<SportCar>(context: context, event: observedEvent) { (change, event) in
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
    XCTAssertEqual(observer.observedEntity, SportCar.entity())

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    car.numberPlate = car.numberPlate + " Updated"
    sportCar.numberPlate = sportCar.numberPlate + " Updated"
    sportCar2.numberPlate = sportCar.numberPlate + " Updated"
    context.delete(sportCar)

    waitForExpectations(timeout: 2)
  }

}
