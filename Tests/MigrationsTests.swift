//
// CoreDataPlus
//
// Copyright © 2016-2018 Tinrobots.
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

class MigrationsTests: XCTestCase {

  let fileManager = FileManager.default

  // MARK: - LightWeight Migration

  func testMigrationFromVersion1ToVersion2() throws {
    let stack = CoreDataStack.stack(type: .sqlite)
    let context = stack.mainContext
    context.fillWithSampleData()
    try context.save()

    let allCars = try Car.fetch(in: context)
    let sportCars = try ExpensiveSportCar.fetch(in: context)

    if #available(iOS 11, tvOS 11, macOS 10.13, *) {
      XCTAssertEqual(allCars.first!.entity.indexes.count, 0)
    }

    let targetVersion = SampleModelVersion.version2
    let steps = SampleModelVersion.version1.migrationSteps(to: .version2)
    XCTAssertEqual(steps.count, 1)

    let sourceURL = stack.storeURL!
    let targetURL = stack.storeURL!

    // When
    try Migration.migrateStore(at: sourceURL, targetVersion: targetVersion)
    let migratedContext = NSManagedObjectContext(model: targetVersion.managedObjectModel(), storeURL: targetURL)
    let luxuryCars = try LuxuryCar.fetch(in: migratedContext)
    XCTAssertEqual(sportCars.count, luxuryCars.count)

    let cars = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Car"))
    XCTAssertTrue(cars.count >= 1)

    if #available(iOS 11, tvOS 11, macOS 10.13, *) {
      let car = cars.first!
      let index = car.entity.indexes.first
      XCTAssertNotNil(index, "There should be a compound index")
      XCTAssertEqual(index!.elements.count, 2)

      let propertyNames = car.entity.indexes.flatMap { $0.elements }.compactMap { $0.propertyName }
      XCTAssertTrue(propertyNames.contains("maker") && propertyNames.contains("numberPlate"))
    }

    try Migration.migrateStore(from: sourceURL, to: targetURL, targetVersion: targetVersion)
  }

  // MARK: - HeavyWeight Migration

  func testMigrationFromVersion2ToVersion3() throws {
    if ProcessInfo.isRunningSwiftPackageTests {
      print("Not implemented")
      return
    }

    let bundle = Bundle(for: MigrationsTests.self)
    let sourceURL = bundle.url(forResource: "SampleModelV2", withExtension: "sqlite")!
    let targetURL = sourceURL

    try Migration.migrateStore(from: sourceURL, to: targetURL, targetVersion: SampleModelVersion.version3)

    let migratedContext = NSManagedObjectContext(model: SampleModelVersion.version3.managedObjectModel(), storeURL: targetURL)
    let cars = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Car"))
    let makers = try Maker.fetch(in: migratedContext)
    XCTAssertEqual(makers.count, 11)

    //try cars.fetchFaultedObjects()
    //print(cars)

    cars.forEach { object in
      let owner = object.value(forKey: "owner") as? NSManagedObject
      let maker = object.value(forKey: "createdBy") as? NSManagedObject
      XCTAssertNotNil(maker)
      let name = maker!.value(forKey: "name") as! String
      maker!.setValue("--\(name)--", forKey: "name")
      let previousOwners = object.value(forKey: "previousOwners") as! Set<NSManagedObject>

      if let carOwner = owner {
        XCTAssertTrue(previousOwners.contains(carOwner))
        let previousCars = carOwner.value(forKey: "previousCars") as! Set<NSManagedObject>
        XCTAssertTrue(previousCars.contains(object))
      } else {
        XCTAssertEqual(previousOwners.count, 0)
      }
    }

    try migratedContext.save()
    XCTAssertTrue(fileManager.fileExists(atPath: targetURL.path))
  }


  func testMigrationFromVersion1ToVersion3() throws {
    if ProcessInfo.isRunningSwiftPackageTests {
      print("Not implemented")
      return
    }

    let bundle = Bundle(for: MigrationsTests.self)
    let sourceURL = bundle.url(forResource: "SampleModelV1", withExtension: "sqlite")!
    let targetURL = URL.temporary.appendingPathComponent("SampleModel").appendingPathExtension("sqlite")

    let progress = Progress(parent: nil, userInfo: nil) //TODO: test
    try Migration.migrateStore(from: sourceURL, to: targetURL, targetVersion: SampleModelVersion.version3, deleteSource: true, progress: progress)

    let migratedContext = NSManagedObjectContext(model: SampleModelVersion.version3.managedObjectModel(), storeURL: targetURL)
    let makers = try migratedContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Maker"))
    XCTAssertEqual(makers.count, 11)

    makers.forEach { (maker) in
      let name = maker.value(forKey: "name") as! String
      maker.setValue("--\(name)--", forKey: "name")
    }
    try migratedContext.save()

    XCTAssertFalse(fileManager.fileExists(atPath: sourceURL.path))
    XCTAssertTrue(fileManager.fileExists(atPath: targetURL.path))
  }
}

extension NSManagedObjectContext {

  convenience init(model: NSManagedObjectModel, storeURL: URL) {
    let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
    try! psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
    self.init(concurrencyType: .mainQueueConcurrencyType)
    persistentStoreCoordinator = psc
  }

}

