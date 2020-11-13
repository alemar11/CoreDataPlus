// CoreDataPlus

import CoreData
@testable import CoreDataPlus

let model = SampleModelVersion.version1.managedObjectModel()

extension URL {
  static func newDatabaseURL(withID id: UUID) -> URL {
    let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let testsURL = cachesURL.appendingPathComponent(bundleIdentifier)
    var directory: ObjCBool = ObjCBool(true)
    let directoryExists = FileManager.default.fileExists(atPath: testsURL.path, isDirectory: &directory)

    if !directoryExists {
      try! FileManager.default.createDirectory(at: testsURL, withIntermediateDirectories: true, attributes: nil)
    }

    let databaseURL = testsURL.appendingPathComponent("\(id).sqlite")
    return databaseURL
  }

  static var temporaryDirectoryURL: URL {
    let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory:true)
      .appendingPathComponent(bundleIdentifier)
      .appendingPathComponent(UUID().uuidString)
    try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    return url
  }
}

extension Foundation.Bundle {
  fileprivate class Dummy { }

  /// Returns the resource bundle associated with the current Swift module.
  /// Note: the implementation is very close to the one provided by the Swift Package with `Bundle.module` (that is not available for XCTests).
  static var tests: Bundle = {
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
    let url = Bundle(for: Dummy.self).bundleURL.deletingLastPathComponent().appendingPathComponent(bundleName + ".bundle")
    if let bundle = Bundle(url: url) {
      return bundle
    }

    // XCTests Fallback
    return Bundle(for: Dummy.self)
  }()
}

