// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

final class NSFetchRequestUtilsTests: XCTestCase {
  func testInit() {
    let fakeEntity = NSEntityDescription()
    do {
      // Given, When
      let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entity: fakeEntity)
      // Then
      XCTAssertEqual(fetchRequest.entity, fakeEntity)
      XCTAssertEqual(fetchRequest.fetchBatchSize, 0)
      XCTAssertNil(fetchRequest.predicate)
    }

    do {
      // Given, When
      let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entity: fakeEntity, predicate: nil, batchSize: 10)
      // Then
      XCTAssertEqual(fetchRequest.entity, fakeEntity)
      XCTAssertEqual(fetchRequest.fetchBatchSize, 10)
      XCTAssertNil(fetchRequest.predicate)
    }

    do {
      // Given, When
      let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entity: fakeEntity, predicate: nil, batchSize: 20)
      // Then
      XCTAssertEqual(fetchRequest.entity, fakeEntity)
      XCTAssertEqual(fetchRequest.fetchBatchSize, 20)
      XCTAssertNil(fetchRequest.predicate)
    }

    do {
      // Given, When
      let predicate = NSPredicate(value: true)
      let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entity: fakeEntity, predicate: predicate, batchSize: 1)
      // Then
      XCTAssertEqual(fetchRequest.entity, fakeEntity)
      XCTAssertEqual(fetchRequest.fetchBatchSize, 1)
      XCTAssertEqual(fetchRequest.predicate, predicate)
    }
  }

  func testPredicateAndDescriptorComposition() {
    do {
      let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Not important")
      fetchRequest.andPredicate(NSPredicate(format: "Y = 30"))
      XCTAssertTrue(fetchRequest.predicate == NSPredicate(format: "Y = 30"))

      fetchRequest.addSortDescriptors([NSSortDescriptor(key: "id", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))])

      if fetchRequest.sortDescriptors?.count == 1 {
        XCTAssertTrue(fetchRequest.sortDescriptors!.last! == NSSortDescriptor(key: "id", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))))
      } else {
        XCTAssertTrue(fetchRequest.sortDescriptors?.count == 1)
      }
    }

    do {
      let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Not important")
      fetchRequest.predicate = NSPredicate(format: "X = 10")
      fetchRequest.sortDescriptors = [NSSortDescriptor(key: "KEY", ascending: false)]
      fetchRequest.andPredicate(NSPredicate(format: "Y = 30"))

      XCTAssertTrue(fetchRequest.predicate == NSPredicate(format: "X = 10 AND Y = 30"))
      fetchRequest.addSortDescriptors([NSSortDescriptor(key: "id", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))])

      if fetchRequest.sortDescriptors?.count == 2 {
        XCTAssertTrue(fetchRequest.sortDescriptors!.first! == NSSortDescriptor(key: "KEY", ascending: false))
        XCTAssertTrue(fetchRequest.sortDescriptors!.last! == NSSortDescriptor(key: "id", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))))
      } else {
        XCTAssertTrue(fetchRequest.sortDescriptors?.count == 2)
      }
    }

    do {
      let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Not important")
      fetchRequest.predicate = NSPredicate(format: "X = 10")
      fetchRequest.orPredicate(NSPredicate(format: "Y = 30"))

      XCTAssertTrue(fetchRequest.predicate == NSPredicate(format: "X = 10 OR Y = 30"))
      XCTAssertNil(fetchRequest.sortDescriptors)
    }

    do {
      let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Not important")
      fetchRequest.orPredicate(NSPredicate(format: "Y = 30"))

      XCTAssertTrue(fetchRequest.predicate == NSPredicate(format: "Y = 30"))
    }
  }
}
