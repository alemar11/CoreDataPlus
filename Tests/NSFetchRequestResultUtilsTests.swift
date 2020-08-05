// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

final class NSFetchRequestResultUtilsTests: CoreDataPlusOnDiskTestCase {

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
    try [sportCar1].materializeFaults()
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

    try [sportCar1].materializeFaults()
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
    XCTAssertNoThrow(try cars.materializeFaults())

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
    XCTAssertNoThrow(try objects.materializeFaults())

    // no faults objects
    let request = Car.newFetchRequest()
    request.predicate = NSPredicate(value: true)
    request.returnsObjectsAsFaults = false
    request.fetchLimit = 2

    // When
    let cars = try context.fetch(request)
    let previousFaultsCount = cars.filter { $0.isFault }.count
    let previousNotFaultsCount = cars.filter { !$0.isFault }.count

    XCTAssertNoThrow(try cars.materializeFaults())

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

    let person2 = context2.performAndWaitResult { context -> Person in
      let person = Person(context: context2)
      person.firstName = "firstName-testBatchFaultingWithDifferentContexts"
      person.lastName = "lastName-testBatchFaultingWithDifferentContexts"
      return person
    }

    let car2 = context2.performAndWaitResult { context -> Car in
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
    XCTAssertNoThrow(try objects.materializeFaults())
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
    let previousFaultsCount = person._cars?.filter { $0.isFault }.count

    XCTAssertNoThrow(try person._cars?.materializeFaults())
    let currentNotFaultsCount = person._cars?.filter { !$0.isFault }.count
    let currentFaultsCount = person._cars?.filter { $0.isFault }.count
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

  func testfetchUnique() throws {
    let context = container.viewContext

    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    do {
      _ = try Person.fetchUnique(in: context) { request in
        request.predicate = NSPredicate(format: "\(#keyPath(Person.lastName)) == %@", "Moreton")
      }
      XCTFail("This fetch should fail because the result should have more than 1 resul.")
    } catch {
      XCTAssertNotNil(error)
    }

    do {
      let person = try Person.fetchUnique(in: context) { request in
        request.predicate = NSPredicate(format: "\(#keyPath(Person.lastName)) == %@", "MoretonXYZ")
      }
      XCTAssertNil(person)
    }

    do {
      let person = try Person.fetchUnique(in: context) { request in
        request.predicate = NSPredicate(format: "\(#keyPath(Person.firstName)) == %@ AND \(#keyPath(Person.lastName)) == %@", "Theodora", "Stone")
      }
      XCTAssertNotNil(person)
    }

  }

//  func testFindUniqueOrCreateWhenUniquenessIsViolated() throws {
//    let context = container.viewContext
//
//    // 1. a Lamborghini with plate 304 is saved
//    context.performAndWait {
//      context.fillWithSampleData()
//      try! context.save()
//    }
//
//    context.reset()
//
//    // 2. another Lamborghini with plate 304 is created
//    let fakeExpensiveSportCar5 = ExpensiveSportCar(context: context)
//    fakeExpensiveSportCar5.maker = "Lamborghini"
//    fakeExpensiveSportCar5.model = "Aventador LP750-4"
//    fakeExpensiveSportCar5.numberPlate = "304"
//    fakeExpensiveSportCar5.isLimitedEdition = false
//
//    // 3. when we search for an unique 304 Lamborhing, an exception should be thrown
//    XCTAssertThrowsError(try Car.findUniqueOrCreate(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")) { _ in XCTFail("A new car shouldn't be created.")
//    })
//  }

  func testFindUniqueOrCreate() throws {
    let context = container.viewContext
    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    // Case 1: existing object
    do {
      let car = try Car.findUniqueOrCreate(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")) { _ in
        XCTFail("A new car shouldn't be created.")
      }

      XCTAssertNotNil(car)
      XCTAssertTrue(car.maker == "Lamborghini")
    }

    // Case 2: new object
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

    // Case 3: new object (supposed to be unique) added in the context before the fetch

    context.reset()

    // first we materialiaze all cars
    XCTAssertNoThrow(try Car.fetch(in: context) { request in request.returnsObjectsAsFaults = false })
    // we add a new car to the context that has an already used numberPlate
    let car = Car(context: context)
    car.numberPlate = "304"
    car.maker = "fake-maker"
    car.model = "fake-model"

    let predicate = NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")
    // There are 2 cars (one saved, one in memory) with the same number plate 304, uniqueness is not guaranteed and a throws is expected
    XCTAssertThrowsError(try Car.findUniqueOrCreate(in: context, where: predicate, with: { _ in }))

    // All the cars match the predicate, uniqueness is not guaranteed and a throws is expected
    XCTAssertThrowsError(try Car.findUniqueOrCreate(in: context, where: NSPredicate(value: true), with: { _ in }))
  }

  // MARK: - First

  func testFindOneOrCreate() throws {
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
      XCTAssertFalse(car.objectID.isTemporaryID)
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
      XCTAssertTrue(car.objectID.isTemporaryID)
      context.delete(car)
    }

    /// new object added in the context before the fetch

    // first we materialiaze all cars
    XCTAssertNoThrow(try Car.fetch(in: context) { request in request.returnsObjectsAsFaults = false })
    let car = Car(context: context)
    car.numberPlate = "304"
    car.maker = "fake-maker"
    car.model = "fake-model"

    /// At this point we have two car with the same 304 number plate in the context, so the method will fetch one of these two.
    do {
      let car = try Car.findOneOrCreate(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304"), with: { car in
        XCTAssertNil(car.numberPlate)
      })
      XCTAssertNotNil(car)
      if car.objectID.isTemporaryID {
        XCTAssertEqual(car.maker, "fake-maker")
      } else {
        XCTAssertEqual(car.maker, "Lamborghini")
      }

      let car304 = context.registeredObjects.filter{ $0 is Car } as! Set<Car>

      XCTAssertTrue(car304.filter { $0.numberPlate == "304" }.count == 2)
    }

