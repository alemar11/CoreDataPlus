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

/**
 - Add more tests with filters
 - Add tests for both onSave & onChange
 - Add tests with different contexts
 */

class EntityObserverTests: XCTestCase {

  // MARK: - Change Event

  func testInsertedOnChangeEvent() {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObservedEvent.onChange
    let entityObserver = EntityObserver<SportCar>(context: context, event: observedEvent)

    let personz = NSEntityDescription.insertNewObject(forEntityName: "Person", into: context) as? Person
XCTAssertNotNil(personz)
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let delegate = DummyEntityObserverDelegate<SportCar>()
    delegate.onInserted = { inserted, event, observer in
      XCTAssertTrue(observer === entityObserver)
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(inserted.count, 1)
      expectation1.fulfill()
    }

    delegate.onDeleted = { deleted, event, observer in
      XCTFail("There shouldn't be deleted objects.")
    }

    delegate.onUpdated = { updated, event, observer in
      XCTFail("There shouldn't be updated objects.")
    }

    delegate.onRefreshed = { refreshed, event, observer in
      XCTFail("There shouldn't be refreshed objects.")
    }

    delegate.onInvalidated = { invalidated, event, observer in
      XCTFail("There shouldn't be invalidated objects.")
    }

    delegate.onIvalidatedAll = { event, observer in
      XCTFail("There shouldn't an invalidated all event.")
    }

    let anyDelegate = AnyEntityObserverDelegate(delegate)
    entityObserver.delegate = anyDelegate

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

    let entityObserver = EntityObserver<SportCar>(context: context, event: observedEvent)
    let delegate = DummyEntityObserverDelegate<SportCar>()
    delegate.onInserted = { inserted, event, observer in
      XCTFail("There shouldn't be inserted objects.")
    }

    delegate.onDeleted = { deleted, event, observer in
      XCTFail("There shouldn't be deleted objects.")
    }

    delegate.onUpdated = { updated, event, observer in
      XCTAssertTrue(observer === entityObserver)
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(updated.count, 1)
      expectation1.fulfill()
    }

    delegate.onRefreshed = { refreshed, event, observer in
      XCTFail("There shouldn't be refreshed objects.")
    }

    delegate.onInvalidated = { invalidated, event, observer in
      XCTFail("There shouldn't be invalidated objects.")
    }

    delegate.onIvalidatedAll = { event, observer in
      XCTFail("There shouldn't an invalidated all event.")
    }

    let anyDelegate = AnyEntityObserverDelegate(delegate)
    entityObserver.delegate = anyDelegate

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    car.numberPlate = car.numberPlate + " Updated"
    sportCar.numberPlate = sportCar.numberPlate + " Updated"

    waitForExpectations(timeout: 2)
  }

