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

class NSManagedObjectContextObserversTests: XCTestCase {

  /// This is a very generic test case
  func testObservers() throws {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")

    let notificationCenter = NotificationCenter.default

    let token1 = context.addContextWillSaveNotificationObserver(notificationCenter: notificationCenter) { notification in
      expectation1.fulfill()
    }

    let token2 = context.addContextDidSaveNotificationObserver(notificationCenter: notificationCenter) { Notification in
      expectation2.fulfill()
    }

    let token3 = context.addObjectsDidChangeNotificationObserver(notificationCenter: notificationCenter) { Notification in
      expectation3.fulfill()
    }

    context.fillWithSampleData()
    try context.save()

    wait(for: [expectation1, expectation2, expectation3], timeout: 2)
    XCTAssertFalse(context.hasChanges)

    notificationCenter.removeObserver(token1)
    notificationCenter.removeObserver(token2)
    notificationCenter.removeObserver(token3)
  }

  func testObserversWithoutSaving() throws {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")

    expectation1.isInverted = true
    expectation2.isInverted = true

    let notificationCenter = NotificationCenter.default

    let token1 = context.addContextWillSaveNotificationObserver(notificationCenter: notificationCenter) { notification in
      expectation1.fulfill()
    }

    let token2 = context.addContextDidSaveNotificationObserver(notificationCenter: notificationCenter) { Notification in
      expectation2.fulfill()
    }

    let token3 = context.addObjectsDidChangeNotificationObserver(notificationCenter: notificationCenter) { Notification in
      expectation3.fulfill()
    }

    context.fillWithSampleData()

    wait(for: [expectation1, expectation2, expectation3], timeout: 2)
    XCTAssertTrue(context.hasChanges)

    notificationCenter.removeObserver(token1)
    notificationCenter.removeObserver(token2)
    notificationCenter.removeObserver(token3)
  }

  func testObserversWhenWorkingOnAnotherContext() throws {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let anotherContext = stack.mainContext.newBackgroundContext(asChildContext: false) // TODO add test with true

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")

    expectation1.isInverted = true
    expectation2.isInverted = true
    expectation3.isInverted = true

    let notificationCenter = NotificationCenter.default

    let token1 = context.addContextWillSaveNotificationObserver(notificationCenter: notificationCenter) { notification in
      expectation1.fulfill()
    }

    let token2 = context.addContextDidSaveNotificationObserver(notificationCenter: notificationCenter) { Notification in
      expectation2.fulfill()
    }

    let token3 = context.addObjectsDidChangeNotificationObserver(notificationCenter: notificationCenter) { Notification in
      expectation3.fulfill()
    }

    anotherContext.fillWithSampleData()
    try anotherContext.save()
    
    wait(for: [expectation1, expectation2, expectation3], timeout: 2)
    XCTAssertFalse(context.hasChanges)
    XCTAssertFalse(anotherContext.hasChanges)

    notificationCenter.removeObserver(token1)
    notificationCenter.removeObserver(token2)
    notificationCenter.removeObserver(token3)
  }