    context.refreshAllObjects()
    context.reset()

    /// multiple objects, the first one matching the condition is returned
    do {
      let car = try Car.findOneOrCreate(in: context, where: NSPredicate(value: true), with: { car in
        XCTAssertNotNil(car.numberPlate)
      })
      XCTAssertNotNil(car)
      XCTAssertFalse(car.objectID.isTemporaryID)
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

    XCTAssertNotNil(Car.materializedObject(in: context, where: NSPredicate(value: true)))

    let predicate = NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")
    XCTAssertNotNil(Car.materializedObject(in: context, where: predicate))

    // de-materialize all objects
    context.refreshAllObjects()

    XCTAssertNil(Car.materializedObject(in: context, where: predicate))
  }

  // MARK: Materialized Object

  func testfindMaterializedObjects() throws {
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

    XCTAssertTrue(Car.materializedObjects(in: context, where: NSPredicate(value: true)).count > 1)
    // with the previous fetch we have materialized only one Lamborghini (the expensive one)
    XCTAssertTrue(SportCar.materializedObjects(in: context, where: NSPredicate(format: "\(#keyPath(Car.maker)) == %@", "Lamborghini")).count == 1)

    // de-materialize all objects
    context.refreshAllObjects()

    XCTAssertTrue(Car.materializedObjects(in: context, where: NSPredicate(value: true)).isEmpty)
  }

  // MARK: Batch Delete

  func testbatchDeleteWithResultTypeStatusOnly() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let result = try Car.batchDelete(using: context, resultType: .resultTypeStatusOnly) { $0.predicate = fiatPredicate }

