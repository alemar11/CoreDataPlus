// 
// CoreDataPlus
//
// Copyright © 2016-2020 Tinrobots.
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
@testable import CoreDataPlus

final class NSSetCoreDataTests: CoreDataPlusInMemoryTestCase {

  func testMaterializeFaultedManagedObjects() throws {
    let context = container.viewContext
    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }
    
    let request = Person.newFetchRequest()
    request.returnsObjectsAsFaults = true
    let foundPerson = try Person.findOneOrFetch(in: context, where: NSPredicate(format: "\(#keyPath(Person.firstName)) == %@ AND \(#keyPath(Person.lastName)) == %@", "Theodora", "Stone"))
    let person = try XCTUnwrap(foundPerson)
    context.refreshAllObjects()
    
    let initialFaultsCount = person.cars?.filter { object in
      if let managedCar = object as? Car {
        return managedCar.isFault
      }
      XCTFail("A Car object was expected")
      return false
    }.count
    
    XCTAssertEqual(initialFaultsCount, person.cars?.count ?? 0)
    try person.cars?.materializeFaultedManagedObjects()
    
    let finalFaultsCount = person.cars?.filter { object in
      if let managedCar = object as? Car {
        return managedCar.isFault
      }
      XCTFail("A Car object was expected")
      return false
    }.count
    
    XCTAssertEqual(finalFaultsCount, 0)
  }
  
  func testDeleteManagedObjects() throws {
    let context = container.viewContext
    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }
    
    let request = Person.newFetchRequest()
    request.returnsObjectsAsFaults = true
    let foundPerson = try Person.findOneOrFetch(in: context, where: NSPredicate(format: "\(#keyPath(Person.firstName)) == %@ AND \(#keyPath(Person.lastName)) == %@", "Theodora", "Stone"))
    let person = try XCTUnwrap(foundPerson)
    context.refreshAllObjects()
    XCTAssertEqual(person.cars?.count ?? 0, 100)
    person.cars?.deleteManagedObjects()
    try context.save()
    XCTAssertEqual(person.cars?.count ?? 0, 0)
  }
}
