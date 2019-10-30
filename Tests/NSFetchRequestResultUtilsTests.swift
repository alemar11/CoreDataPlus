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

final class NSFetchRequestResultUtilsTests: CoreDataPlusInMemoryTestCase {
  
  // MARK: - Batch Faulting
  
  func testFaultAndMaterializeObjectWithoutNSManagedObjectContext() throws {
    let context = container.viewContext
    
    // Given
    let sportCar1 = SportCar(context: context)
    sportCar1.maker = "McLaren"
    sportCar1.model = "570GT"
    sportCar1.numberPlate = "203"
    try context.save()
    
    context.reset()
    XCTAssertTrue(sportCar1.isFault)
    XCTAssertNil(sportCar1.managedObjectContext)
    
    // When
    try [sportCar1].materializeFaultedObjects()
    // Then
    XCTAssertFalse(sportCar1.isFault)
  }
  
  func testFaultAndMaterializeTemporaryObject() throws {
    let context = container.viewContext
    
    // Given
    let sportCar1 = SportCar(context: context)
    sportCar1.maker = "McLaren"
    sportCar1.model = "570GT"
    sportCar1.numberPlate = "203"
    
    XCTAssertTrue(sportCar1.objectID.isTemporaryID)
    XCTAssertFalse(sportCar1.isFault)
    
    // When
    sportCar1.fault()
    // Then
    XCTAssertTrue(sportCar1.isFault)
    
    try [sportCar1].materializeFaultedObjects()
    XCTAssertFalse(sportCar1.isFault)
  }
  
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
    XCTAssertNoThrow(try cars.materializeFaultedObjects())
    
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
    XCTAssertNoThrow(try objects.materializeFaultedObjects())
    
    // no faults objects
    let request = Car.newFetchRequest()
    request.predicate = NSPredicate(value: true)
    request.returnsObjectsAsFaults = false
    request.fetchLimit = 2
    
    // When
    let cars = try context.fetch(request)
    let previousFaultsCount = cars.filter { $0.isFault }.count
    let previousNotFaultsCount = cars.filter { !$0.isFault }.count
    
    XCTAssertNoThrow(try cars.materializeFaultedObjects())
    
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
    XCTAssertNoThrow(try objects.materializeFaultedObjects())
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
    