    XCTAssertNotNil(result.status)
    XCTAssertTrue(result.status! == true)
    XCTAssertNil(result.deletes)
    XCTAssertEqual(result.changes?[NSDeletedObjectsKey]?.count, nil) // wrong result type
  }

  func testbatchDeleteWithResultTypeCount() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let result = try Car.batchDelete(using: context, resultType: .resultTypeCount) { $0.predicate = fiatPredicate }

    XCTAssertNotNil(result.count)
    XCTAssertTrue(result.count! > 1)
    XCTAssertEqual(result.changes?[NSDeletedObjectsKey]?.count, nil) // wrong result type
  }

  func testbatchDeleteWithResultTypeObjectIDs() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()


    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let fiatCount = try Car.count(in: context) { request in request.predicate = fiatPredicate }
    XCTAssertTrue(fiatCount > 0)

    let backgroundContext = context.newBackgroundContext()
    let result = try backgroundContext.performAndWaitResult {
      try Car.batchDelete(using: $0, resultType: .resultTypeObjectIDs) { $0.predicate = fiatPredicate }
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

  func testbatchDeleteWithResultTypeStatusOnlyThrowingAnException() throws {
    // Given
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

    // When, Then
    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    XCTAssertThrowsError(try Car.batchDelete(using: context, resultType: .resultTypeStatusOnly) { $0.predicate = fiatPredicate },
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

  func testBatchdeleteEntities() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    // When, Then
    let result = try SportCar.batchDelete(using: context, resultType: .resultTypeStatusOnly)
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
    let result = try SportCar.batchDelete(using: context, resultType: .resultTypeStatusOnly) { request in
      request.includesSubentities = false
    }
    XCTAssertTrue(result.status!)

    context.reset()
    let sportCarCount = try SportCar.count(in: context)
    let expensiveSportCarCount = try ExpensiveSportCar.count(in: context)
    XCTAssertEqual(sportCarCount, expectedRemainingSportCartCount)
    XCTAssertEqual(expensiveSportCarCount, preDeleteExpensiveSportCarCount)
  }

  func testbatchDeleteMarkedForDeletion() throws {
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

    let result = try Car.batchDeleteMarkedForDeletion(with: context, olderThan: Date(), resultType: .resultTypeStatusOnly)
    XCTAssertTrue(result.status!)

    try context.save()
    let kiasCars2 = try Car.fetch(in: context, with: { $0.predicate = NSPredicate(format: "%K IN %@", #keyPath(Car.numberPlate), kias) })
    XCTAssertEqual(kiasCars2.count, 0)
  }

  // MARK: Batch Insert

  func testbatchInsertWithResultTypeStatusOnly() throws {
    guard #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) else { return }

    // Given
    let context = container.viewContext

    let object = [#keyPath(Car.maker): "FIAT",
                  #keyPath(Car.numberPlate): "123",
                  #keyPath(Car.model): "Panda"]

    let result = try! Car.batchInsert(using: context,
                                             resultType: .statusOnly,
                                             objects: [object])

    XCTAssertTrue(result.status!)
    XCTAssertEqual(result.changes?[NSInsertedObjectsKey]?.count, nil) // wrong result type
  }

  func testbatchInsertWithResultTypeCount() throws {
    guard #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) else { return }

    // Given
    let context = container.viewContext

    let object = [#keyPath(Car.maker): "FIAT",
                  #keyPath(Car.numberPlate): "123",
                  #keyPath(Car.model): "Panda"]

    let result = try! Car.batchInsert(using: context,
                                             resultType: .count,
                                             objects: [object])

    XCTAssertEqual(result.count!, 1)
    XCTAssertEqual(result.changes?[NSInsertedObjectsKey]?.count, nil) // wrong result type
  }

  func testbatchInsertWithResultObjectIDs() throws {
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

    let result = try! Car.batchInsert(using: context,
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

  func testFailedbatchInsertWithResultObjectIDs() throws {
    guard #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) else { return }

    // Given
    let context = container.viewContext

    let objects = [
      [#keyPath(Car.maker): "FIAT",
       "WRONG_REQUIRED_KEY": "1234",
       #keyPath(Car.model): "Panda"],
    ]

    XCTAssertThrowsError(try Car.batchInsert(using: context, resultType: .objectIDs, objects: objects))
  }

  // MARK: Batch Update

  func testbatchUpdateWithResultTypeStatusOnly() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let fcaPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FCA")

    let fiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
    let fcaCount = try Car.count(in: context) { $0.predicate = fcaPredicate }
    XCTAssertEqual(fcaCount, 0)

    let result = try Car.batchUpdate(using: context, propertiesToUpdate: [#keyPath(Car.maker): "FCA"], predicate: fiatPredicate)
    XCTAssertTrue(result.status!)

    context.reset()
    let newFiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
    XCTAssertEqual(newFiatCount, 0)
    let newFCACount = try Car.count(in: context) { $0.predicate = fcaPredicate }
    XCTAssertEqual(newFCACount, fiatCount)
    XCTAssertEqual(result.changes?[NSUpdatedObjectsKey]?.count, nil) // wrong result type
  }

  func testbatchUpdateWithResultCountType() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let fcaPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FCA")

    let fiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
    let fcaCount = try Car.count(in: context) { $0.predicate = fcaPredicate }
    XCTAssertEqual(fcaCount, 0)

    let result = try Car.batchUpdate(using: context, resultType: .updatedObjectsCountResultType, propertiesToUpdate: [#keyPath(Car.maker): "FCA"], includesSubentities: true, predicate: fiatPredicate)
    XCTAssertEqual(result.count!, fiatCount)

    context.reset()
    let newFiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
    XCTAssertEqual(newFiatCount, 0)
    let newFCACount = try Car.count(in: context) { $0.predicate = fcaPredicate }
    XCTAssertEqual(newFCACount, fiatCount)
    XCTAssertEqual(result.changes?[NSUpdatedObjectsKey]?.count, nil) // wrong result type
  }

  func testbatchUpdateWithResultObjectIDsType() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let fiatPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
    let fcaPredicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FCA")

    let fiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
    let fcaCount = try Car.count(in: context) { $0.predicate = fcaPredicate }
    XCTAssertEqual(fcaCount, 0)

    let result = try Car.batchUpdate(using: context,
                                     resultType: .updatedObjectIDsResultType,
                                     propertiesToUpdate: [#keyPath(Car.maker): "FCA"],
                                     includesSubentities: true,
                                     predicate: fiatPredicate)

    let changes = result.updates!
    XCTAssertEqual(changes.count, 103)

    context.reset()
    let newFiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
    XCTAssertEqual(newFiatCount, 0)
    let newFCACount = try Car.count(in: context) { $0.predicate = fcaPredicate }
    XCTAssertEqual(newFCACount, fiatCount)
    XCTAssertEqual(result.changes?[NSUpdatedObjectsKey]?.count, 103)
  }

  // TODO: investigation
//  func testFailedbatchUpdateWithResultObjectIDs() throws {
//    guard #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) else { return }
//
//    // Given
//    let context = container.viewContext
//    context.fillWithSampleData()
//    try context.save()
//
//    // numberPlate is not optional and a constraint for the Car Entity in CoreData
//    // but in the backing .sqlite file it's actually just an optional string
//
//    XCTAssertThrowsError(try Car.batchUpdate(using: context,
//                                             resultType: .statusOnlyResultType,
//                                             propertiesToUpdate: [#keyPath(Car.numberPlate): NSExpression(forConstantValue: "SAME_VALE")],
//                                             includesSubentities: true)
//    )
//
//    let cars = try! Car.fetch(in: context)
//    XCTAssertEqual(cars.count, 125) // Nothing changed here
//
//
//    // TODO: investigate this behaviour
//    // While setting the same value for a constrainingg property throws an exception, setting nil doesn't throw anything but then
//    // all the updated objects are "broken"
//    let result2 = try Car.batchUpdate(using: context,
//                                      resultType: .statusOnlyResultType,
//                                      propertiesToUpdate: [#keyPath(Car.numberPlate): NSExpression(forConstantValue: nil)],
//                                      includesSubentities: true)
//    XCTAssertNotNil(result2.status, "There should be a status for a batch update with statusOnlyResultType option.")
//    XCTAssertTrue(result2.status!)
//
//    let car = try Car.findOneOrFetch(in: context, where: NSPredicate(value: true))
//
//    try context.save()
//    try Car.delete(in: context)
//    try context.save()
//    let cars2 = try! Car.fetch(in: context)
//    XCTAssertTrue(cars2.isEmpty) // All the cars aren't valid (for the CoreData model) anymore
//    let _car = try Car.findOneOrFetch(in: context, where: NSPredicate(value: true))
//
//    let count = try Car.count(in: context)
//    XCTAssertEqual(count, 125)
//
//    try Car.batchDelete(using: context, resultType: .resultTypeCount) { $0.predicate = NSPredicate(format: "%K == NULL", #keyPath(Car.numberPlate))}
//    let count2 = try Car.count(in: context)
//
//    XCTAssertEqual(count2, 0)
//    // https://developer.apple.com/library/archive/featuredarticles/CoreData_Batch_Guide/BatchUpdates/BatchUpdates.html
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
    let car = context.performAndWaitResult { return Car(context: $0) }
    car.safeAccess { XCTAssertEqual($0.managedObjectContext, context) }
  }

  func testFetchedResultsControllerThreadSafeAccess() throws {
    let context = container.viewContext.newBackgroundContext()
    try context.performAndWaitResult { _ in
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

