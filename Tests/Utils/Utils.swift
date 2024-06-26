// CoreDataPlus

import CoreData

@testable import CoreDataPlus

// It should be fine to mark these as Sendable because they can be shared between different threads.
// https://duckrowing.com/2010/03/11/using-core-data-on-multiple-threads/
extension NSManagedObjectContext: @unchecked Sendable {}
extension NSManagedObjectModel: @unchecked Sendable {}

// MARK: - URL

extension URL {
  static func newDatabaseURL(withID id: UUID) -> URL {
    newDatabaseURL(withName: id.uuidString)
  }

  static func newDatabaseURL(withName name: String) -> URL {
    let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let testsURL = cachesURL.appendingPathComponent(bundleIdentifier)
    var directory: ObjCBool = ObjCBool(true)
    let directoryExists = FileManager.default.fileExists(atPath: testsURL.path, isDirectory: &directory)

    if !directoryExists {
      try! FileManager.default.createDirectory(at: testsURL, withIntermediateDirectories: true, attributes: nil)
    }

    let databaseURL = testsURL.appendingPathComponent("\(name).sqlite")
    return databaseURL
  }

  static var temporaryDirectory: URL {
    let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent(bundleIdentifier)
      .appendingPathComponent(UUID().uuidString)
    try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    return url
  }
}

extension Foundation.Bundle {
  fileprivate class Dummy {}

  static var tests: Bundle {
    #if SWIFT_PACKAGE
      return Bundle.module
    #else
      return Bundle(for: Dummy.self)
    #endif
  }

  /// Returns the resource bundle associated with the current Swift module.
  /// Note: the implementation is very close to the one provided by the Swift Package with `Bundle.module` (that is not available for XCTests).
  nonisolated(unsafe) static var moduleOldImplementation: Bundle = {
    let bundleName = "CoreDataPlus_Tests"

    let candidates = [
      // Bundle should be present here when the package is linked into an App.
      Bundle.main.resourceURL,
      // Bundle should be present here when the package is linked into a framework.
      Bundle(for: Dummy.self).resourceURL,
      // For command-line tools.
      Bundle.main.bundleURL,
    ]

    // Search for resources bundle when running Swift Package tests from Xcode
    for candidate in candidates {
      let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
      if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
        return bundle
      }
    }

    // Search for resources bundle when running Swift Package tests from terminal (swift test)
    // It's probably a fix for this:
    // https://forums.swift.org/t/5-3-resources-support-not-working-on-with-swift-test/40381/10
    // https://github.com/apple/swift-package-manager/pull/2905
    // https://bugs.swift.org/browse/SR-13560
    let url = Bundle(for: Dummy.self)
      .bundleURL
      .deletingLastPathComponent()
      .appendingPathComponent(bundleName + ".bundle")

    if let bundle = Bundle(url: url) {
      return bundle
    }

    // XCTests Fallback
    return Bundle(for: Dummy.self)
  }()
}

// MARK: - NSManagedObjectContext

extension NSManagedObjectContext {
  convenience init(model: NSManagedObjectModel, storeURL: URL) {
    let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
    try! psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
    self.init(concurrencyType: .mainQueueConcurrencyType)
    persistentStoreCoordinator = psc
  }

  func _fix_sqlite_warning_when_destroying_a_store() {
    /// If SQLITE_ENABLE_FILE_ASSERTIONS is set to 1 tests crash without this fix.
    /// solve the warning: "BUG IN CLIENT OF libsqlite3.dylib: database integrity compromised by API violation: vnode unlinked while in use..."
    try! persistentStoreCoordinator!.removeAllStores()
  }
}
