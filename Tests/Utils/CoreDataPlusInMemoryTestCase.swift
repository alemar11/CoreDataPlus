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
  static func makeNew(named: String? = nil) -> InMemoryPersistentContainer {
    // WWDC https://developer.apple.com/videos/play/wwdc2019/230
    // A simple in memory store can't be shared between coordinators (remote change notifications won't work)
    // using .appendingPathComponent(_:) we can create a named in memory store
    // all the SQLite stores with that URL in the same process will connect to the shared in memory database
    // Different coordinators sharing the same in memory store will also dispatch remote change notifications to
    // each other
    var url = URL(fileURLWithPath: "/dev/null") // it's the same URL we get by default when we create a description like so: let description = NSPersistentStoreDescription()
    if let named = named {
      url.appendPathComponent(named)
    }
    let container = InMemoryPersistentContainer(name: "SampleModel", managedObjectModel: model)
    let description = container.persistentStoreDescriptions.first!
    description.url = url
    description.type = NSInMemoryStoreType

    // Enable history tracking and remote notifications
    container.persistentStoreDescriptions[0].setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    if #available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
      container.persistentStoreDescriptions[0].setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    }

    container.loadPersistentStores { (description, error) in
      XCTAssertNil(error)
    }
    return container
  }
}

