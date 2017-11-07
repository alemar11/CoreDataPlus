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

class NSFetchRequestResultCoreDataTests: XCTestCase {

  func testDeleteAllIncludingSubentities() {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext

    // Given
    context.fillWithSampleData()
    // When
    XCTAssertNoThrow(try SportCar.deleteAll(in: context, where: NSPredicate(format: "%K == %@", #keyPath(SportCar.numberPlate), "302")))
    // Then
    XCTAssertTrue(try SportCar.fetch(in: context).filter { $0.numberPlate == "302" }.isEmpty)
    XCTAssertTrue(try ExpensiveSportCar.fetch(in: context).filter { $0.numberPlate == "302" }.isEmpty)

    // When
    XCTAssertNoThrow(try ExpensiveSportCar.deleteAll(in: context, where: NSPredicate(format: "%K == %@", #keyPath(SportCar.numberPlate), "301")))
    // Then
    XCTAssertTrue(try SportCar.fetch(in: context).filter { $0.numberPlate == "301" }.isEmpty)
    XCTAssertTrue(try ExpensiveSportCar.fetch(in: context).filter { $0.numberPlate == "301" }.isEmpty)

    // When
    XCTAssertNoThrow(try SportCar.deleteAll(in: context, where: NSPredicate(value: true)))
    // Then
    XCTAssertTrue(try SportCar.fetch(in: context).isEmpty)
    XCTAssertTrue(try ExpensiveSportCar.fetch(in: context).isEmpty)
    XCTAssertTrue(try !Car.fetch(in: context).isEmpty)

    // When
    XCTAssertNoThrow(try Car.deleteAll(in: context))
    // Then
    XCTAssertTrue(try Car.fetch(in: context).isEmpty)

  }

  func testDeleteAllExcludingSubentities() {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext

    // Given
    context.fillWithSampleData()
    // When
    XCTAssertNoThrow(try SportCar.deleteAll(in: context, includingSubentities:false, where: NSPredicate(format: "%K == %@", #keyPath(SportCar.numberPlate), "302"))) //it's an ExpensiveSportCar
    // Then
    XCTAssertFalse(try SportCar.fetch(in: context).filter { $0.numberPlate == "302" }.isEmpty)
    XCTAssertFalse(try ExpensiveSportCar.fetch(in: context).filter { $0.numberPlate == "302" }.isEmpty)

    // When
    XCTAssertNoThrow(try ExpensiveSportCar.deleteAll(in: context, includingSubentities:false, where: NSPredicate(format: "%K == %@", #keyPath(SportCar.numberPlate), "301")))
    // Then
    XCTAssertTrue(try SportCar.fetch(in: context).filter { $0.numberPlate == "301" }.isEmpty)
    XCTAssertTrue(try ExpensiveSportCar.fetch(in: context).filter { $0.numberPlate == "301" }.isEmpty)

    // When
    XCTAssertNoThrow(try SportCar.deleteAll(in: context, includingSubentities:false, where: NSPredicate(value: true)))
    // Then
    XCTAssertFalse(try SportCar.fetch(in: context).isEmpty)
    XCTAssertFalse(try ExpensiveSportCar.fetch(in: context).isEmpty)

    // When
    XCTAssertNoThrow(try Car.deleteAll(in: context))
    // Then
    XCTAssertTrue(try Car.fetch(in: context).isEmpty)

  }

  func testDeleteAllExcludingExceptions() {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    context.fillWithSampleData()

    // Given
    do {
      let optonalCar = try Car.fetch(in: context).filter { $0.numberPlate == "5" }.first
      let optionalPerson = try Person.fetch(in: context).filter { $0.firstName == "Theodora" && $0.lastName == "Stone" }.first
      let persons = try Person.fetch(in: context).filter { $0.lastName == "Moreton" }

      // When
      guard let car = optonalCar, let person = optionalPerson, !persons.isEmpty else {
        XCTAssertNotNil(optonalCar)
        XCTAssertNotNil(optionalPerson)
        XCTAssertFalse(persons.isEmpty)
        return
      }

      // Then

      /// Car exception
      XCTAssertNoThrow(try Car.deleteAll(in: context, except: [car]))
      let cars = try Car.fetch(in: context)
      XCTAssertNotNil(cars.filter { $0.numberPlate == "5" }.first)
      XCTAssertTrue(cars.filter { $0.numberPlate != "5" }.isEmpty)

      /// exceptions
      var exceptions = persons
      exceptions.append(person)
      XCTAssertNoThrow(try Person.deleteAll(in: context, except: exceptions))
      XCTAssertFalse(try Person.fetch(in: context).filter { ($0.firstName == "Theodora" && $0.lastName == "Stone") || ($0.lastName == "Moreton") }.isEmpty)

      /// no exceptions
      XCTAssertNoThrow(try Person.deleteAll(in: context, except: []))
      XCTAssertTrue(try Person.fetch(in: context).isEmpty)

    } catch {
      XCTFail(error.localizedDescription)
    }
  }

  func testDeleteAllWithSubentitiesExcludingExceptions() {
    // Given
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    context.fillWithSampleData()
    // When, Then
    do {
      let sportCar = try! SportCar.fetch(in: context, with: { $0.predicate = NSPredicate(format: "%K BETWEEN %@", #keyPath(Car.numberPlate), ["202","204"]) })
      XCTAssertNotNil(sportCar)
      XCTAssertNoThrow(try Car.deleteAll(in: context, except: sportCar))
      let carsAfterDelete = try Car.fetch(in: context)
      XCTAssertTrue(carsAfterDelete.count == 3)
    } catch {
      XCTFail(error.localizedDescription)
    }
  }

}
