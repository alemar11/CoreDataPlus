//
// CoreDataPlus
//
//  Copyright © 2016-2018 Tinrobots.
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
import XCTest
@testable import CoreDataPlus

public enum SampleModelVersion: String {
  case version1 = "SampleModel"
}

extension SampleModelVersion: ModelVersion {

  public static var allVersions: [SampleModelVersion] { return [.version1] }

  public static var currentVersion: SampleModelVersion { return .version1 }

  public var versionName: String { return rawValue }

  public var modelBundle: Bundle {
    class Object {} // used to get the current bundle 🤓
    return Bundle(for: Object.self)
  }

  /// Hack-ish way to load the NSManagedObjectModel without using the Bundle.
  public func managedObjectModel_swift_package_tests() -> NSManagedObjectModel {
    let environment = ProcessInfo.processInfo.environment

    guard
      let path = environment["__XPC_DYLD_FRAMEWORK_PATH"],
      let bundleName = environment["IDEiPhoneInternalTestBundleName"],
      let url = URL(string: path)
      else {
        XCTFail("Missing enviroment values.")
        fatalError()
    }

    let bundleUrl = url.appendingPathComponent(bundleName)

    let momUrl: URL

    #if os(macOS)
      momUrl = bundleUrl.appendingPathComponent("Contents/Resources/")
    #endif

    momUrl = bundleUrl.appendingPathComponent("\(versionName).momd/\(versionName).mom")

    XCTAssertTrue(FileManager.default.fileExists(atPath: momUrl.absoluteString.removingPercentEncoding!))
    guard let model = NSManagedObjectModel(contentsOf: momUrl) else { preconditionFailure("Error initializing Managed Object Model: cannot open model at \(momUrl).") }

    return model
  }

  public var modelName: String { return "SampleModel" }

}

