// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

final class NSPersistentStoreCoordinatorUtilsTests: XCTestCase {
  func testDestroyMissingStore() throws {
    let wrongURL = URL(fileURLWithPath: "/dev/null")
    XCTAssertThrowsError(try NSPersistentStoreCoordinator.destroyStore(at: wrongURL))

    let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let wrongURL2 = cachesURL.appendingPathComponent(bundleIdentifier).appendingPathComponent("\(#file)\(#function)")
    XCTAssertThrowsError(try NSPersistentStoreCoordinator.destroyStore(at: wrongURL2))
  }
}
