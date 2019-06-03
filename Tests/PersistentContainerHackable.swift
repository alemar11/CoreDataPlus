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

import Foundation
import CoreData
import XCTest

let model = SampleModelVersion.version1.managedObjectModel()

protocol PersistentContainerHackable: NSPersistentContainer {
  /// Registers a context in order to do some cleaning during the destroying phase.
  /// "BUG IN CLIENT OF libsqlite3.dylib: database integrity compromised by API violation: vnode unlinked while in use..."
  /// It's an hack to avoid an sqlite3 bug warning when trying to destroy the NSPersistentCoordinator
  func hack_registerContext(_ context: NSManagedObjectContext) -> Void
  /// Destroys the database in a "safe" way (that not causes errors or warnings).
  func destroy() throws -> Void
}

final class OnDiskPersistentContainer: NSPersistentContainer, PersistentContainerHackable {
  static func makeNew() -> OnDiskPersistentContainer {
    let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent(UUID().uuidString)
    let container = OnDiskPersistentContainer(name: "SampleModel", managedObjectModel: model)
    container.persistentStoreDescriptions[0].url = url
    container.loadPersistentStores { (description, error) in
      XCTAssertNil(error)
    }
    return container
  }
  
  private(set) var contexts = [NSManagedObjectContext]()
  
  override var viewContext: NSManagedObjectContext {
    let context = super.viewContext
    hack_registerContext(context)
    return context
  }
  
  override func newBackgroundContext() -> NSManagedObjectContext {
    let context = super.newBackgroundContext()
    hack_registerContext(context)
    return context
  }
  
  func hack_registerContext(_ context: NSManagedObjectContext) {
    if !contexts.contains(context) {
      contexts.append(context)
    }
  }
  
  /// Destroys the database and reset all the registered contexts.
  func destroy() throws {
    let url = persistentStoreDescriptions[0].url!
    // unload each store from the used context avoid the sqlite3 bug warning.
    do {
      let stores = persistentStoreCoordinator.persistentStores
      for store in stores {
        // viewContext is created even if it's not accessed
        if !contexts.contains(viewContext) {
          contexts.append(viewContext)
        }
        
        try contexts.forEach {
          if !($0.persistentStoreCoordinator?.persistentStores.isEmpty ?? true) {
            try $0.persistentStoreCoordinator?.remove(store)
          }
        }
        
        contexts.removeAll()
      }
      try NSPersistentStoreCoordinator.destroyStore(at: url)
    } catch {
      fatalError("\(error) while destroying the store.")
    }
  }
}

final class InMemoryPersistentContainer: NSPersistentContainer, PersistentContainerHackable {
  static func makeNew() -> InMemoryPersistentContainer {
    let url = URL(fileURLWithPath: "/dev/null")
    let container = InMemoryPersistentContainer(name: "SampleModel", managedObjectModel: model)
    container.persistentStoreDescriptions[0].url = url
    container.loadPersistentStores { (description, error) in
      XCTAssertNil(error)
    }
    return container
  }
  
  private(set) var contexts = [NSManagedObjectContext]()
  
  override var viewContext: NSManagedObjectContext {
    let context = super.viewContext
    hack_registerContext(context)
    return context
  }
  
  override func newBackgroundContext() -> NSManagedObjectContext {
    let context = super.newBackgroundContext()
    hack_registerContext(context)
    return context
  }
  
  /// Registers a context in order to do some cleaning during the destroying phase.
  /// It's a hack to avoid an sqlite3 bug warning when trying to destroy the NSPersistentCoordinator
  func hack_registerContext(_ context: NSManagedObjectContext) {
    if !contexts.contains(context) {
      contexts.append(context)
    }
  }
  
  /// Destroys the database and reset all the registered contexts.
  func destroy() throws {
    do {
      let stores = persistentStoreCoordinator.persistentStores
      for store in stores {
        // viewContext is created even if it's not accessed
        if !contexts.contains(viewContext) {
          contexts.append(viewContext)
        }
        
        try contexts.forEach {
          if !($0.persistentStoreCoordinator?.persistentStores.isEmpty ?? true) {
            try $0.persistentStoreCoordinator?.remove(store)
          }
        }
        contexts.removeAll()
      }
    } catch {
      fatalError("\(error) while destroying the store.")
    }
  }
}
