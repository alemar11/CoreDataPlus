import XCTest
import CoreData
@testable import CoreDataPlus

final class NSManagedObjectUpdateTimestampableTests: CoreDataPlusInMemoryTestCase {

  func testRefreshUpdateDate() throws {
    let context = container.viewContext
    context.fillWithSampleData()

    // Given
    let people = try! Person.fetch(in: context) { $0.predicate = NSPredicate(value: true) }
    var updates = [String: Date]()

    // When, Then
    for person in people {
      XCTAssertNotNil(person.updatedAt)
      updates["\(person.firstName) - \(person.lastName)"] = person.updatedAt
      person.refreshUpdateDate()
      XCTAssertTrue(updates["\(person.firstName) - \(person.lastName)"] == person.updatedAt)
    }

    // When, Then
    try context.save()

    for person in people {
      XCTAssertTrue(updates["\(person.firstName) - \(person.lastName)"] == person.updatedAt)
      person.refreshUpdateDate()
      XCTAssertTrue(updates["\(person.firstName) - \(person.lastName)"] != person.updatedAt)
    }

  }

}
