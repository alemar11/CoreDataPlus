// CoreDataPlus

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
  static func makeNew(named: String = "test") -> InMemoryPersistentContainer {
    // WWDC https://developer.apple.com/videos/play/wwdc2019/230
    // A simple in memory store can't be shared between coordinators (remote change notifications won't work)
    // using .appendingPathComponent(_:) we can create a named in memory store
    // all the SQLite stores with that URL in the same process will connect to the shared in memory database
    // Different coordinators sharing the same in memory store will also dispatch remote change notifications to
    // each other
    let url = URL(fileURLWithPath: "/dev/null") //.appendingPathComponent(named) // TODO
    let container = InMemoryPersistentContainer(name: "SampleModel", managedObjectModel: model)
    let description = container.persistentStoreDescriptions.first!
    description.url = url
    container.loadPersistentStores { (description, error) in
      XCTAssertNil(error)
    }
    return container
  }
}

