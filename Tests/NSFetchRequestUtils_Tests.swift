// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

final class NSFetchRequestUtilsTests: XCTestCase {
  func test_Init() {
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
}
