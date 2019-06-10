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

final class SingleFetchedResultControllerTests: CoreDataPlusTestCase {
  func testInsert() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    let expectation = self.expectation(description: "\(#function)\(#line)")
    
    try context.save()
    let request = Car.newFetchRequest()
    let predicate = NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "not_existing")
    request.predicate = predicate
    let controller = SingleFetchedResultController<Car>(request: request, managedObjectContext: context) { change in
      switch change {
      case .insert: expectation.fulfill()
      default: XCTFail("Unexpected change.")
      }
    }
    // When, Then
    try controller.performFetch()
    XCTAssertNil(controller.fetchedObject)
    let car = Car(context: context)
    car.numberPlate = "not_existing"
    try context.save()
    waitForExpectations(timeout: 5)
  }
  
  func testUpdate() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    let expectation = self.expectation(description: "\(#function)\(#line)")
    
    try context.save()
    let request = Car.newFetchRequest()
    let predicate = NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")
    request.predicate = predicate
    let controller = SingleFetchedResultController<Car>(request: request, managedObjectContext: context) { change in
      switch change {
      case .update: expectation.fulfill()
      default: XCTFail("Unexpected change.")
      }
    }
    // When, Then
    try controller.performFetch()
    XCTAssertNotNil(controller.fetchedObject)
    let car = controller.fetchedObject!
    car.maker = "maker"
    try context.save()
    waitForExpectations(timeout: 5)
  }
  
  func testUpdateWhenTheOldObjectDoesNotFullfilThePredicateAnymoreButANewObjectDoes() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    let expectation1 = self.expectation(description: "\(#function)\(#line)")
    let expectation2 = self.expectation(description: "\(#function)\(#line)")
    
    try context.save()
    let request = Car.newFetchRequest()
    let predicate = NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")
    request.predicate = predicate
    let controller = SingleFetchedResultController<Car>(request: request, managedObjectContext: context) { change in
      switch change {
      case .delete: expectation1.fulfill()
      case .insert: expectation2.fulfill()
      default: XCTFail("Unexpected change.")
      }
    }
    // When, Then
    try controller.performFetch()
    XCTAssertNotNil(controller.fetchedObject)
    let car = controller.fetchedObject!
    car.numberPlate = "304 new"
    let car2 = Car(context: context)
    car2.numberPlate = "304"
    try context.save()
   wait(for: [expectation1, expectation2], timeout: 5, enforceOrder: true)
  }
  
  func testDeleteWhenTheObjectDoesNotFullfilThePredicateAnymore() throws {
    // The update changes a value used in the predicate
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    let expectation = self.expectation(description: "\(#function)\(#line)")
    
    try context.save()
    let request = Car.newFetchRequest()
    let predicate = NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")
    request.predicate = predicate
    let controller = SingleFetchedResultController<Car>(request: request, managedObjectContext: context) { change in
      switch change {
      case .delete: expectation.fulfill()
      default: XCTFail("Unexpected change.")
      }
    }
    // When, Then
    try controller.performFetch()
    XCTAssertNotNil(controller.fetchedObject)
    let car = controller.fetchedObject!
    car.numberPlate = "304 new"
    try context.save()
    waitForExpectations(timeout: 5)
    XCTAssertNil(controller.fetchedObject)
  }
  
  func testDelete() throws {
    // The update changes a value used in the predicate
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    let expectation = self.expectation(description: "\(#function)\(#line)")
    
    try context.save()
    let request = Car.newFetchRequest()
    let predicate = NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")
    request.predicate = predicate
    let controller = SingleFetchedResultController<Car>(request: request, managedObjectContext: context) { change in
      switch change {
      case .delete: expectation.fulfill()
      default: XCTFail("Unexpected change.")
      }
    }
    // When, Then
    try controller.performFetch()
    XCTAssertNotNil(controller.fetchedObject)
    let car = controller.fetchedObject!
    car.delete()
    try context.save()
    waitForExpectations(timeout: 5)
    XCTAssertNil(controller.fetchedObject)
  }

  func testDuplicates() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()

    try context.save()
    let request = Car.newFetchRequest()
    let predicate = NSPredicate(format: "\(#keyPath(Car.maker)) == %@", "FIAT")
    request.predicate = predicate
    let controller = SingleFetchedResultController<Car>(request: request, managedObjectContext: context) { _ in }
    XCTAssertThrowsError(try controller.performFetch())
  }
}