  func testObserverCountingChangedObjects() throws {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext

//    let expectation1 = expectation(description: "\(#function)\(#line)")
//    let expectation2 = expectation(description: "\(#function)\(#line)")
//    let expectation3 = expectation(description: "\(#function)\(#line)")

    let notificationCenter = NotificationCenter.default

    // Add and save some data in the context

    /// Elements to be deleted: 1 Person + 1 Car
    let person1_deleted = Person(context: context)
    person1_deleted.firstName = "Alessandro"
    person1_deleted.lastName = "Marzoli "

    let car1_deleted = Car(context: context)
    car1_deleted.maker = "Alfa Romeo"
    car1_deleted.model = "Giulietta"
    car1_deleted.numberPlate = "00011"

    person1_deleted.cars = Set([car1_deleted])

     /// Elements to be updated: 3 Person + 1 Car
    let person1_updated = Person(context: context)
    person1_updated.firstName = "Andrea"
    person1_updated.lastName = "Marzoli"

    let person2_updated = Person(context: context)
    person2_updated.firstName = "Valdemaro"
    person2_updated.lastName = "Marzoli"

    let person3_updated = Person(context: context)
    person3_updated.firstName = "Primetto"
    person3_updated.lastName = "Marzoli"

    let car1_updated = Car(context: context)
    car1_updated.maker = "Alfa Romeo"
    car1_updated.model = "Giulia"
    car1_updated.numberPlate = "000"

    person1_updated.cars = Set([car1_updated])

    try context.save()

    var deletedObjects = 0
    var insertedObjects = 0

    let token1 = context.addContextWillSaveNotificationObserver(notificationCenter: notificationCenter) { notification in
      XCTAssertEqual(notification.managedObjectContext, context)
      //expectation1.fulfill()
    }

    let token2 = context.addContextDidSaveNotificationObserver(notificationCenter: notificationCenter) { notification in
      XCTAssertEqual(notification.managedObjectContext, context)
      //expectation2.fulfill()
    }

    let token3 = context.addObjectsDidChangeNotificationObserver(notificationCenter: notificationCenter) { notification in
      XCTAssertEqual(notification.managedObjectContext, context)

      deletedObjects += notification.deletedObjects.count
      for o in notification.deletedObjects {
        print(o.isDeleted)
      }
      debugPrint(notification)
      insertedObjects += notification.insertedObjects.count

      //XCTAssertEqual(notification.invalidatedObjects.count, 0) //--> 1
      //XCTAssertEqual(notification.updatedObjects.count, 0) //--> 4
      //XCTAssertEqual(notification.refreshedObjects.count, 0) //--> 3
      //XCTAssertFalse(notification.invalidatedAllObjects)
      //XCTAssertEqual(notification.insertedObjects.count, 9) // 3 persons + 6 cars
      //expectation3.fulfill()
    }

    let person1_inserted = Person(context: context)
    person1_inserted.firstName = "Edythe"
    person1_inserted.lastName = "Moreton"

    let person2_inserted = Person(context: context)
    person2_inserted.firstName = "Ellis"
    person2_inserted.lastName = "Khoury"

    let person3_inserted = Person(context: context)
    person3_inserted.firstName = "Faron"
    person3_inserted.lastName = "Moreton"

    let car1_inserted = Car(context: context)
    car1_inserted.maker = "Alfa Romeo"
    car1_inserted.model = "Giulietta"
    car1_inserted.numberPlate = "4"

    let car2_inserted = ExpensiveSportCar(context: context)
    car2_inserted.maker = "McLaren"
    car2_inserted.model = "570GT"
    car2_inserted.numberPlate = "303"
    car2_inserted.isLimitedEdition = false

    let car3_inserted = ExpensiveSportCar(context: context)
    car3_inserted.maker = "Lamborghini"
    car3_inserted.model = "Aventador LP750-4"
    car3_inserted.numberPlate = "304"
    car3_inserted.isLimitedEdition = false

    let car4_inserted = Car(context: context)
    car4_inserted.maker = "Renault"
    car4_inserted.model = "Clio"
    car4_inserted.numberPlate = "14"

    let car5_inserted = Car(context: context)
    car5_inserted.maker = "Renault"
    car5_inserted.model = "Megane"
    car5_inserted.numberPlate = "15"

    let car6_inserted = SportCar(context: context)
    car6_inserted.maker = "BMW"
    car6_inserted.model = "M6 Coupe"
    car6_inserted.numberPlate = "200"

    person1_inserted.cars = Set([car1_inserted])
    person2_inserted.cars = Set([car2_inserted, car3_inserted])
    person3_inserted.cars = Set([car4_inserted, car5_inserted, car6_inserted])


    context.delete(person1_deleted)
    context.delete(car1_deleted)

    try context.save()

    XCTAssertEqual(deletedObjects, 2)
    XCTAssertEqual(insertedObjects, 9)

    //wait(for: [expectation1, expectation2, expectation3], timeout: 2)
    notificationCenter.removeObserver(token1)
    notificationCenter.removeObserver(token2)
    notificationCenter.removeObserver(token3)
  }

}
