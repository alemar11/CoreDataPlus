// CoreDataPlus

import CoreData
import XCTest

@testable import CoreDataPlus

// MARK: - On Disk XCTestCase

class OnDiskTestCase: BaseTestCase {
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
      XCTFail("The persistent container couldn't be destroyed.")
    }
    container = nil
    super.tearDown()
  }
}

// MARK: - On Disk NSPersistentContainer

final class OnDiskPersistentContainer: NSPersistentContainer, @unchecked Sendable {

  static func makeNew() -> OnDiskPersistentContainer {
    Self.makeNew(id: UUID())
  }

  static func makeNew(id: UUID) -> OnDiskPersistentContainer {
    let url = URL.newDatabaseURL(withID: id)
    let container = OnDiskPersistentContainer(name: "SampleModel", managedObjectModel: model1)
    let description = container.persistentStoreDescriptions.first!
    description.url = url
    // disable automatic migration (true by default)
    // tests works fine even if they are left to true
    description.shouldMigrateStoreAutomatically = false
    description.shouldInferMappingModelAutomatically = false

    // Enable history tracking and remote notifications
    container.persistentStoreDescriptions[0].setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    container.persistentStoreDescriptions[0].setOption(
      true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

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
