// CoreDataPlus

import CoreData
import XCTest
@testable import CoreDataPlus

final class NSSetCoreDataTests: CoreDataPlusInMemoryTestCase {

  func testMaterializeFaultedManagedObjects() throws {
    let context = container.viewContext
    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    let request = Person.newFetchRequest()
    request.returnsObjectsAsFaults = true
    let foundPerson = try Person.materializedObjectOrFetch(in: context, where: NSPredicate(format: "\(#keyPath(Person.firstName)) == %@ AND \(#keyPath(Person.lastName)) == %@", "Theodora", "Stone"))
    let person = try XCTUnwrap(foundPerson)
    context.refreshAllObjects()

    let initialFaultsCount = person.cars?.filter { object in
      if let managedCar = object as? Car {
        return managedCar.isFault
      }
      XCTFail("A Car object was expected")
      return false
    }.count

    XCTAssertEqual(initialFaultsCount, person.cars?.count ?? 0)
    try person.cars?.materializeManagedObjectFaults()

    let finalFaultsCount = person.cars?.filter { object in
      if let managedCar = object as? Car {
        return managedCar.isFault
      }
      XCTFail("A Car object was expected")
      return false
    }.count

    XCTAssertEqual(finalFaultsCount, 0)
  }

  func testDeleteManagedObjects() throws {
    let context = container.viewContext
    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    let request = Person.newFetchRequest()
    request.returnsObjectsAsFaults = true
    let foundPerson = try Person.materializedObjectOrFetch(in: context, where: NSPredicate(format: "\(#keyPath(Person.firstName)) == %@ AND \(#keyPath(Person.lastName)) == %@", "Theodora", "Stone"))
    let person = try XCTUnwrap(foundPerson)

    context.refreshAllObjects()
    XCTAssertEqual(person.cars?.count ?? 0, 100)
    person.cars?.deleteManagedObjects()
    try context.save()
    XCTAssertEqual(person.cars?.count ?? 0, 0)
  }
}