  func testDeleteOnChangeEvent() throws {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObservedEvent.onChange
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")

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

    let entityObserver = EntityObserver<SportCar>(context: context, event: observedEvent)
    let delegate = DummyEntityObserverDelegate<SportCar>()
    delegate.onInserted = { inserted, event, observer in
      XCTFail("There shouldn't be inserted objects.")
    }

    delegate.onDeleted = { deleted, event, observer in
      XCTAssertTrue(observer === entityObserver)
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(deleted.count, 1)
      XCTAssertTrue(deleted.first === sportCar)
      expectation2.fulfill()
    }

    delegate.onUpdated = { updated, event, observer in
      XCTAssertTrue(observer === entityObserver)
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(updated.count, 1)
      XCTAssertTrue(updated.first === sportCar2)
      expectation1.fulfill()
    }

    delegate.onRefreshed = { refreshed, event, observer in
      XCTFail("There shouldn't be refreshed objects.")
    }

    delegate.onInvalidated = { invalidated, event, observer in
      XCTFail("There shouldn't be invalidated objects.")
    }

    delegate.onIvalidatedAll = { event, observer in
      XCTFail("There shouldn't an invalidated all event.")
    }

    let anyDelegate = AnyEntityObserverDelegate(delegate)
    entityObserver.delegate = anyDelegate

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    car.numberPlate = car.numberPlate + " Updated"
    sportCar.numberPlate = sportCar.numberPlate + " Updated"
    sportCar2.numberPlate = sportCar.numberPlate + " Updated"
    context.delete(sportCar)

    waitForExpectations(timeout: 2)
  }

//  func testFilteredUpdatedOnChangeEvent() throws {
//    let stack = CoreDataStack.stack()
//    let context = stack.mainContext
//    let observedEvent = ObservedEvent.onChange
//    let expectation1 = expectation(description: "\(#function)\(#line)")
//
//    let sportCar1 = SportCar(context: context)
//    sportCar1.maker = "McLaren"
//    sportCar1.model = "570GT"
//    sportCar1.numberPlate = "203"
//
//    let sportCar2 = SportCar(context: context)
//    sportCar2.maker = "Lamborghini "
//    sportCar2.model = "Aventador LP750-4"
//    sportCar2.numberPlate = "204"
//
//    let expensiveSportCar1 = ExpensiveSportCar(context: context)
//    expensiveSportCar1.maker = "BMW"
//    expensiveSportCar1.model = "M6 Coupe"
//    expensiveSportCar1.numberPlate = "300"
//    expensiveSportCar1.isLimitedEdition = true
//
//    let car1 = Car(context: context)
//    car1.maker = "FIAT"
//    car1.model = "Panda"
//    car1.numberPlate = "1"
//
//    try context.save()
//
//    let predicate = NSPredicate(format: "SELF == %@", sportCar2)
//    let entityObserver = EntityObserver<SportCar>(context: context, event: observedEvent, filterBy: predicate)
//
//    let delegate = DummyEntityObserverDelegate<SportCar>()
//    delegate.onInserted = { inserted, event, observer in
//      XCTFail("There shouldn't be inserted objects.")
//    }
//
//    delegate.onDeleted = { deleted, event, observer in
//      XCTFail("There shouldn't be deleted objects.")
//    }
//
//    delegate.onUpdated = { updated, event, observer in
//      XCTAssertTrue(observer === entityObserver)
//      XCTAssertEqual(observedEvent, event)
//      XCTAssertEqual(updated.count, 1)
//      XCTAssertTrue(updated.first! === sportCar2)
//      expectation1.fulfill()
//    }
//
//    delegate.onRefreshed = { refreshed, event, observer in
//      XCTFail("There shouldn't be refreshed objects.")
//    }
//
//    delegate.onInvalidated = { invalidated, event, observer in
//      XCTFail("There shouldn't be invalidated objects.")
//    }
//
//    delegate.onIvalidatedAll = { event, observer in
//      XCTFail("There shouldn't an invalidated all event.")
//    }
//
//    let anyDelegate = AnyEntityObserverDelegate(delegate)
//    entityObserver.delegate = anyDelegate
//
//    let person1 = Person(context: context)
//    person1.firstName = "Edythe"
//    person1.lastName = "Moreton"
//
//    context.delete(car1)
//    sportCar1.numberPlate = sportCar1.numberPlate + " Updated"
//    sportCar2.numberPlate = sportCar2.numberPlate + " Updated"
//    expensiveSportCar1.numberPlate = expensiveSportCar1.numberPlate + " Updated"
//
//    waitForExpectations(timeout: 2)
//  }

