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

class ThreadSafeAccessibleTests: CoreDataPlusTestCase {

  func testManagedObjectThreadSafeAccess() {
    let context = container.viewContext.newBackgroundContext()
    let car = context.performAndWait { return Car(context: $0) }
    car.safeAccess { XCTAssertEqual($0.managedObjectContext, context) }
  }

  func testFetchedResultsControllerThreadSafeAccess() throws {
    let context = container.viewContext.newBackgroundContext()
    try context.performAndWait { _ in
      context.fillWithSampleData()
      try context.save()
    }

    let request = Car.newFetchRequest()
    request.sortDescriptors = [NSSortDescriptor(key: #keyPath(Car.numberPlate), ascending: true)]
    let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    try controller.performFetch()

    let cars = controller.fetchedObjects!
    let firstCar = controller.object(at: IndexPath(item: 0, section: 0)) as Car

    firstCar.safeAccess {
      XCTAssertEqual(controller.managedObjectContext, $0.managedObjectContext)
    }

    for car in cars {
      _ = car.safeAccess { car -> String in
        XCTAssertEqual(controller.managedObjectContext, context)
        return car.numberPlate
      }
    }
  }

}
