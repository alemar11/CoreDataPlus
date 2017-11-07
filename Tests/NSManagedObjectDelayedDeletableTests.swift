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

class NSManagedObjectDelayedDeletableTests: XCTestCase {

  func testMarkAsDelayedDeletable() {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    context.fillWithSampleData()

    // Given
    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let cars = try! Car.fetch(in: context) { $0.predicate = fiatPredicate }

    // When, Then
    for car in cars {
      XCTAssertNil(car.markedForDeletionAsOf)
      XCTAssertFalse(car.hasChangedForDelayedDeletion)
      car.markForDelayedDeletion()
    }

    for car in cars {
      XCTAssertNotNil(car.markedForDeletionAsOf)
      XCTAssertTrue(car.hasChangedForDelayedDeletion)
    }

    // When, Then
    try! context.save()
    let fiatNotDeletablePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [fiatPredicate, Car.notMarkedForLocalDeletionPredicate])
    let notDeletableCars = try! Car.fetch(in: context) { $0.predicate = fiatNotDeletablePredicate }
    XCTAssertTrue(notDeletableCars.isEmpty)

  }

}