    XCTAssertNoThrow(try person.cars?.materializeFaultedObjects())
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
      let nsError = error as NSError
      XCTAssertEqual(nsError.code, NSError.ErrorCode.fetchExpectingOnlyOneObjectFailed.rawValue, "Expected an error of type NSError.fetchExpectingOneObjectFailed")
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
    XCTAssertNil(result.deletes)
    XCTAssertEqual(result.changes?[NSDeletedObjectsKey]?.count, nil) // wrong result type
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
    XCTAssertEqual(result.changes?[NSDeletedObjectsKey]?.count, nil) // wrong result type
  }
  
  func testBatchDeleteObjectsWithResultTypeObjectIDs() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()
    
    
    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let fiatCount = try Car.count(in: context) { request in request.predicate = fiatPredicate }
    XCTAssertTrue(fiatCount > 0)
    
    let backgroundContext = context.newBackgroundContext()
    let result = try backgroundContext.performAndWait {
      try Car.batchDeleteObjects(with: $0, resultType: .resultTypeObjectIDs) { $0.predicate = fiatPredicate }
    }
    
    XCTAssertNotNil(result.deletes)
    let deletedValues = result.deletes?.count ?? 0
    XCTAssertTrue(deletedValues > 1)
    XCTAssertTrue(result.changes?[NSDeletedObjectsKey]?.count ?? 0 > 1)
    
    // the var `changes`  is usefull when used while merging changes
    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: result.changes!, into: [context])
    
    let fiatCountAfterMerge = try Car.count(in: context) { request in request.predicate = fiatPredicate }
    XCTAssertEqual(fiatCountAfterMerge, 0)
  }
  
  func testBatchDeleteObjectsWithResultTypeStatusOnlyThrowingAnException() throws {
    // Given
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    
    // When, Then
    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    XCTAssertThrowsError(try Car.batchDeleteObjects(with: context, resultType: .resultTypeStatusOnly) { $0.predicate = fiatPredicate },
                         "There should be an exception because the context doesn't have PSC") { (error) in
                          let nsError = error as NSError
                          if nsError.code == NSError.ErrorCode.persistentStoreCoordinatorNotFound.rawValue {
                            XCTAssertNil(nsError.underlyingError)
                            XCTAssertNotNil(nsError.localizedDescription)
                            XCTAssertEqual(nsError.debugMessage, "\(context.description) doesn't have a NSPersistentStoreCoordinator.")
                          } else {
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
  
  // MARK: Batch Insert
  
  func testBatchInsertObjectsWithResultTypeStatusOnly() throws {
    guard #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) else { return }
    
    // Given
    let context = container.viewContext
    
    let object = [#keyPath(Car.maker): "FIAT",
                  #keyPath(Car.numberPlate): "123",
                  #keyPath(Car.model): "Panda"]
    
    let result = try! Car.batchInsertObjects(with: context,
                                             resultType: .statusOnly,
                                             objects: [object])
    
    XCTAssertTrue(result.status!)
    XCTAssertEqual(result.changes?[NSInsertedObjectsKey]?.count, nil) // wrong result type
  }
  
  func testBatchInsertObjectsWithResultTypeCount() throws {
    guard #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) else { return }
    
    // Given
    let context = container.viewContext
    
    let object = [#keyPath(Car.maker): "FIAT",
                  #keyPath(Car.numberPlate): "123",
                  #keyPath(Car.model): "Panda"]
    
    let result = try! Car.batchInsertObjects(with: context,
                                             resultType: .count,
                                             objects: [object])
    
    XCTAssertEqual(result.count!, 1)
    XCTAssertEqual(result.changes?[NSInsertedObjectsKey]?.count, nil) // wrong result type
  }
  
  func testBatchInsertObjectsWithResultObjectIDs() throws {
    guard #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) else { return }
    
    // Given
    let context = container.viewContext
    let numberPlate = UUID().uuidString
    let numberPlate2 = UUID().uuidString
    
    let objects = [
      // This object will be inserted without a maker
      ["WRONG_KEY": "FIAT",
       #keyPath(Car.numberPlate): numberPlate,
       #keyPath(Car.model): "Panda"],
      
      // This object will not be inserted because the number plate has already been inserted
      [#keyPath(Car.maker): "FIAT",
       #keyPath(Car.numberPlate): numberPlate,
       #keyPath(Car.model): "Panda*"],
      
      [#keyPath(Car.maker): "FIAT",
       #keyPath(Car.numberPlate): numberPlate2,
       #keyPath(Car.model): "Panda"]
      ,
    ]
    
    let result = try! Car.batchInsertObjects(with: context,
                                             resultType: .objectIDs,
                                             objects: objects)
    
    // the first two objects have the same numberPlate
    XCTAssertEqual(result.inserts!.count, 2)
    XCTAssertEqual(result.changes?[NSInsertedObjectsKey]?.count, 2)
    
    let cars = try Car.fetch(in: context)
    let models = cars.compactMap { $0.model }
    let makers = cars.compactMap { $0.maker }
    XCTAssertEqual(models, ["Panda", "Panda"])
    XCTAssertEqual(makers.count, 1)
  }
  
  func testFailedBatchInsertObjectsWithResultObjectIDs() throws {
    guard #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) else { return }
    
    // Given
    let context = container.viewContext
    
    let objects = [
      [#keyPath(Car.maker): "FIAT",
       "WRONG_REQUIRED_KEY": "1234",
       #keyPath(Car.model): "Panda"],
    ]
    
    XCTAssertThrowsError(try Car.batchInsertObjects(with: context, resultType: .objectIDs, objects: objects))
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
    
    let result = try Car.batchUpdateObjects(with: context, propertiesToUpdate: [#keyPath(Car.maker): "FCA"], predicate: fiatPredicate)
    XCTAssertTrue(result.status!)
    
    context.reset()
    let newFiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
    XCTAssertEqual(newFiatCount, 0)
    let newFCACount = try Car.count(in: context) { $0.predicate = fcaPredicate }
    XCTAssertEqual(newFCACount, fiatCount)
    XCTAssertEqual(result.changes?[NSUpdatedObjectsKey]?.count, nil) // wrong result type
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
    
    let result = try Car.batchUpdateObjects(with: context, resultType: .updatedObjectsCountResultType, propertiesToUpdate: [#keyPath(Car.maker): "FCA"], includesSubentities: true, predicate: fiatPredicate)
    XCTAssertEqual(result.count!, fiatCount)
    
    context.reset()
    let newFiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
    XCTAssertEqual(newFiatCount, 0)
    let newFCACount = try Car.count(in: context) { $0.predicate = fcaPredicate }
    XCTAssertEqual(newFCACount, fiatCount)
    XCTAssertEqual(result.changes?[NSUpdatedObjectsKey]?.count, nil) // wrong result type
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
    
    let result = try Car.batchUpdateObjects(with: context, resultType: .updatedObjectIDsResultType, propertiesToUpdate: [#keyPath(Car.maker): "FCA"], includesSubentities: true, predicate: fiatPredicate)
    
    let changes = result.updates!
    XCTAssertEqual(changes.count, 103)
    
    context.reset()
    let newFiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
    XCTAssertEqual(newFiatCount, 0)
    let newFCACount = try Car.count(in: context) { $0.predicate = fcaPredicate }
    XCTAssertEqual(newFCACount, fiatCount)
    XCTAssertEqual(result.changes?[NSUpdatedObjectsKey]?.count, 103)
  }
  
  // TODO: investigate or delete this test
  //  func testFailedBatchUpdateObjectsWithResultObjectIDs() throws {
  //    guard #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) else { return }
  //
  //    // Given
  //     let context = container.viewContext
  //       context.fillWithSampleData()
  //       try context.save()
  //
  //
  ////    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
  ////      let fcaPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FCA")
  ////       let fiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
  ////       let fcaCount = try Car.count(in: context) { $0.predicate = fcaPredicate }
  ////       XCTAssertEqual(fcaCount, 0)
  //
  //   let x = try Car.batchUpdateObjects(with: context, resultType: .statusOnlyResultType, propertiesToUpdate: [#keyPath(Car.numberPlate): NSExpression(forConstantValue: nil)], includesSubentities: true)
  //    print(x.status)
  //   let cars = try! Car.fetch(in: context)
  //    cars.forEach { (car) in
  //      print(car.numberPlate)
  //    }
  //// https://developer.apple.com/library/archive/featuredarticles/CoreData_Batch_Guide/BatchUpdates/BatchUpdates.html
  //  }
  
  // MARK: - Async Fetch
  
  func testAsyncFetch() throws {
    // BUG: Async fetches can't be tested with the ConcurrencyDebug enabled,
    // https://stackoverflow.com/questions/31728425/coredata-asynchronous-fetch-causes-concurrency-debugger-error
    guard UserDefaults.standard.integer(forKey: "com.apple.CoreData.ConcurrencyDebug") != 1 else {
      print("Test skipped.")
      return
    }
    
    let expectation1 = self.expectation(description: "\(#function)\(#line)")
    let expectation2 = self.expectation(description: "\(#function)\(#line)")
    let mainContext = container.viewContext
    
    (1...10_000).forEach { (i) in
      let car = Car(context: mainContext)
      car.numberPlate = "test\(i)"
    }
    
    try mainContext.save()
    let currentProgress = Progress(totalUnitCount: 1)
    currentProgress.becomeCurrent(withPendingUnitCount: 1)
    
    let token = try Car.fetchAsync(in: mainContext, with: { request in
      request.predicate = NSPredicate(value: true)
    }) { result in
      switch result {
      case .success(let cars):
        XCTAssertEqual(cars.count, 10_000)
        expectation1.fulfill()
      case .failure(let error):
        XCTFail(error.localizedDescription)
      }
    }

    XCTAssertNotNil(token.progress)
    
    // progress is not nil only if we create a progress and call the becomeCurrent method
    let currentToken = token.progress?.observe(\.completedUnitCount, options: [.old, .new]) { (progress, change) in
      print(change)
      if change.newValue == 10_000 {
        expectation2.fulfill()
      }
    }
    
    waitForExpectations(timeout: 30, handler: nil)
    currentProgress.resignCurrent()
    currentToken?.invalidate()
  }
  
  // MARK: - Thread Safe Access
  
  func testManagedObjectThreadSafeAccess() {
    let context = container.viewContext.newBackgroundContext()
    let car = context.performAndWait { return Car(context: $0) }
    car.safeAccess { XCTAssertEqual($0.managedObjectContext, context) }
  }
  
  func testFetchedResultsControllerThreadSafeAccess() throws {
    let context = container.viewContext.newBackgroundContext()
    try context.performAndWait { _ in
      context.fillWithSampleData()
      try context.save()
    }
    
    let request = Car.newFetchRequest()
    request.sortDescriptors = [NSSortDescriptor(key: #keyPath(Car.numberPlate), ascending: true)]
    let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    try controller.performFetch()
    
    let cars = controller.fetchedObjects!
    let firstCar = controller.object(at: IndexPath(item: 0, section: 0)) as Car
    
    firstCar.safeAccess {
      XCTAssertEqual(controller.managedObjectContext, $0.managedObjectContext)
    }
    
    for car in cars {
      _ = car.safeAccess { car -> String in
        XCTAssertEqual(controller.managedObjectContext, context)
        return car.numberPlate
      }
    }
  }
  
  // MARK: - Group By
  
  // TODO: Wip
  // TODO: read documentation on how to use processPendingChanges and UndoManager
  
  //  func testGroupBy() throws {
  //    // https://developer.apple.com/documentation/coredata/nsfetchrequest/1506191-propertiestogroupby
  //    // https://gist.github.com/pronebird/cca9777af004e9c91f9cd36c23cc821c
  //    // http://www.cimgf.com/2015/06/25/core-data-and-aggregate-fetches-in-swift/
  //    // https://medium.com/@cocoanetics/group-by-count-and-sum-in-coredata-63e575fb8bc8
  //    // Given
  //    let context = container.viewContext
  //    context.fillWithSampleData()
  //    try context.save()
  //    let request = Car.fetchRequest()
  //
  //    let nameExpr = NSExpression(forKeyPath: #keyPath(Car.maker))
  //    let countVariableExpr = NSExpression(forVariable: "count")
  //
  //    let countExpr = NSExpressionDescription()
  //    countExpr.name = "count" // alias
  //    countExpr.expression = NSExpression(forFunction: "count:", arguments: [nameExpr])
  //    countExpr.expressionResultType = .integer64AttributeType
  //
  //    request.returnsObjectsAsFaults = false
  //    request.propertiesToGroupBy = ["maker"]
  //    request.propertiesToFetch = ["maker", countExpr]
  //    request.resultType = .dictionaryResultType
  //    request.havingPredicate = NSPredicate(format: "%@ > 100", countVariableExpr)
  //    let results = try context.fetch(request) as! [Dictionary<String, Any>]
  //
  //    print(results)
  //  }
  //
  //  // MARK: - Undo
  //
  //  // TODO: the undo manager is needed for undo, redo and rollback
  //  // https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext
  //  // https://stackoverflow.com/questions/10745027/undo-core-data-managed-object
  //  /**
  //   undo: sends an undo message to the NSUndoManager
  //   redo: sends a redo message to the NSUndoManager
  //   rollback: sends undo messages to the NSUndoManager until there is nothing left to undo
  //
  //
  //   undo reverses a single change, rollback reverses all changes up to the previous save.
  //   To enable undo support on iOS you have to set the context's NSUndoManager.
  //   NOTE: https://forums.developer.apple.com/thread/74038 it appears the undoManager is nil by default on macos too.
  //   **/
  //
  //  func testUndo() throws {
  //    do {
  //      let context = container.newBackgroundContext()
  //      context.undoManager = UndoManager() // with the undo manager we can use the undo function
  //      context.performAndWait { context in
  //        context.fillWithSampleData()
  //        context.undo()
  //        XCTAssertTrue(context.insertedObjects.isEmpty)
  //        context.redo()
  //        XCTAssertFalse(context.insertedObjects.isEmpty)
  //      }
  //    }
  //    do {
  //      let context = container.newBackgroundContext()
  //      context.performAndWait { context in
  //        context.fillWithSampleData()
  //        context.undo()
  //        XCTAssertFalse(context.insertedObjects.isEmpty)
  //      }
  //    }
  //  }
}

