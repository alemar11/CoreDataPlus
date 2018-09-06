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
  case version2 = "SampleModel2" // is equal to version1
}

extension SampleModelVersion: ModelVersion {

  public static var allVersions: [SampleModelVersion] { return [.version1, .version2] }

  public static var currentVersion: SampleModelVersion { return .version1 }

  public var successor: SampleModelVersion? {
    switch self {
    case .version1: return .version2
    //case .version2: return .version3
    default: return nil
    }
  }

  public var versionName: String { return rawValue }

//  public var persistentStoreURL: URL {
//    class Object {} // used to get the current bundle 🤓
//    return Bundle(for: Object.self).url(forResource: versionName, withExtension: ".sqlite")!
//  }

  public var modelBundle: Bundle {
    class Object {} // used to get the current bundle 🤓
    return Bundle(for: Object.self)
  }

  /// Hack-ish way to load the NSManagedObjectModel without using the Bundle.
  /// - Note: This is not enough to run the spm tests because the enviroment doesn't contain the "required" values.
  public func managedObjectModel_swift_package_tests() -> NSManagedObjectModel {
    let sampleFolderURL = URL(fileURLWithPath: #file, isDirectory: false).deletingLastPathComponent()
    let momUrl = sampleFolderURL.appendingPathComponent("\(versionName).momd/\(versionName).mom")

    XCTAssertTrue(FileManager.default.fileExists(atPath: momUrl.path))

    guard let model = NSManagedObjectModel(contentsOf: momUrl) else { preconditionFailure("Error initializing Managed Object Model: cannot open model at \(momUrl).") }

    return model
  }

  public var modelName: String { return "SampleModel" }

}

