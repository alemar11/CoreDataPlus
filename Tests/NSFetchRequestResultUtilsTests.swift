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
      cars.fetchFaultedObjects()
      
      // Then
      let currentNotFaultsCount = cars.filter { !$0.isFault }.count
      let currentFaultsCount = cars.filter { $0.isFault }.count
      XCTAssertTrue(previousFaultsCount == currentNotFaultsCount)
      XCTAssertTrue(currentFaultsCount == 0)
      
    } catch {
      XCTFail(error.localizedDescription)
    }
    
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
    request.predicate = NSPredicate(format: "firstName == %@ AND lastName == %@", "Theodora", "Stone")
    
    do {
      let persons = try context.fetch(request)
      
      XCTAssertNotNil(persons)
      XCTAssertTrue(!persons.isEmpty)
      
      let person = persons.first!
      let previousFaultsCount = person.cars?.filter { $0.isFault }.count
      
      person.cars?.fetchFaultedObjects()
      let currentNotFaultsCount = person.cars?.filter { !$0.isFault }.count
      let currentFaultsCount = person.cars?.filter { $0.isFault }.count
      XCTAssertTrue(previousFaultsCount == currentNotFaultsCount)
      XCTAssertTrue(currentFaultsCount == 0)
      
    } catch {
      XCTFail(error.localizedDescription)
    }
    
  }
  
}
