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

final class NSFetchRequestResultUtilsTests: CoreDataPlusTestCase {

  // MARK: - Batch Faulting

  func testBatchFaulting() throws {
    // Given
    let context = container.viewContext

    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    /// re-fault objects that don't have pending changes
    context.refreshAllObjects()

    let request = Car.newFetchRequest()
    request.predicate = NSPredicate(value: true)


    // When
    let cars = try context.fetch(request)

    /// re-fault objects that don't have pending changes
    context.refreshAllObjects()

    let previousFaultsCount = cars.filter { $0.isFault }.count

    /// batch faulting
    XCTAssertNoThrow(try cars.fetchFaultedObjects())

    // Then
    let currentNotFaultsCount = cars.filter { !$0.isFault }.count
    let currentFaultsCount = cars.filter { $0.isFault }.count
    XCTAssertTrue(previousFaultsCount == currentNotFaultsCount)
    XCTAssertTrue(currentFaultsCount == 0)

  }

  func testBatchFaultingEdgeCases() throws {
    // Given
    let context = container.viewContext
    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    // empty data set
    let objects: [NSManagedObject] = []
    XCTAssertNoThrow(try objects.fetchFaultedObjects())

    // no faults objects
    let request = Car.newFetchRequest()
    request.predicate = NSPredicate(value: true)
    request.returnsObjectsAsFaults = false
    request.fetchLimit = 2

    // When
    let cars = try context.fetch(request)
    let previousFaultsCount = cars.filter { $0.isFault }.count
    let previousNotFaultsCount = cars.filter { !$0.isFault }.count

    XCTAssertNoThrow(try cars.fetchFaultedObjects())

    // Then
    let currentFaultsCount = cars.filter { $0.isFault }.count
    let currentNotFaultsCount = cars.filter { !$0.isFault }.count
    XCTAssertTrue(previousFaultsCount == 0)
    XCTAssertTrue(currentFaultsCount == 0)
    XCTAssertTrue(previousNotFaultsCount == currentNotFaultsCount)

  }

  func testBatchFaultingWithDifferentContexts() {
    // Given
    let context1 = container.viewContext
    let context2 = context1.newBackgroundContext(asChildContext: false)

    let car1 = Car(context: context1)
    car1.numberPlate = "car1-testBatchFaultingWithDifferentContexts"
    let sportCar1 = SportCar(context: context1)
    sportCar1.numberPlate = "sportCar1-testBatchFaultingWithDifferentContexts"

    let person2 = context2.performAndWait { context -> Person in
      let person = Person(context: context2)
      person.firstName = "firstName-testBatchFaultingWithDifferentContexts"
      person.lastName = "lastName-testBatchFaultingWithDifferentContexts"
      return person
    }

    let car2 = context2.performAndWait { context -> Car in
      let car = Car(context: context2)
      car.numberPlate = "car2-testBatchFaultingWithDifferentContexts"
      return car
    }

    context1.performAndWait {
      try! context1.save()
    }

    context2.performAndWait {
      try! context2.save()
    }

    // When
    context1.refreshAllObjects()
    context2.performAndWait {
      context2.refreshAllObjects()
    }

    let objects = [car1, sportCar1, person2, car2]

    // Then
    XCTAssertTrue(objects.filter { !$0.isFault }.isEmpty)
    XCTAssertNoThrow(try objects.fetchFaultedObjects())
    XCTAssertTrue(objects.filter { !$0.isFault }.count == 4)
  }

  func testBatchFaultingToManyRelationship() throws {
    let context = container.viewContext

    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    context.refreshAllObjects() //re-fault objects that don't have pending changes

    let request = Person.newFetchRequest()
    request.predicate = NSPredicate(format: "\(#keyPath(Person.firstName)) == %@ AND \(#keyPath(Person.lastName)) == %@", "Theodora", "Stone")

    let persons = try context.fetch(request)

    XCTAssertNotNil(persons)
    XCTAssertTrue(!persons.isEmpty)

    let person = persons.first!
    let previousFaultsCount = person.cars?.filter { $0.isFault }.count

    XCTAssertNoThrow(try person.cars?.fetchFaultedObjects())
    let currentNotFaultsCount = person.cars?.filter { !$0.isFault }.count
    let currentFaultsCount = person.cars?.filter { $0.isFault }.count
    XCTAssertTrue(previousFaultsCount == currentNotFaultsCount)
    XCTAssertTrue(currentFaultsCount == 0)

  }

