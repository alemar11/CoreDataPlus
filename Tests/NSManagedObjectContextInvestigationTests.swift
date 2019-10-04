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

import CoreData
import XCTest

final class NSManagedObjectContextInvestigationTests: CoreDataPlusInMemoryTestCase {
  /// Investigation test: calling refreshAllObjects calls refreshObject:mergeChanges on all objects in the context.
  func testInvestigationRefreshAllObjects() throws {
    let context = container.viewContext
    let car1 = Car(context: context)
    car1.numberPlate = "car1"
    let car2 = Car(context: context)
    car2.numberPlate = "car2"

    try context.save()

    car1.numberPlate = "car1_updated"
    context.refreshAllObjects()

    XCTAssertFalse(car1.isFault)
    XCTAssertTrue(car2.isFault)
    XCTAssertEqual(car1.numberPlate, "car1_updated")
  }

  /// Investigation test: KVO is fired whenever a property changes (even if the object is not saved in the context).
  func testInvestigationKVO() throws {
    let context = container.viewContext
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let sportCar1 = SportCar(context: context)
    var count = 0
    let token = sportCar1.observe(\.maker, options: .new) { (car, changes) in
      count += 1
      if count == 2 {
        expectation.fulfill()
      }
    }
    sportCar1.maker = "McLaren"
    sportCar1.model = "570GT"
    sportCar1.numberPlate = "203"
    sportCar1.maker = "McLaren 2"
    try context.save()

    waitForExpectations(timeout: 10)
    token.invalidate()
  }

  /// Investigation test: automaticallyMergesChangesFromParent behaviour
  func testInvestigationautomaticallyMergesChangesFromParent() throws {
    // automaticallyMergesChangesFromParent = true
    do {
      let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
      let storeURL = URL.newDatabaseURL(withID: UUID())
      try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)

      let parentContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
      parentContext.persistentStoreCoordinator = psc

      let car1 = Car(context: parentContext)
      car1.maker = "FIAT"
      car1.model = "Panda"
      car1.numberPlate = UUID().uuidString
      car1.maker = "maker"
      try parentContext.save()

      let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
      childContext.parent = parentContext
      childContext.automaticallyMergesChangesFromParent = true

      let childCar = try childContext.performAndWait { context -> Car in
        let car = try childContext.existingObject(with: car1.objectID) as! Car
        XCTAssertEqual(car.maker, "maker")
        return car
      }

      try parentContext.performSaveAndWait { context in
        let car = try context.existingObject(with: car1.objectID) as! Car
        XCTAssertEqual(car.maker, "maker")
        car.maker = "😀"
        XCTAssertEqual(car.maker, "😀")
      }

      // this will fail without automaticallyMergesChangesFromParent to true
      XCTAssertEqual(childCar.safeAccess({ $0.maker }), "😀")
    }

    // automaticallyMergesChangesFromParent = false
    do {
      let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
      let storeURL = URL.newDatabaseURL(withID: UUID())
      try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)

      let parentContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
      parentContext.persistentStoreCoordinator = psc

      let car1 = Car(context: parentContext)
      car1.maker = "FIAT"
      car1.model = "Panda"
      car1.numberPlate = UUID().uuidString
      car1.maker = "maker"
      try parentContext.save()

      let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
      childContext.parent = parentContext
      childContext.automaticallyMergesChangesFromParent = false

      let childCar = try childContext.performAndWait { context -> Car in
        let car = try childContext.existingObject(with: car1.objectID) as! Car
        XCTAssertEqual(car.maker, "maker")
        return car
      }

      try parentContext.performSaveAndWait { context in
        let car = try context.existingObject(with: car1.objectID) as! Car
        XCTAssertEqual(car.maker, "maker")
        car.maker = "😀"
        XCTAssertEqual(car.maker, "😀")
      }

      XCTAssertEqual(childCar.safeAccess({ $0.maker }), "maker") // no changes
    }

    // automaticallyMergesChangesFromParent = true
    do {
      let parentContext = container.viewContext

      let car1 = Car(context: parentContext)
      car1.maker = "FIAT"
      car1.model = "Panda"
      car1.numberPlate = UUID().uuidString
      car1.maker = "maker"
      try parentContext.save()

      let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
      childContext.parent = parentContext
      childContext.automaticallyMergesChangesFromParent = true

      let childCar = try childContext.performAndWait { context -> Car in
        let car = try childContext.existingObject(with: car1.objectID) as! Car
        XCTAssertEqual(car.maker, "maker")
        return car
      }

      try parentContext.performSaveAndWait { context in
        let car = try context.existingObject(with: car1.objectID) as! Car
        XCTAssertEqual(car.maker, "maker")
        car.maker = "😀"
        XCTAssertEqual(car.maker, "😀")
      }

      // this will fail without automaticallyMergesChangesFromParent to true
      XCTAssertEqual(childCar.safeAccess({ $0.maker }), "😀")
    }

    // automaticallyMergesChangesFromParent = false
    do {
      let parentContext = container.viewContext

      let car1 = Car(context: parentContext)
      car1.maker = "FIAT"
      car1.model = "Panda"
      car1.numberPlate = UUID().uuidString
      car1.maker = "maker"
      try parentContext.save()

      let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
      childContext.parent = parentContext
      childContext.automaticallyMergesChangesFromParent = false

      let childCar = try childContext.performAndWait { context -> Car in
        let car = try childContext.existingObject(with: car1.objectID) as! Car
        XCTAssertEqual(car.maker, "maker")
        return car
      }

      try parentContext.performSaveAndWait { context in
        let car = try context.existingObject(with: car1.objectID) as! Car
        XCTAssertEqual(car.maker, "maker")
        car.maker = "😀"
        XCTAssertEqual(car.maker, "😀")
      }

      XCTAssertEqual(childCar.safeAccess({ $0.maker }), "maker") // no changes

    }
  }
}
