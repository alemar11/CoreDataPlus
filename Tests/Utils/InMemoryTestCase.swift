// CoreDataPlus

import CoreData
import XCTest

@testable import CoreDataPlus

// MARK: - In Memory XCTestCase

class InMemoryTestCase: BaseTestCase {
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

final class InMemoryPersistentContainer: NSPersistentContainer, @unchecked Sendable {
  static func makeNew(named: String? = nil) -> InMemoryPersistentContainer {
    // WWDC https://developer.apple.com/videos/play/wwdc2019/230
    // A simple in memory store can't be shared between coordinators (remote change notifications won't work)
    // using .appendingPathComponent(_:) we can create a named in memory store
    // all the SQLite stores with that URL in the same process will connect to the shared in memory database
    // Different coordinators sharing the same in memory store will also dispatch remote change notifications to
    // each other

    // "/dev/null" it's the same URL we get by default when we create a description like so: let description = NSPersistentStoreDescription()
    var url = URL(fileURLWithPath: "/dev/null")
    if let named = named {
      url.appendPathComponent(named)
    }
    let container = InMemoryPersistentContainer(name: "SampleModel", managedObjectModel: model1)
    let description = container.persistentStoreDescriptions.first!
    description.url = url
    //description.type = NSInMemoryStoreType // Setting this value will fail some tests at the moment

    // Enable history tracking and remote notifications
    container.persistentStoreDescriptions[0].setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    container.persistentStoreDescriptions[0].setOption(
      true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

    container.loadPersistentStores { (description, error) in
      XCTAssertNil(error)
    }
    return container
  }
}
