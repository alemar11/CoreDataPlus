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

class EntityObserverTests: XCTestCase {

  func testInsertedOnChangeEvent() {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObserverFrequency.onChange
    let entityObserver = EntityObserver<SportCar>(context: context, frequency: observedEvent)

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

    waitForExpectations(timeout: 10)
  }

  func testUpdatedOnChangeEvent() throws {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObserverFrequency.onChange
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

    let entityObserver = EntityObserver<SportCar>(context: context, frequency: observedEvent)
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

    let anyDelegate = AnyEntityObserverDelegate(delegate)
    entityObserver.delegate = anyDelegate

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    car.numberPlate = car.numberPlate + " Updated"
    sportCar.numberPlate = sportCar.numberPlate + " Updated"

    waitForExpectations(timeout: 10)
  }

  func testDeleteOnChangeEvent() throws {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObserverFrequency.onChange
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

    let entityObserver = EntityObserver<SportCar>(context: context, frequency: observedEvent)
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

    let anyDelegate = AnyEntityObserverDelegate(delegate)
    entityObserver.delegate = anyDelegate

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    car.numberPlate = car.numberPlate + " Updated"
    sportCar.numberPlate = sportCar.numberPlate + " Updated"
    sportCar2.numberPlate = sportCar.numberPlate + " Updated"
    context.delete(sportCar)

    waitForExpectations(timeout: 10)
  }

  func testFilteredUpdatedOnChangeEvent() throws {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObserverFrequency.onChange
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

    let predicate = NSPredicate(format: "SELF == %@", sportCar2)
    let entityObserver = EntityObserver<SportCar>(context: context, frequency: observedEvent, filterBy: predicate)

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
      XCTAssertTrue(updated.first! === sportCar2)
      expectation1.fulfill()
    }

    delegate.onRefreshed = { refreshed, event, observer in
      XCTFail("There shouldn't be refreshed objects.")
    }

    delegate.onInvalidated = { invalidated, event, observer in
      XCTFail("There shouldn't be invalidated objects.")
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

    waitForExpectations(timeout: 10)
  }

  func testRelationshipUpdatedOnChangeEvent() throws {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let observedEvent = ObserverFrequency.onChange
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

    let entityObserver = EntityObserver<SportCar>(context: context, frequency: observedEvent)

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

    let anyDelegate = AnyEntityObserverDelegate(delegate)
    entityObserver.delegate = anyDelegate

    person1.cars = [sportCar1, sportCar2]
    expensiveSportCar1.numberPlate = expensiveSportCar1.numberPlate + " Updated"

    waitForExpectations(timeout: 10)
  }

  // MARK: - Utils

  fileprivate class DummyEntityObserverDelegate<T: NSManagedObject> : EntityObserverDelegate {
    typealias ManagedObject = T

    var onInserted: (Set<ManagedObject>, ObserverFrequency, EntityObserver<ManagedObject>) -> Void = { _,_,_ in }
    var onDeleted: (Set<ManagedObject>, ObserverFrequency, EntityObserver<ManagedObject>) -> Void = { _,_,_ in }
    var onUpdated: (Set<ManagedObject>, ObserverFrequency, EntityObserver<ManagedObject>) -> Void = { _,_,_ in }
    var onRefreshed: (Set<ManagedObject>, ObserverFrequency, EntityObserver<ManagedObject>) -> Void = { _,_,_ in }
    var onInvalidated: (Set<ManagedObject>, ObserverFrequency, EntityObserver<ManagedObject>) -> Void = { _,_,_ in}

    func entityObserver(_ observer: EntityObserver<ManagedObject>, inserted: Set<ManagedObject>, event: ObserverFrequency) {
      onInserted(inserted, event, observer)
    }

    func entityObserver(_ observer: EntityObserver<ManagedObject>, deleted: Set<ManagedObject>, event: ObserverFrequency) {
      onDeleted(deleted, event, observer)
    }

    func entityObserver(_ observer: EntityObserver<ManagedObject>, updated: Set<ManagedObject>, event: ObserverFrequency) {
      onUpdated(updated, event, observer)
    }

    func entityObserver(_ observer: EntityObserver<ManagedObject>, refreshed: Set<ManagedObject>, event: ObserverFrequency) {
      onRefreshed(refreshed, event, observer)
    }

    func entityObserver(_ observer: EntityObserver<ManagedObject>, invalidated: Set<ManagedObject>, event: ObserverFrequency) {
      onInvalidated(invalidated, event, observer)
    }
  }

}
