// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

final class NSManagedObjectDelayedDeletableTests: InMemoryTestCase {
  func testMarkAsDelayedDeletable() throws {
    let context = container.viewContext
    context.fillWithSampleData()

    // Given
    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let cars = try! Car.fetchObjects(in: context) { $0.predicate = fiatPredicate }

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
    try context.save()
    let fiatNotDeletablePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [fiatPredicate, Car.notMarkedForLocalDeletionPredicate])
    let notDeletableCars = try! Car.fetchObjects(in: context) { $0.predicate = fiatNotDeletablePredicate }
    XCTAssertTrue(notDeletableCars.isEmpty)

    let fiatDeletablePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [fiatPredicate, Car.markedForLocalDeletionPredicate])
    let deletableCars = try! Car.fetchObjects(in: context) { $0.predicate = fiatDeletablePredicate }
    XCTAssertTrue(deletableCars.count > 0)
  }
}
