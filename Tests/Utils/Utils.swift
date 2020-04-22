//
// CoreDataPlus
//
// Copyright © 2016-2020 Tinrobots.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import CoreData
@testable import CoreDataPlus

let model = SampleModelVersion.version1.managedObjectModel()

/// True is is tests are run via SPM (both Terminal or Xcode 11)
func isRunningSwiftPackageTests() -> Bool {
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