  // MARK: - Fetch

  func testFetch() throws {
    let context = container.viewContext

    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    do {
      let persons = try Person.fetch(in: context) { request in
        request.predicate = NSPredicate(format: "\(#keyPath(Person.lastName)) == %@", "Moreton")
      }
      XCTAssertTrue(persons.count == 2)
    }

    do {
      let persons = try Person.fetch(in: context) { request in
        request.predicate = NSPredicate(format: "\(#keyPath(Person.lastName)) == %@", "MoretonXYZ")
      }
      XCTAssertTrue(persons.isEmpty)
    }

  }

  // MARK: - Count

  func testCount() throws {
    let context = container.viewContext

    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    do {
      let persons = try Person.count(in: context) { request in
        request.predicate = NSPredicate(format: "\(#keyPath(Person.lastName)) == %@", "Moreton")
      }
      XCTAssertTrue(persons == 2)
    }

    do {
      let persons = try Person.count(in: context) { request in
        request.predicate = NSPredicate(format: "\(#keyPath(Person.lastName)) == %@", "MoretonXYZ")
      }
      XCTAssertTrue(persons == 0)
    }

  }

  // MARK: - Unique

  func testFetchUniqueObject() throws {
    let context = container.viewContext

    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    do {
      _ = try Person.fetchUniqueObject(in: context) { request in
        request.predicate = NSPredicate(format: "\(#keyPath(Person.lastName)) == %@", "Moreton")
      }
      XCTFail("This fetch should fail because the result should have more than 1 resul.")
    } catch {
      XCTAssertNotNil(error)
    }

    do {
      let person = try Person.fetchUniqueObject(in: context) { request in
        request.predicate = NSPredicate(format: "\(#keyPath(Person.lastName)) == %@", "MoretonXYZ")
      }
      XCTAssertNil(person)
    }

    do {
      let person = try Person.fetchUniqueObject(in: context) { request in
        request.predicate = NSPredicate(format: "\(#keyPath(Person.firstName)) == %@ AND \(#keyPath(Person.lastName)) == %@", "Theodora", "Stone")
      }
      XCTAssertNotNil(person)
    }

  }

  func testFindUniqueOrCreate() throws {
    let context = container.viewContext

    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    /// existing object
    do {
      let car = try Car.findUniqueOrCreate(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")) { car in
        XCTAssertNotNil(car.numberPlate)
      }

      XCTAssertNotNil(car)
      XCTAssertTrue(car.maker == "Lamborghini")
    }

    /// new object
    do {
      let car = try Car.findUniqueOrCreate(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304-new"), with: { car in
        XCTAssertNil(car.numberPlate)
        car.numberPlate = "304-new"
        car.model = "test"
      })
      XCTAssertNotNil(car)
      XCTAssertNil(car.maker)
      XCTAssertEqual(car.numberPlate, "304-new")
      XCTAssertEqual(car.model, "test")
      context.delete(car)
    }

    /// new object added in the context before the fetch

    // first we materialiaze all cars
    XCTAssertNoThrow( try Car.fetch(in: context) { request in request.returnsObjectsAsFaults = false })
    let car = Car(context: context)
    car.numberPlate = "304"
    car.maker = "fake-maker"
    car.model = "fake-model"