  func testRefreshedOnChangeEvent() throws {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObservedEvent.onChange
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

    let entityObserver = EntityObserver<SportCar>(context: context, event: observedEvent)

    let delegate = DummyEntityObserverDelegate<SportCar>()
    delegate.onInserted = { inserted, event, observer in
      XCTFail("There shouldn't be inserted objects.")
    }

    delegate.onDeleted = { deleted, event, observer in
      XCTFail("There shouldn't be deleted objects.")
    }

    delegate.onUpdated = { updated, event, observer in
      XCTAssertTrue(observer === entityObserver)
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(updated.count, 1)
      XCTAssertTrue(updated.first! === sportCar1)
      expectation1.fulfill()
    }

    delegate.onRefreshed = { refreshed, event, observer in
      XCTAssertTrue(observer === entityObserver)
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(refreshed.count, 2)
      expectation2.fulfill()
    }

    delegate.onInvalidated = { invalidated, event, observer in
      XCTFail("There shouldn't be invalidated objects.")
    }

    delegate.onIvalidatedAll = { event, observer in
      XCTFail("There shouldn't an invalidated all event.")
    }

    let anyDelegate = AnyEntityObserverDelegate(delegate)
    entityObserver.delegate = anyDelegate

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
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObservedEvent.onChange
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

    let entityObserver = EntityObserver<SportCar>(context: context, event: observedEvent)

    let delegate = DummyEntityObserverDelegate<SportCar>()
    delegate.onInserted = { inserted, event, observer in
      XCTFail("There shouldn't be inserted objects.")
    }

    delegate.onDeleted = { deleted, event, observer in
      XCTFail("There shouldn't be deleted objects.")
    }

    delegate.onUpdated = { updated, event, observer in
      XCTFail("There shouldn't be updated objects.")
    }

    delegate.onRefreshed = { refreshed, event, observer in
      XCTFail("There shouldn't be refreshed objects.")
    }

    delegate.onInvalidated = { invalidated, event, observer in
      XCTFail("There shouldn't be invalidated objects.")
    }

    delegate.onIvalidatedAll = { event, observer in
      expectation1.fulfill()
    }

    let anyDelegate = AnyEntityObserverDelegate(delegate)
    entityObserver.delegate = anyDelegate

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
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObservedEvent.onChange
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

    let entityObserver = EntityObserver<SportCar>(context: context, event: observedEvent)

    let delegate = DummyEntityObserverDelegate<SportCar>()
    delegate.onInserted = { inserted, event, observer in
      XCTFail("There shouldn't be inserted objects.")
    }

    delegate.onDeleted = { deleted, event, observer in
      XCTFail("There shouldn't be deleted objects.")
    }

    delegate.onUpdated = { updated, event, observer in
      XCTAssertTrue(observer === entityObserver)
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(updated.count, 2)

      for car in updated {
        XCTAssertTrue(car.owner === person1)
      }

      expectation1.fulfill()
    }

    delegate.onRefreshed = { refreshed, event, observer in
      XCTFail("There shouldn't be refreshed objects.")
    }

    delegate.onInvalidated = { invalidated, event, observer in
      XCTFail("There shouldn't be invalidated objects.")
    }

    delegate.onIvalidatedAll = { event, observer in
      XCTFail("There shouldn't an invalidated all event.")
    }

    let anyDelegate = AnyEntityObserverDelegate(delegate)
    entityObserver.delegate = anyDelegate

    person1.cars = [sportCar1, sportCar2]
    expensiveSportCar1.numberPlate = expensiveSportCar1.numberPlate + " Updated"

    waitForExpectations(timeout: 2)
  }

  // MARK: - Save Event

