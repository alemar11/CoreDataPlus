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

let model = SampleModelVersion.version1.managedObjectModel()

final class TestPersistentContainer: NSPersistentContainer {
  var contexts = [NSManagedObjectContext]()
  override var viewContext: NSManagedObjectContext {
    let context = super.viewContext
    registerContext(context)
    return context
  }
  
  override func newBackgroundContext() -> NSManagedObjectContext {
    let context = super.newBackgroundContext()
    registerContext(context)
    return context
  }
  
  func registerContext(_ context: NSManagedObjectContext) {
    if !contexts.contains(context) {
      contexts.append(context)
    }
  }
}

class CoreDataPlusTestCase: XCTestCase {
  var container: TestPersistentContainer!
  
  override func setUp() {
    super.setUp()
    let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent(UUID().uuidString)
    container = TestPersistentContainer(name: "SampleModel", managedObjectModel: model)
    container.persistentStoreDescriptions[0].url = url //URL(fileURLWithPath: "/dev/null")
    container.loadPersistentStores { (description, error) in
      XCTAssertNil(error)
    }
  }

  override func tearDown() {
    let url = container.persistentStoreDescriptions[0].url!
    // unload each store from the used context avoid the sqlite3 bug warning.
    do {
      let stores = container.persistentStoreCoordinator.persistentStores
      for store in stores {
        container.contexts.forEach {
          try! $0.persistentStoreCoordinator?.remove(store)
        }
        
      }
      try NSPersistentStoreCoordinator.destroyStore(at: url)
    } catch {
      print("\(error) while destroying store.")
    }
    container = nil
    super.tearDown()
  }
}