    XCTAssertThrowsError(try Car.findUniqueOrCreate(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304"), with: { _ in }))

    /// multiple objects, the first one matching the condition is returned

    XCTAssertThrowsError(try Car.findUniqueOrCreate(in: context, where: NSPredicate(value: true), with: { _ in }))

  }

  func testFindUniqueMaterializedObject() throws {
    let context = container.viewContext

    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    // materialize all expensive sport cars
    let request = ExpensiveSportCar.newFetchRequest()
    request.returnsObjectsAsFaults = false
    request.predicate = NSPredicate(value: true)
    _ = try context.fetch(request)

    XCTAssertThrowsError(try Car.findUniqueMaterializedObject(in: context, where: NSPredicate(value: true)))

    let predicate = NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")
    XCTAssertNotNil(Car.findOneMaterializedObject(in: context, where: predicate))

    // de-materialize all objects
    context.refreshAllObjects()

    XCTAssertNil(Car.findOneMaterializedObject(in: context, where: predicate))

  }

  // MARK: - First

  func testFindFirstOrCreate() throws {
    let context = container.viewContext

    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    /// existing object
    do {
      let car = try Car.findOneOrCreate(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")) { car in
        XCTAssertNotNil(car.numberPlate)
      }
      XCTAssertNotNil(car)
      XCTAssertTrue(car.maker == "Lamborghini")
    }

    /// new object
    do {
      let car = try Car.findOneOrCreate(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304-new"), with: { car in
        XCTAssertNil(car.numberPlate)
        car.numberPlate = "304-new"
        car.model = "test"
      })
      XCTAssertNotNil(car)
      XCTAssertNil(car.maker)
      XCTAssertEqual(car.numberPlate, "304-new")
      XCTAssertEqual(car.model, "test")
      context.delete(car)
    }

    /// new object added in the context before the fetch

    // first we materialiaze all cars
    XCTAssertNoThrow( try Car.fetch(in: context) { request in request.returnsObjectsAsFaults = false })
    let car = Car(context: context)
    car.numberPlate = "304"
    car.maker = "fake-maker"
    car.model = "fake-model"

    do {
      let car = try Car.findOneOrCreate(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304"), with: { car in
        XCTAssertNil(car.numberPlate)
      })
      XCTAssertNotNil(car)

      let car304 = context.registeredObjects.filter{ $0 is Car } as! Set<Car>

      XCTAssertTrue(car304.filter { $0.numberPlate == "304" }.count == 2)
    }

    context.refreshAllObjects()