  func testInsertedOnSaveEvent() throws {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObservedEvent.onSave
    let entityObserver = EntityObserver<SportCar>(context: context, event: observedEvent)

    let expectation1 = expectation(description: "\(#function)\(#line)")

    let delegate = DummyEntityObserverDelegate<SportCar>()
    delegate.onInserted = { inserted, event, observer in
      XCTAssertTrue(observer === entityObserver)
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(inserted.count, 2)
      expectation1.fulfill()
    }

    delegate.onDeleted = { deleted, event, observer in
      XCTFail("There shouldn't be deleted objects.")
    }

    delegate.onUpdated = { updated, event, observer in
      XCTFail("There shouldn't be updated objects.")
    }

    delegate.onRefreshed = { refreshed, event, observer in
      XCTFail("There shouldn't be refreshed objects.")
    }

    delegate.onInvalidated = { invalidated, event, observer in
      XCTFail("There shouldn't be invalidated objects.")
    }

    delegate.onIvalidatedAll = { event, observer in
      XCTFail("There shouldn't an invalidated all event.")
    }

    let anyDelegate = AnyEntityObserverDelegate(delegate)
    entityObserver.delegate = anyDelegate

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
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObservedEvent.onSave
    let entityObserver = EntityObserver<SportCar>(context: context, event: observedEvent)

    let expectation1 = expectation(description: "\(#function)\(#line)")
    expectation1.isInverted = true

    let delegate = DummyEntityObserverDelegate<SportCar>()
    delegate.onInserted = { inserted, event, observer in
      expectation1.fulfill()
    }

    delegate.onDeleted = { deleted, event, observer in
      XCTFail("There shouldn't be deleted objects.")
    }

    delegate.onUpdated = { updated, event, observer in
      XCTFail("There shouldn't be updated objects.")
    }

    delegate.onRefreshed = { refreshed, event, observer in
      XCTFail("There shouldn't be refreshed objects.")
    }

    delegate.onInvalidated = { invalidated, event, observer in
      XCTFail("There shouldn't be invalidated objects.")
    }

    delegate.onIvalidatedAll = { event, observer in
      XCTFail("There shouldn't an invalidated all event.")
    }

    let anyDelegate = AnyEntityObserverDelegate(delegate)
    entityObserver.delegate = anyDelegate

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
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObservedEvent.onSave
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

    let entityObserver = EntityObserver<SportCar>(context: context, event: observedEvent)

    let delegate = DummyEntityObserverDelegate<SportCar>()
    delegate.onInserted = { inserted, event, observer in
      XCTFail("There shouldn't be inserted objects.")
    }

    delegate.onDeleted = { deleted, event, observer in
      XCTFail("There shouldn't be deleted objects.")
    }

    delegate.onUpdated = { updated, event, observer in
      XCTAssertTrue(observer === entityObserver)
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(updated.count, 2)

      for car in updated {
        XCTAssertTrue(car.owner === person1)
      }

      expectation1.fulfill()
    }

    delegate.onRefreshed = { refreshed, event, observer in
      XCTFail("There shouldn't be refreshed objects.")
    }

    delegate.onInvalidated = { invalidated, event, observer in
      XCTFail("There shouldn't be invalidated objects.")
    }

    delegate.onIvalidatedAll = { event, observer in
      XCTFail("There shouldn't an invalidated all event.")
    }

    let anyDelegate = AnyEntityObserverDelegate(delegate)
    entityObserver.delegate = anyDelegate

    person1.cars = [sportCar1, sportCar2]
    expensiveSportCar1.numberPlate = expensiveSportCar1.numberPlate + " Updated"

    try context.save()

    waitForExpectations(timeout: 2)
  }


//  func testFilteredUpdatedOnSaveEvent() throws {
//    let stack = CoreDataStack.stack()
//    let context = stack.mainContext
//    let observedEvent = ObservedEvent.onSave
//    let expectation1 = expectation(description: "\(#function)\(#line)")
//
//    let sportCar1 = SportCar(context: context)
//    sportCar1.maker = "McLaren"
//    sportCar1.model = "570GT"
//    sportCar1.numberPlate = "203"
//
//    let sportCar2 = SportCar(context: context)
//    sportCar2.maker = "Lamborghini "
//    sportCar2.model = "Aventador LP750-4"
//    sportCar2.numberPlate = "204"
//
//    let expensiveSportCar1 = ExpensiveSportCar(context: context)
//    expensiveSportCar1.maker = "BMW"
//    expensiveSportCar1.model = "M6 Coupe"
//    expensiveSportCar1.numberPlate = "300"
//    expensiveSportCar1.isLimitedEdition = true
//
//    let car1 = Car(context: context)
//    car1.maker = "FIAT"
//    car1.model = "Panda"
//    car1.numberPlate = "1"
//
//    try context.save()
//
//    let predicate = NSPredicate(format: "SELF == %@", sportCar2)
//    let entityObserver = EntityObserver<SportCar>(context: context, event: observedEvent, filterBy: predicate)
//
//    let delegate = DummyEntityObserverDelegate<SportCar>()
//    delegate.onInserted = { inserted, event, observer in
//      XCTFail("There shouldn't be inserted objects.")
//    }
//
//    delegate.onDeleted = { deleted, event, observer in
//      XCTFail("There shouldn't be deleted objects.")
//    }
//
//    delegate.onUpdated = { updated, event, observer in
//      XCTAssertTrue(observer === entityObserver)
//      XCTAssertEqual(observedEvent, event)
//      XCTAssertEqual(updated.count, 1)
//      XCTAssertTrue(updated.first! === sportCar2)
//      expectation1.fulfill()
//    }
//
//    delegate.onRefreshed = { refreshed, event, observer in
//      XCTFail("There shouldn't be refreshed objects.")
//    }
//
//    delegate.onInvalidated = { invalidated, event, observer in
//      XCTFail("There shouldn't be invalidated objects.")
//    }
//
//    delegate.onIvalidatedAll = { event, observer in
//      XCTFail("There shouldn't an invalidated all event.")
//    }
//
//    let anyDelegate = AnyEntityObserverDelegate(delegate)
//    entityObserver.delegate = anyDelegate
//
//    let person1 = Person(context: context)
//    person1.firstName = "Edythe"
//    person1.lastName = "Moreton"
//
//    context.delete(car1)
//    sportCar1.numberPlate = sportCar1.numberPlate + " Updated"
//    sportCar2.numberPlate = sportCar2.numberPlate + " Updated"
//    expensiveSportCar1.numberPlate = expensiveSportCar1.numberPlate + " Updated"
//
//    try context.save()
//
//    waitForExpectations(timeout: 2)
//  }


