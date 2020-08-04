import CoreData
@testable import CoreDataPlus

let model = SampleModelVersion.version1.managedObjectModel()

/// True if tests are run via SPM (both Terminal or Xcode 11)
func isRunningSwiftPackageTests() -> Bool {
  // TODO
  // A Swift Package Test doesn't contain the custom XCODE_TESTS environment key
  // ProcessInfo.processInfo.environment.keys.contains("XCODE_TESTS")
  class Dummy { }
  let testBundle = Bundle(for: Dummy.self)
  let urls = testBundle.urls(forResourcesWithExtension: "momd", subdirectory: nil) ?? []
  return urls.isEmpty
}

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
