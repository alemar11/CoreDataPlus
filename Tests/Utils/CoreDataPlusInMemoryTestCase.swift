import XCTest
import CoreData
@testable import CoreDataPlus

// MARK: - In Memory XCTestCase

class CoreDataPlusInMemoryTestCase: XCTestCase {
  var container: NSPersistentContainer!

  override func setUp() {
    super.setUp()
    container = InMemoryPersistentContainer.makeNew()
  }

  override func tearDown() {
    container = nil
    super.tearDown()
  }
}

// MARK: - In Memory NSPersistentContainer

final class InMemoryPersistentContainer: NSPersistentContainer {
  static func makeNew() -> InMemoryPersistentContainer {
    let url = URL(fileURLWithPath: "/dev/null")
    let container = InMemoryPersistentContainer(name: "SampleModel", managedObjectModel: model)
    container.persistentStoreDescriptions[0].url = url
    container.loadPersistentStores { (description, error) in
      XCTAssertNil(error)
    }
    return container
  }
}

