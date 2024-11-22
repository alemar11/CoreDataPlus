// CoreDataPlus

import CoreData
import XCTest

@testable import CoreDataPlus

class OnDiskWithProgrammaticallyModelTestCase: XCTestCase {
  var container: NSPersistentContainer!

  override func setUp() {
    super.setUp()
    container = OnDiskWithProgrammaticallyModelPersistentContainer.makeNew()
  }

  override func tearDown() {
    do {
      if let onDiskContainer = container as? OnDiskWithProgrammaticallyModelPersistentContainer {
        try onDiskContainer.destroy()
      }
    } catch {
      XCTFail("The persistent container couldn't be destroyed.")
    }
    container = nil
    super.tearDown()
  }
}

// MARK: - On Disk NSPersistentContainer with Programmatically Model

final class OnDiskWithProgrammaticallyModelPersistentContainer: NSPersistentContainer, @unchecked Sendable {
  static func makeNew() -> OnDiskWithProgrammaticallyModelPersistentContainer {
    Self.makeNew(id: UUID().uuidString)
  }

  static func makeNew(
    id: String,
    forStagedMigration enableStagedMigration: Bool = false,
    model: NSManagedObjectModel = V1.makeManagedObjectModel()
  ) -> OnDiskWithProgrammaticallyModelPersistentContainer {
    let url = URL.newDatabaseURL(withName: id)
    let container = OnDiskWithProgrammaticallyModelPersistentContainer(name: "SampleModel2", managedObjectModel: model)
    let description = NSPersistentStoreDescription()
    description.url = url
    description.shouldMigrateStoreAutomatically = enableStagedMigration
    description.shouldInferMappingModelAutomatically = enableStagedMigration

    // Enable history tracking and remote notifications
    description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    container.persistentStoreDescriptions = [description]

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
