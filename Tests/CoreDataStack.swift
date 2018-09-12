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

import XCTest
import CoreData

final class CoreDataStack {

  enum StoreType { case sqlite, inMemory }

  private(set) var persistentStoreCoordinator: NSPersistentStoreCoordinator
  private(set) var mainContext: NSManagedObjectContext
  private(set) var storeURL: URL?

  init?(type: StoreType = .inMemory) {

    let managedObjectModel: NSManagedObjectModel

    XCTAssertTrue(ProcessInfo.isRunningUnitTests)

    if ProcessInfo.isRunningSwiftPackageTests {
      managedObjectModel = SampleModelVersion.currentVersion.managedObjectModel_swift_package_tests()
    } else {
      managedObjectModel = SampleModelVersion.currentVersion.managedObjectModel()
    }
    persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

    switch (type) {

    case .inMemory:
      do {
        try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
      } catch {
        XCTFail("\(error.localizedDescription)")
      }

    case .sqlite:
      storeURL = URL.temporary.appendingPathComponent("SampleModel.sqlite")
      let persistentStoreDescription = NSPersistentStoreDescription(url: storeURL!)

      persistentStoreDescription.type = NSSQLiteStoreType
      persistentStoreDescription.shouldMigrateStoreAutomatically = true // default behaviour: true
      persistentStoreDescription.shouldInferMappingModelAutomatically = false // default behaviour (lightweight)
      persistentStoreDescription.shouldAddStoreAsynchronously = false // default

      persistentStoreCoordinator.addPersistentStore(with: persistentStoreDescription, completionHandler: { (persistentStoreDescription, error) in
        if let error = error { XCTFail(error.localizedDescription) }
      })
    }

    let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
    mainContext = managedObjectContext
  }

}

extension CoreDataStack {
  class func stack(type: StoreType = .inMemory) -> CoreDataStack {
    let _stack = CoreDataStack(type: type)
    guard let stack = _stack else {
      XCTAssertNotNil(_stack)
      fatalError()
    }
    return stack
  }
}

extension URL {

  static var temporary: URL {
    return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)
  }

}
