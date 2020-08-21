// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

// MARK: - On Disk XCTestCase

class CoreDataPlusOnDiskTestCase: XCTestCase {
  var container: NSPersistentContainer!

  override func setUp() {
    super.setUp()
    container = OnDiskPersistentContainer.makeNew()
  }

  override func tearDown() {
    do {
      if let onDiskContainer = container as? OnDiskPersistentContainer {
        try onDiskContainer.destroy()
      }
    } catch {
      XCTFail("The persistent container couldn't be deostryed.")
    }
    container = nil
    super.tearDown()
  }
}

// MARK: - On Disk NSPersistentContainer

final class OnDiskPersistentContainer: NSPersistentContainer {
  static func makeNew() -> OnDiskPersistentContainer {
    let url = URL.newDatabaseURL(withID: UUID())
    let container = OnDiskPersistentContainer(name: "SampleModel", managedObjectModel: model)
    container.persistentStoreDescriptions[0].url = url

    // Enable history tracking and remote notifications
    container.persistentStoreDescriptions[0].setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    if #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
      container.persistentStoreDescriptions[0].setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    }

    container.loadPersistentStores { (description, error) in
      XCTAssertNil(error)
    }
    return container
  }

  static func makeNew(id: UUID) -> OnDiskPersistentContainer {
    let url = URL.newDatabaseURL(withID: id)
    let container = OnDiskPersistentContainer(name: "SampleModel", managedObjectModel: model)
    let description = container.persistentStoreDescriptions.first!
    description.url = url

    // Enable history tracking and remote notifications
    container.persistentStoreDescriptions[0].setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    if #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
      container.persistentStoreDescriptions[0].setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    }

    container.loadPersistentStores { (description, error) in
      XCTAssertNil(error)
    }
    return container
  }

  /// Destroys the database and reset all the registered contexts.
  func destroy() throws {
    guard let url = persistentStoreDescriptions[0].url else { return }
    guard !url.absoluteString.starts(with: "/dev/null") else { return }

    // unload each store from the used context to avoid the sqlite3 bug warning.
    do {
      if let store = persistentStoreCoordinator.persistentStores.first {
        try persistentStoreCoordinator.remove(store)
      }
      try NSPersistentStoreCoordinator.destroyStore(at: url)
    } catch {
      fatalError("\(error) while destroying the store.")
    }
  }
}
