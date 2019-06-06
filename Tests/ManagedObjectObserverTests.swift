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

//class ManagedObjectObserverTests: CoreDataPlusTestCase {
//
//  // MARK: - didSave
//
//  func testInsertOnDidSaveEvent() throws {
//    let context = container.viewContext
//    let expectation = self.expectation(description: "\(#function)\(#line)")
//    let car = Car(context: context)
//    let id = car.objectID.copy() as! NSManagedObjectID
//    let observer = try ManagedObjectObserver(object: car, event: .didSave) { (changes, event) in
//      XCTAssertTrue(changes == .inserted)
//      XCTAssertFalse(id == car.objectID)
//      expectation.fulfill()
//    }
//    _ = observer
//
//    car.numberPlate = UUID().uuidString
//
//    try context.save()
//    waitForExpectations(timeout: 12)
//  }
//
//  func testUpdateOnDidSaveEvent() throws {
//    let context = container.viewContext
//    let expectation = self.expectation(description: "\(#function)\(#line)")
//    let car = Car(context: context)
//    car.numberPlate = UUID().uuidString
//    try context.save()
//    let id = car.objectID.copy() as! NSManagedObjectID
//
//    let observer = try ManagedObjectObserver(object: car, event: .didSave) { (changes, event) in
//      XCTAssertTrue(changes == .updated)
//      XCTAssertTrue(id == car.objectID)
//      expectation.fulfill()
//    }
//    _ = observer
//
//    car.maker = "123"
//
//    try context.save()
//    waitForExpectations(timeout: 2)
//  }
//
//  func testDeleteOnDidSaveEvent() throws {
//    let context = container.viewContext
//    let expectation = self.expectation(description: "\(#function)\(#line)")
//    let car = Car(context: context)
//    car.numberPlate = UUID().uuidString
//    try context.save()
//    let id = car.objectID.copy() as! NSManagedObjectID
//
//    let observer = try ManagedObjectObserver(object: car, event: .didSave) { (changes, event) in
//      XCTAssertTrue(changes == .deleted)
//      XCTAssertTrue(id == car.objectID)
//      expectation.fulfill()
//    }
//    _ = observer
//
//    car.delete()
//
//    try context.save()
//    waitForExpectations(timeout: 2)
//  }
//
//  func testDeleteNotSavedObjectOnDidSaveEvent() throws {
//    let context = container.viewContext
//    let expectation = self.expectation(description: "\(#function)\(#line)")
//    expectation.isInverted = true
//    let car = Car(context: context)
//
//     let car2 = Car(context: context)
//    car2.numberPlate = "123"
//
////   let k =  car.observe(\.isDeleted) { (car, changed) in
////      print("isDeleted")
////    }
//
//    let observer = try ManagedObjectObserver(object: car, event: .didSave) { (changes, event) in
//      expectation.fulfill()
//    }
//    _ = observer
//
//    //print(car.isDeleted)
//    car.delete()
////    print(car.isDeleted)
//   try context.save()
//    //car.numberPlate = "124rwege"
////    print(car.isDeleted)
//    //context.refreshAllObjects()
//
//    try context.save()
//    waitForExpectations(timeout: 2)
//  }
//
//  // MARK: - willSave
//
//  func testInsertOnWillSaveEvent() throws {
//    let context = container.viewContext
//    let car = Car(context: context)
//    // a willSave notificaiton doesn't contain any info about what is going to be saved so we can't identify the observed object
//    XCTAssertThrowsError(try ManagedObjectObserver(object: car, event: .willSave) { (changes, event) in })
//  }
//}
