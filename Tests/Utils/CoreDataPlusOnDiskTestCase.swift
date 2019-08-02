// 
// CoreDataPlus
//
// Copyright © 2016-2019 Tinrobots.
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

import XCTest
import CoreData
@testable import CoreDataPlus

// MARK: - On Disk XCTestCase

class CoreDataPlusOnDiskTestCase: XCTestCase {
  var container: NSPersistentContainer!
  
  override func setUp() {
    super.setUp()
    container = OnDiskPersistentContainer.makeNew()
  }
  
  override func tearDown() {
    do {
      if let onDiskContainer = container as? OnDiskPersistentContainer {
        try onDiskContainer.destroy()
      }
    } catch {
      XCTFail("The persistent container couldn't be deostryed.")
    }
    container = nil
    super.tearDown()
  }
}

// MARK: - On Disk NSPersistentContainer

final class OnDiskPersistentContainer: NSPersistentContainer {
  static func makeNew() -> OnDiskPersistentContainer {
    let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("org.tinrobots.CoreDataPlusTests").appendingPathComponent(UUID().uuidString)
    let container = OnDiskPersistentContainer(name: "SampleModel", managedObjectModel: model)
    container.persistentStoreDescriptions[0].url = url
    if #available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *) {
      container.persistentStoreDescriptions[0].setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    }
    container.loadPersistentStores { (description, error) in
      XCTAssertNil(error)
    }
    return container
  }
  
  static func makeNew(id: UUID) -> OnDiskPersistentContainer {
    let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("org.tinrobots.CoreDataPlusTests").appendingPathComponent(id.uuidString)
    let container = OnDiskPersistentContainer(name: "SampleModel", managedObjectModel: model)
    container.persistentStoreDescriptions[0].url = url
    if #available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *) {
      container.persistentStoreDescriptions[0].setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    }
    container.loadPersistentStores { (description, error) in
      XCTAssertNil(error)
    }
    return container
  }
  
  /// Destroys the database and reset all the registered contexts.
  func destroy() throws {
    guard let url = persistentStoreDescriptions[0].url else { return }
    guard url.absoluteString != "/dev/null" else { return }
    
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
