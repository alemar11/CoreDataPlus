// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

final class NSPersistentStoreCoordinatorUtilsTests: BaseTestCase {
  func testMetadata() throws {
    // Given
    let id = UUID()
    let container1 = OnDiskPersistentContainer.makeNew(id: id)
    let store1 = try XCTUnwrap(container1.persistentStoreCoordinator.persistentStores.first)
    let psc1 = container1.persistentStoreCoordinator // ot context.persistentStoreCoordinator!

    // When
    let metaData = psc1.metadata(for: store1)
    XCTAssertNotNil((metaData["NSStoreModelVersionHashes"] as? [String: Any])?[Car.entityName])
    XCTAssertNotNil((metaData["NSStoreModelVersionHashes"] as? [String: Any])?[Person.entityName])
    XCTAssertNotNil(metaData["NSStoreType"] as? String)

    // ⚠️ A context associated with the psc must be saved to actually persist the metadata changes on disk
    try container1.viewContext.performAndWait { _ in
      psc1.setMetadataValue("Test", with: "testKey", for: store1)
      try container1.viewContext.save()
    }

    // Then
    let updatedMetaData = psc1.metadata(for: store1)
    XCTAssertNotNil(updatedMetaData["testKey"])
    XCTAssertEqual(updatedMetaData["testKey"] as? String, "Test")

    // If the context is not saved, the metadata won't be persisted and these next tests will fail
    let container2 = OnDiskPersistentContainer.makeNew(id: id)
    let psc2 = container2.persistentStoreCoordinator
    let store2 = try XCTUnwrap(container2.persistentStoreCoordinator.persistentStores.first)
    let updatedMetaData2 = psc2.metadata(for: store2)
    XCTAssertNotNil(updatedMetaData2["testKey"])
    XCTAssertEqual(updatedMetaData2["testKey"] as? String, "Test")

    try psc2.removeAllStores() // container2 must unload the store otherwise container1 can't be destroyed (SQLITE error) because they point to the same db
    try container1.destroy()
    try container2.destroy()
  }

  func testInvestigationSettingMetadataFromPersistentStore() throws {
    let id = UUID()
    let container = OnDiskPersistentContainer.makeNew(id: id)
    let store = try XCTUnwrap(container.persistentStoreCoordinator.persistentStores.first)
    var metadata = store.metadata ?? [String : Any]()
    metadata["testKey"] = "Test"
    store.metadata = metadata

    // ⚠️ A context associated with the container store must be saved to actually persist the metadata changes on disk
    try container.viewContext.performAndWait { _ in
      try container.viewContext.save()
    }

    let container2 = OnDiskPersistentContainer.makeNew(id: id)
    let store2 = try XCTUnwrap(container2.persistentStoreCoordinator.persistentStores.first)
    let metadata2 =  try XCTUnwrap(store2.metadata)
    print(metadata2)
    XCTAssertNotNil(metadata2["testKey"])
    XCTAssertEqual(metadata2["testKey"] as? String, "Test")
  }

  func testInvestigationSettingMetadataFromPersistentStoreCoordinator() throws {
    // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/PersistentStoreFeatures.html
    // There are two ways you can set the metadata for a store:
    //
    // 1. Given an instance of a persistent store, set its metadata using the NSPersistentStoreCoordinator instance method, "setMetadata:forPersistentStore:".
    // 2. Set the metadata without the overhead of creating a persistence stack by using the NSPersistentStoreCoordinator class method,
    //    "setMetadata:forPersistentStoreOfType:URL:error:".
    //
    // There is again an important difference between these approaches.
    // If you use setMetadata:forPersistentStore:, you must save the store (through a managed object context) before the new metadata is saved.
    // If you use setMetadata:forPersistentStoreOfType:URL:error:, however, the metadata is updated immediately, and the last-modified date of the file is changed.
    let id = UUID()
    let container = OnDiskPersistentContainer.makeNew(id: id)
    let url = container.persistentStoreCoordinator.persistentStores.first!.url!

    var metaData = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: url, options: nil)
    metaData["testKey"] = "Test"
    try NSPersistentStoreCoordinator.setMetadata(metaData, forPersistentStoreOfType: NSSQLiteStoreType, at: url, options: nil)
    let metaData2 = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: url, options: nil)
    XCTAssertNotNil(metaData2["testKey"])
    XCTAssertEqual(metaData2["testKey"] as? String, "Test")

    // Already loaded container must remove and reload the store to see the changes
    try container.persistentStoreCoordinator.removeAllStores()
    try container.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
    let psc = container.persistentStoreCoordinator
    let store = try XCTUnwrap(container.persistentStoreCoordinator.persistentStores.first)
    let updatedMetaData = psc.metadata(for: store)
    XCTAssertNotNil(updatedMetaData["testKey"])
    XCTAssertEqual(updatedMetaData["testKey"] as? String, "Test")

    // A just loaded container sees the metadatachanges right away
    let container2 = OnDiskPersistentContainer.makeNew(id: id)
    let psc2 = container2.persistentStoreCoordinator
    let store2 = try XCTUnwrap(container2.persistentStoreCoordinator.persistentStores.first)
    let updatedMetaData2 = psc2.metadata(for: store2)
    XCTAssertNotNil(updatedMetaData2["testKey"])
    XCTAssertEqual(updatedMetaData2["testKey"] as? String, "Test")
  }

  func testDestroyMissingStore() throws {
    let wrongURL = URL(fileURLWithPath: "/dev/null")
    XCTAssertThrowsError(try NSPersistentStoreCoordinator.destroyStore(at: wrongURL))

    let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let wrongURL2 = cachesURL.appendingPathComponent(bundleIdentifier).appendingPathComponent("\(#file)\(#function)")
    XCTAssertThrowsError(try NSPersistentStoreCoordinator.destroyStore(at: wrongURL2))
  }
}
