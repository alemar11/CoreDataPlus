//
// CoreDataPlus
//
// Copyright © 2016-2017 Tinrobots.
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

class NSFetchRequestResultUtilsTests: XCTestCase {
  
  func testBatchFaulting() {
    // Given
    let stack = CoreDataStack()!
    let context = stack.mainContext
    
    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }
    
    /// re-fault objects that don't have pending changes
    context.refreshAllObjects()
    
    let request = Car.newFetchRequest()
    request.predicate = NSPredicate(value: true)
    
    do {
      // When
      let cars = try context.fetch(request)
      
      /// re-fault objects that don't have pending changes
      context.refreshAllObjects()
      
      let previousFaultsCount = cars.filter { $0.isFault }.count
      
      /// batch faulting
      XCTAssertNoThrow(try cars.fetchFaultedObjects())
      
      // Then
      let currentNotFaultsCount = cars.filter { !$0.isFault }.count
      let currentFaultsCount = cars.filter { $0.isFault }.count
      XCTAssertTrue(previousFaultsCount == currentNotFaultsCount)
      XCTAssertTrue(currentFaultsCount == 0)
      
    } catch {
      XCTFail(error.localizedDescription)
    }
    
  }
  
  func testBatchFaultingEdgeCases() {
    // Given
    let _stack = CoreDataStack()
    guard let stack = _stack else {
      XCTAssertNotNil(_stack)
      return
    }
    let context = stack.mainContext
    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }
    
    // empty data set
    let objects: [NSManagedObject] = []
    XCTAssertNoThrow(try objects.fetchFaultedObjects())
    
    // no faults objects
    let request = Car.newFetchRequest()
    request.predicate = NSPredicate(value: true)
    request.returnsObjectsAsFaults = false
    request.fetchLimit = 2
    
    do {
      // When
      let cars = try context.fetch(request)
      let previousFaultsCount = cars.filter { $0.isFault }.count
      let previousNotFaultsCount = cars.filter { !$0.isFault }.count
      
      XCTAssertNoThrow(try cars.fetchFaultedObjects())
      
      // Then
      let currentFaultsCount = cars.filter { $0.isFault }.count
      let currentNotFaultsCount = cars.filter { !$0.isFault }.count
      XCTAssertTrue(previousFaultsCount == 0)
      XCTAssertTrue(currentFaultsCount == 0)
      XCTAssertTrue(previousNotFaultsCount == currentNotFaultsCount)
      
    } catch {
      XCTFail(error.localizedDescription)
    }
    
  }
  
  func testBatchFaultingWithDifferentContexts() {
    // Given
    let _stack = CoreDataStack()
    guard let stack = _stack else {
      XCTAssertNotNil(_stack)
      return
    }
    let context1 = stack.mainContext
    let context2 = context1.newBackgroundContext(asChildContext: false)
    
    let car1 = Car(context: context1)
    car1.numberPlate = "car1-testBatchFaultingWithDifferentContexts"
    let sportCar1 = SportCar(context: context1)
    sportCar1.numberPlate = "sportCar1-testBatchFaultingWithDifferentContexts"
    
    let person2 = Person(context: context2)
    person2.firstName = "firstName-testBatchFaultingWithDifferentContexts"
    person2.lastName = "lastName-testBatchFaultingWithDifferentContexts"
    let car2 = Car(context: context2)
    car2.numberPlate = "car2-testBatchFaultingWithDifferentContexts"
    
    context1.performAndWait {
      try! context1.save()
    }
    
    context2.performAndWait {
      try! context2.save()
    }
    
    // When
    context1.refreshAllObjects()
    context2.refreshAllObjects()
    
    let objects = [car1, sportCar1, person2, car2]
    
    // Then
    XCTAssertTrue(objects.filter { !$0.isFault }.isEmpty)
    XCTAssertNoThrow(try objects.fetchFaultedObjects())
    XCTAssertTrue(objects.filter { !$0.isFault }.count == 4)
  }
  
  func testBatchFaultingToManyRelationship() {
    let stack = CoreDataStack()!
    let context = stack.mainContext
    
    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }
    
    context.refreshAllObjects() //re-fault objects that don't have pending changes
    
    let request = Person.newFetchRequest()
    request.predicate = NSPredicate(format: "\(#keyPath(Person.firstName)) == %@ AND \(#keyPath(Person.lastName)) == %@", "Theodora", "Stone")
    
    do {
      let persons = try context.fetch(request)
      
      XCTAssertNotNil(persons)
      XCTAssertTrue(!persons.isEmpty)
      
      let person = persons.first!
      let previousFaultsCount = person.cars?.filter { $0.isFault }.count
      
      XCTAssertNoThrow(try person.cars?.fetchFaultedObjects())
      let currentNotFaultsCount = person.cars?.filter { !$0.isFault }.count
      let currentFaultsCount = person.cars?.filter { $0.isFault }.count
      XCTAssertTrue(previousFaultsCount == currentNotFaultsCount)
      XCTAssertTrue(currentFaultsCount == 0)
      
    } catch {
      XCTFail(error.localizedDescription)
    }
    
  }
  
}
