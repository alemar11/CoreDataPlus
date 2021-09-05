// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

final class NSPersistentStoreCoordinatorUtilsTests: BaseTestCase {
  func testInvestigationMetadata() throws {
    let id = UUID()
    let container = OnDiskPersistentContainer.makeNew(id: id)
    let url = container.persistentStoreCoordinator.persistentStores.first!.url!
    let options: PersistentStoreOptions = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]

    var metaData = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: url, options: nil)
    metaData["testKey"] = "Test"
    try NSPersistentStoreCoordinator.setMetadata(metaData, forPersistentStoreOfType: NSSQLiteStoreType, at: url, options: options)
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
      psc1.setMetadataObject("Test", with: "testKey", for: store1)
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

  func testDestroyMissingStore() throws {
    let wrongURL = URL(fileURLWithPath: "/dev/null")
    XCTAssertThrowsError(try NSPersistentStoreCoordinator.destroyStore(at: wrongURL))

    let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let wrongURL2 = cachesURL.appendingPathComponent(bundleIdentifier).appendingPathComponent("\(#file)\(#function)")
    XCTAssertThrowsError(try NSPersistentStoreCoordinator.destroyStore(at: wrongURL2))
  }
}