  func testDeleteOnSaveEvent() throws {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObservedEvent.onSave
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")

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

    let entityObserver = EntityObserver<SportCar>(context: context, event: observedEvent)
    let delegate = DummyEntityObserverDelegate<SportCar>()
    delegate.onInserted = { inserted, event, observer in
      XCTFail("There shouldn't be inserted objects.")
    }

    delegate.onDeleted = { deleted, event, observer in
      XCTAssertTrue(observer === entityObserver)
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(deleted.count, 1)
      XCTAssertTrue(deleted.first === sportCar)
      expectation2.fulfill()
    }

    delegate.onUpdated = { updated, event, observer in
      XCTAssertTrue(observer === entityObserver)
      XCTAssertEqual(observedEvent, event)
      XCTAssertEqual(updated.count, 1)
      XCTAssertTrue(updated.first === sportCar2)
      expectation1.fulfill()
    }

    delegate.onRefreshed = { refreshed, event, observer in
      XCTFail("There shouldn't be refreshed objects.")
    }

    delegate.onInvalidated = { invalidated, event, observer in
      XCTFail("There shouldn't be invalidated objects.")
    }

    delegate.onIvalidatedAll = { event, observer in
      XCTFail("There shouldn't an invalidated all event.")
    }

    let anyDelegate = AnyEntityObserverDelegate(delegate)
    entityObserver.delegate = anyDelegate

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

  // MARK: - Change and Save Events

  // MARK: - Utils

  fileprivate class DummyEntityObserverDelegate<T: NSManagedObject> : EntityObserverDelegate {
    typealias ManagedObject = T

    var onInserted: (Set<ManagedObject>, ObservedEvent, EntityObserver<ManagedObject>) -> Void = { _,_,_ in }
    var onDeleted: (Set<ManagedObject>, ObservedEvent, EntityObserver<ManagedObject>) -> Void = { _,_,_ in }
    var onUpdated: (Set<ManagedObject>, ObservedEvent, EntityObserver<ManagedObject>) -> Void = { _,_,_ in }
    var onRefreshed: (Set<ManagedObject>, ObservedEvent, EntityObserver<ManagedObject>) -> Void = { _,_,_ in }
    var onInvalidated: (Set<ManagedObject>, ObservedEvent, EntityObserver<ManagedObject>) -> Void = { _,_,_ in}
    var onIvalidatedAll: (ObservedEvent, EntityObserver<ManagedObject>) -> Void = { _,_  in }

    func entityObserver(_ observer: EntityObserver<ManagedObject>, inserted: Set<ManagedObject>, event: ObservedEvent) {
      onInserted(inserted, event, observer)
    }

    func entityObserver(_ observer: EntityObserver<ManagedObject>, deleted: Set<ManagedObject>, event: ObservedEvent) {
      onDeleted(deleted, event, observer)
    }

    func entityObserver(_ observer: EntityObserver<ManagedObject>, updated: Set<ManagedObject>, event: ObservedEvent) {
      onUpdated(updated, event, observer)
    }

    func entityObserver(_ observer: EntityObserver<ManagedObject>, refreshed: Set<ManagedObject>, event: ObservedEvent) {
      onRefreshed(refreshed, event, observer)
    }

    func entityObserver(_ observer: EntityObserver<ManagedObject>, invalidated: Set<ManagedObject>, event: ObservedEvent) {
      onInvalidated(invalidated, event, observer)
    }

    func entityObserver(_ observer: EntityObserver<T>, allObjectsInvalidatedForEvent event: ObservedEvent) {
      onIvalidatedAll(event, observer)
    }
  }

}