    /// multiple objects, the first one matching the condition is returned
    do {
      let car = try Car.findOneOrCreate(in: context, where: NSPredicate(value: true), with: { car in
        XCTAssertNotNil(car.numberPlate)
      })
      XCTAssertNotNil(car)
    }

  }

  func testFindFirstMaterializedObject() throws {
    let context = container.viewContext

    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    // materialize all expensive sport cars
    let request = ExpensiveSportCar.newFetchRequest()
    request.returnsObjectsAsFaults = false
    request.predicate = NSPredicate(value: true)

    _ = try context.fetch(request)

    XCTAssertNotNil(Car.findOneMaterializedObject(in: context, where: NSPredicate(value: true)))

    let predicate = NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")
    XCTAssertNotNil(Car.findOneMaterializedObject(in: context, where: predicate))

    // de-materialize all objects
    context.refreshAllObjects()

    XCTAssertNil(Car.findOneMaterializedObject(in: context, where: predicate))

  }

  // MARK: Materialized Object

  func testFindMaterializedObjects() throws {
    let context = container.viewContext

    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    // materialize all expensive sport cars
    let request = ExpensiveSportCar.newFetchRequest()
    request.returnsObjectsAsFaults = false
    request.predicate = NSPredicate(value: true)
    _ = try context.fetch(request)

    XCTAssertTrue(Car.findMaterializedObjects(in: context, where: NSPredicate(value: true)).count > 1)
    // with the previous fetch we have materialized only one Lamborghini (the expensive one)
    XCTAssertTrue(SportCar.findMaterializedObjects(in: context, where: NSPredicate(format: "\(#keyPath(Car.maker)) == %@", "Lamborghini")).count == 1)

    // de-materialize all objects
    context.refreshAllObjects()

    XCTAssertTrue(Car.findMaterializedObjects(in: context, where: NSPredicate(value: true)).isEmpty)
  }

  // MARK: Cache

  func testFetchCachedObject() throws {
    let context = container.viewContext

    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    do {
      let person = try Person.fetchCachedObject(in: context, forKey: "cached-person") { request in
        request.predicate = NSPredicate(format: "\(#keyPath(Person.firstName)) == %@ AND \(#keyPath(Person.lastName)) == %@", "Theodora", "Stone")
      }
      XCTAssertNotNil(person)
    }

    do {
      let person = try Person.fetchCachedObject(in: context, forKey: "cached-person") { request in
        request.predicate = NSPredicate(format: "\(#keyPath(Person.firstName)) == %@ AND \(#keyPath(Person.lastName)) == %@", "Theodora", "Stone")
      }
      XCTAssertNotNil(person)
    }

    do {
      let person = try Person.fetchCachedObject(in: context, forKey: "cached-person") { request in
        request.predicate = NSPredicate(format: "\(#keyPath(Person.firstName)) == %@ AND \(#keyPath(Person.lastName)) == %@", "TheodoraXYZ", "Stone")
      }
      // the cache is already there, the request is not evaluated
      XCTAssertNotNil(person)
      XCTAssertTrue(person?.firstName == "Theodora")
      XCTAssertTrue(person?.lastName == "Stone")
    }

    do {
      let car = try Car.fetchCachedObject(in: context, forKey: "cached-person") { request in
        request.predicate = NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")
      }
      // the cache was already there but for another entity, the request has been evaluated
      XCTAssertNotNil(car)
    }

    XCTAssertNotNil(context.cachedManagedObject(forKey: "cached-person"))

    let newContext = context.newBackgroundContext()
    newContext.performAndWait {
      XCTAssertNil(newContext.cachedManagedObject(forKey: "cached-person"))
    }

    do {
      _ = try newContext.performAndWait { context in
        _  = try Person.fetchCachedObject(in: context, forKey: "cached-person-2") { request in
          request.predicate = NSPredicate(value: true)
        }
      }

    } catch {
      XCTAssertTrue(error is CoreDataPlusError)
      if case CoreDataPlusError.fetchExpectingOneObjectFailed = error {
        // do nothing
      } else {
        XCTFail("Expected an error of type CoreDataPlusError.fetchExpectingOneObjectFailed")
      }
    }
  }

  // MARK: Batch Delete

  func testBatchDeleteObjectsWithResultTypeStatusOnly() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let result = try Car.batchDeleteObjects(with: context, resultType: .resultTypeStatusOnly) { $0.predicate = fiatPredicate }

    XCTAssertNotNil(result.status)
    XCTAssertTrue(result.status! == true)
    XCTAssertNil(result.changes)
  }

  func testBatchDeleteObjectsWithResultTypeCount() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let result = try Car.batchDeleteObjects(with: context, resultType: .resultTypeCount) { $0.predicate = fiatPredicate }

    XCTAssertNotNil(result.count)
    XCTAssertTrue(result.count! > 1)
  }

  func testBatchDeleteObjectsWithResultTypeObjectIDs() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let result = try Car.batchDeleteObjects(with: context, resultType: .resultTypeObjectIDs) { $0.predicate = fiatPredicate }

    XCTAssertNotNil(result.changes)
    XCTAssertTrue(result.changes!.keys.count == 1)
    let deletedValues = result.changes![NSDeletedObjectsKey]?.count ?? 0
    XCTAssertTrue(deletedValues > 1)

  }

  func testBatchDeleteObjectsWithResultTypeStatusOnlyThrowingAnException() throws {
    // Given
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

    // When, Then
    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    XCTAssertThrowsError(try Car.batchDeleteObjects(with: context, resultType: .resultTypeStatusOnly) { $0.predicate = fiatPredicate },
                         "There should be an exception because the context doesn't have PSC") { (error) in
                          switch error {
                          case CoreDataPlusError.persistentStoreCoordinatorNotFound(let errorContext):
                            let coreDataPlusError = error as! CoreDataPlusError
                            XCTAssertTrue(errorContext == context)
                            XCTAssertNil(coreDataPlusError.underlyingError)
                            XCTAssertNotNil(coreDataPlusError.localizedDescription)
                          default:
                            XCTFail("Unexepcted error type.")
                          }
    }


  }

  func testBatchDeleteAllEntities() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    // When, Then
    let result = try SportCar.batchDeleteObjects(with: context, resultType: .resultTypeStatusOnly)
    XCTAssertTrue(result.status!)

    context.reset()
    let sportCarCount = try ExpensiveSportCar.count(in: context)
    let expensiveSportCarCount = try ExpensiveSportCar.count(in: context)
    XCTAssertEqual(sportCarCount, 0)
    XCTAssertEqual(expensiveSportCarCount, 0)
  }

  func testBatchDeleteEntitiesExcludingSubEntities() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let preDeleteSportCarCount = try SportCar.count(in: context) // This count include all the subentities
    let preDeleteExpensiveSportCarCount = try ExpensiveSportCar.count(in: context)
    let expectedRemovedCarCount = preDeleteSportCarCount - preDeleteExpensiveSportCarCount
    let expectedRemainingSportCartCount = preDeleteSportCarCount - expectedRemovedCarCount

    // When, Then
    let result = try SportCar.batchDeleteObjects(with: context, resultType: .resultTypeStatusOnly) { request in
      request.includesSubentities = false
    }
    XCTAssertTrue(result.status!)

    context.reset()
    let sportCarCount = try SportCar.count(in: context)
    let expensiveSportCarCount = try ExpensiveSportCar.count(in: context)
    XCTAssertEqual(sportCarCount, expectedRemainingSportCartCount)
    XCTAssertEqual(expensiveSportCarCount, preDeleteExpensiveSportCarCount)
  }

  func testBatchDeleteObjectsMarkedForDeletion() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let kias = [9, 10, 11]
    let kiasCars = try Car.fetch(in: context, with: { $0.predicate = NSPredicate(format: "%K IN %@", #keyPath(Car.numberPlate), kias) })
    XCTAssertEqual(kiasCars.count, 3)
    kiasCars.forEach { car in
      car.markForDelayedDeletion()
    }
    try context.save()

    let result = try Car.batchDeleteObjectsMarkedForDeletion(with: context, olderThan: Date(), resultType: .resultTypeStatusOnly)
    XCTAssertTrue(result.status!)

    try context.save()
    let kiasCars2 = try Car.fetch(in: context, with: { $0.predicate = NSPredicate(format: "%K IN %@", #keyPath(Car.numberPlate), kias) })
    XCTAssertEqual(kiasCars2.count, 0)
  }

  // MARK: Batch Update

  func testBatchUpdateObjectsWithResultTypeStatusOnly() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let fcaPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FCA")

    let fiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
    let fcaCount = try Car.count(in: context) { $0.predicate = fcaPredicate }
    XCTAssertEqual(fcaCount, 0)

    let result = try Car.batchUpdateObjects(with: context) {
      $0.predicate = fiatPredicate
      $0.propertiesToUpdate = [#keyPath(Car.maker): "FCA"]
    }

    XCTAssertTrue(result.status!)

    context.reset()
    let newFiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
    XCTAssertEqual(newFiatCount, 0)
    let newFCACount = try Car.count(in: context) { $0.predicate = fcaPredicate }
    XCTAssertEqual(newFCACount, fiatCount)
  }

  func testBatchUpdateObjectsWithResultCountType() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let fcaPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FCA")

    let fiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
    let fcaCount = try Car.count(in: context) { $0.predicate = fcaPredicate }
    XCTAssertEqual(fcaCount, 0)

    let result = try Car.batchUpdateObjects(with: context) {
      $0.predicate = fiatPredicate
      $0.propertiesToUpdate = [#keyPath(Car.maker): "FCA"]
      $0.resultType = .updatedObjectsCountResultType
    }

    XCTAssertEqual(result.count!, fiatCount)

    context.reset()
    let newFiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
    XCTAssertEqual(newFiatCount, 0)
    let newFCACount = try Car.count(in: context) { $0.predicate = fcaPredicate }
    XCTAssertEqual(newFCACount, fiatCount)
  }

  func testBatchUpdateObjectsWithResultObjectIDsType() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let fcaPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FCA")

    let fiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
    let fcaCount = try Car.count(in: context) { $0.predicate = fcaPredicate }
    XCTAssertEqual(fcaCount, 0)

    let result = try Car.batchUpdateObjects(with: context) {
      $0.predicate = fiatPredicate
      $0.propertiesToUpdate = [#keyPath(Car.maker): "FCA"]
      $0.resultType = .updatedObjectIDsResultType
    }

    let changes = result.changes!
    XCTAssertEqual(changes.keys.count, 1)
    let ids = changes["updated"]!
    XCTAssertEqual(ids.count, 103)

    context.reset()
    let newFiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
    XCTAssertEqual(newFiatCount, 0)
    let newFCACount = try Car.count(in: context) { $0.predicate = fcaPredicate }
    XCTAssertEqual(newFCACount, fiatCount)
  }

}
