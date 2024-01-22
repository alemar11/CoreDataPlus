// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

final class NSFetchRequestResultUtilsTests: OnDiskTestCase {
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

    let person2 = context2.performAndWait { _ -> Person in
      let person = Person(context: context2)
      person.firstName = "firstName-testBatchFaultingWithDifferentContexts"
      person.lastName = "lastName-testBatchFaultingWithDifferentContexts"
      return person
    }

    let car2 = context2.performAndWait { _ -> Car in
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
      let persons = try Person.fetchObjects(in: context) { request in
        request.predicate = NSPredicate(format: "\(#keyPath(Person.lastName)) == %@", "Moreton")
      }
      XCTAssertTrue(persons.count == 2)
    }

    do {
      let persons = try Person.fetchObjects(in: context) { request in
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

  func testfetchUniqueObject() throws {
    let context = container.viewContext

    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    // This fetch will cause a fatal error (multiple objects will be fetched
    //  _ = try Person.fetchUniqueObject(in: context) {
    //    $0.predicate = NSPredicate(format: "\(#keyPath(Person.lastName)) == %@", "Moreton")
    //  }

    do {
      let person = try Person.fetchUniqueObject(in: context, where: NSPredicate(format: "\(#keyPath(Person.lastName)) == %@", "MoretonXYZ"))
      XCTAssertNil(person)
    }

    do {
      let person = try Person.fetchUniqueObject(in: context, where: NSPredicate(format: "\(#keyPath(Person.firstName)) == %@ AND \(#keyPath(Person.lastName)) == %@", "Theodora", "Stone"))
      XCTAssertNotNil(person)
    }

  }

  func testFindUniqueAfterPendingDelete() throws {
    let context = container.viewContext

    // 1. a Lamborghini with plate 304 is saved
    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    context.reset()
    let predicate = NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")
    try ExpensiveSportCar.delete(in: context, where: predicate)

    let car1 = try ExpensiveSportCar.fetchUniqueObject(in: context, where: predicate)
    XCTAssertNil(car1)

    // pending changes are lost
    context.reset()

    let car2 = try ExpensiveSportCar.fetchUniqueObject(in: context, where: predicate)
    XCTAssertNotNil(car2)
  }

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
    XCTAssertNoThrow(try Car.fetchObjects(in: context) { request in request.returnsObjectsAsFaults = false })
    // we add a new car to the context that has an already used numberPlate
    let car = Car(context: context)
    car.numberPlate = "304"
    car.maker = "fake-maker"
    car.model = "fake-model"

    // There are 2 cars (one saved, one in memory) with the same number plate 304, uniqueness is not guaranteed and a throws is expected

    // let predicate = NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")
    // The next fech is expected to print a fatal error
    //_ = try Car.findUniqueOrCreate(in: context, where: predicate, with: { _ in })

    // All the cars match the predicate, uniqueness is not guaranteed and a throws is expected
    // The next fech is expected to print a fatal error
    //_ = try Car.findUniqueOrCreate(in: context, where: NSPredicate(value: true), with: { _ in })
  }

  // MARK: - First

  func testfetchOneObject() throws {
    let context = container.viewContext

    context.performAndWait {
      context.fillWithSampleData()
      try! context.save()
    }

    let car1 = try Car.fetchOneObject(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304"))
    XCTAssertNotNil(car1)

    car1?.numberPlate = "304-edited"

    let car2 = try Car.fetchOneObject(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304"))
    XCTAssertNil(car2)

    // the fetch will be run only against saved values (number plate "304-edited" is a pending change)
    let car3 = try Car.fetchOneObject(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304"), includesPendingChanges: false)
    XCTAssertNotNil(car3)


    let newCar = Car(context: context)
    newCar.numberPlate = "304-fake"
    newCar.maker = "fake-maker"
    newCar.model = "fake-model"

    let car4 = try Car.fetchOneObject(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304-fake"))
    XCTAssertNotNil(car4)

    let car5 = try Car.fetchOneObject(in: context, where: NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304-fake"), includesPendingChanges: false)
    XCTAssertNil(car5)
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
    let result = try Car.batchDelete(using: context, predicate: fiatPredicate, resultType: .resultTypeStatusOnly)

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
    let result = try Car.batchDelete(using: context, predicate: fiatPredicate, resultType: .resultTypeCount)

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
    let result = try backgroundContext.performAndWait {
      try Car.batchDelete(using: $0, predicate: fiatPredicate, resultType: .resultTypeObjectIDs)
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

  func testBatchDeleteEntities() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    // When, Then
    let result = try SportCar.batchDelete(using: context, resultType: .resultTypeStatusOnly)
    XCTAssertTrue(result.status!)

    context.reset()
    let sportCarCount = try SportCar.count(in: context)
    let expensiveSportCarCount = try ExpensiveSportCar.count(in: context)
    XCTAssertEqual(sportCarCount, 0)
    XCTAssertEqual(expensiveSportCarCount, 0)
  }

  func testBatchDeleteEntitiesExcludingSubentities() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let preDeleteSportCarCount = try SportCar.count(in: context) // This count include all the subentities
    let preDeleteExpensiveSportCarCount = try ExpensiveSportCar.count(in: context)
    let expectedRemovedCarCount = preDeleteSportCarCount - preDeleteExpensiveSportCarCount
    let expectedRemainingSportCartCount = preDeleteSportCarCount - expectedRemovedCarCount

    // When, Then
    let result = try SportCar.batchDelete(using: context, includesSubentities: false, resultType: .resultTypeStatusOnly)
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
    let kiasCars = try Car.fetchObjects(in: context, with: { $0.predicate = NSPredicate(format: "%K IN %@", #keyPath(Car.numberPlate), kias) })
    XCTAssertEqual(kiasCars.count, 3)
    kiasCars.forEach { car in
      car.markForDelayedDeletion()
    }
    try context.save()

    let result = try Car.batchDeleteMarkedForDeletion(with: context, olderThan: Date(), resultType: .resultTypeStatusOnly)
    XCTAssertTrue(result.status!)

    try context.save()
    let kiasCars2 = try Car.fetchObjects(in: context, with: { $0.predicate = NSPredicate(format: "%K IN %@", #keyPath(Car.numberPlate), kias) })
    XCTAssertEqual(kiasCars2.count, 0)
  }

  // MARK: Batch Insert

  @available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  func testbatchInsertWithResultTypeStatusOnly() throws {
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

  @available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  func testbatchInsertWithResultTypeCount() throws {
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
    ]

    if #available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *) {
      // on iOS 14, throws an error (NSValidationErrorKey)
      XCTAssertThrowsError(try Car.batchInsert(using: context, resultType: .objectIDs, objects: objects))
    } else {
      // on iOS 13, it doesn't throw
      let result = try! Car.batchInsert(using: context, resultType: .objectIDs, objects: objects)

      // the first two objects have the same numberPlate
      XCTAssertEqual(result.inserts!.count, 2)
      XCTAssertEqual(result.changes?[NSInsertedObjectsKey]?.count, 2)

      let cars = try Car.fetchObjects(in: context)
      let models = cars.compactMap { $0.model }
      let makers = cars.compactMap { $0.maker }
      XCTAssertEqual(models, ["Panda", "Panda"])
      XCTAssertEqual(makers.count, 1)
    }
  }

  @available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  func testFailedbatchInsertWithResultObjectIDs() throws {
    // Given
    let context = container.viewContext

    let objects = [
      [#keyPath(Car.maker): "FIAT",
       "WRONG_REQUIRED_KEY": "1234",
       #keyPath(Car.model): "Panda"],
    ]

    XCTAssertThrowsError(try Car.batchInsert(using: context, resultType: .objectIDs, objects: objects))
  }

  func testbatchInsertWithDictionaryHandler() throws {
    // Given
    let context = container.viewContext

    let dictionaries: [[String: Any]] = [
      [#keyPath(Car.maker): "FIAT", #keyPath(Car.numberPlate): "1", #keyPath(Car.model): "Panda"],
      [#keyPath(Car.maker): "FIAT", #keyPath(Car.numberPlate): "2", #keyPath(Car.model): "Panda"],
      [#keyPath(Car.maker): "FIAT", #keyPath(Car.numberPlate): "3", #keyPath(Car.model): "Panda"],
      [#keyPath(Car.maker): "FIAT", #keyPath(Car.numberPlate): "4", #keyPath(Car.model): "Panda"],
      [#keyPath(Car.maker): "FIAT", #keyPath(Car.numberPlate): "5", #keyPath(Car.model): "Panda"],
    ]

    // Provide one dictionary at a time when the block is called.
    var index = 0
    let total = dictionaries.count
    let result = try Car.batchInsert(using: context, dictionaryHandler: { dictionary -> Bool in
      guard index < total else { return true }
      dictionary.addEntries(from: dictionaries[index])
      index += 1
      return false
    })

    let insertResult = try XCTUnwrap(result)
    XCTAssertEqual(index, total)
    XCTAssertTrue(insertResult.status!)
    XCTAssertEqual(insertResult.changes?[NSInsertedObjectsKey]?.count, nil) // wrong result type

    let count = try Car.count(in: context)
    XCTAssertEqual(count, total)
  }

  func testBatchInserWithObjectHandler() throws {
    // Given
    let context = container.viewContext

    let dictionaries: [[String: Any]] = [
      [#keyPath(Car.maker): "FIAT", #keyPath(Car.numberPlate): "1", #keyPath(Car.model): "Panda"],
      [#keyPath(Car.maker): "FIAT", #keyPath(Car.numberPlate): "2", #keyPath(Car.model): "Panda"],
      [#keyPath(Car.maker): "FIAT", #keyPath(Car.numberPlate): "3", #keyPath(Car.model): "Panda"],
      [#keyPath(Car.maker): "FIAT", #keyPath(Car.numberPlate): "4", #keyPath(Car.model): "Panda"],
      [#keyPath(Car.maker): "FIAT", #keyPath(Car.numberPlate): "5", #keyPath(Car.model): "Panda"],
    ]

    // Provide one object at a time when the block is called.
    var index = 0
    let total = dictionaries.count
    let result = try ExpensiveSportCar.batchInsert(using: context, managedObjectHandler: { car -> Bool in
      guard index < total else { return true }
      let dictionary = dictionaries[index]
      car.maker = dictionary[#keyPath(Car.maker)] as? String
      car.numberPlate = dictionary[#keyPath(Car.numberPlate)] as? String
      car.model = dictionary[#keyPath(Car.model)] as? String
      car.isLimitedEdition = Bool.random()
      index += 1
      return false
    })

    let insertResult = try XCTUnwrap(result)
    XCTAssertEqual(index, total)
    XCTAssertTrue(insertResult.status!)
    XCTAssertEqual(insertResult.changes?[NSInsertedObjectsKey]?.count, nil) // wrong result type

    let count = try Car.count(in: context)
    XCTAssertEqual(count, total)
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

    let result = try Car.batchUpdate(using: context) {
      $0.propertiesToUpdate = [#keyPath(Car.maker): "FCA"]
      $0.predicate = fiatPredicate
    }
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

    let result = try Car.batchUpdate(using: context) {
      $0.resultType = .updatedObjectsCountResultType
      $0.propertiesToUpdate = [#keyPath(Car.maker): "FCA"]
      $0.includesSubentities = true
      $0.predicate = fiatPredicate
    }
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

    let result = try Car.batchUpdate(using: context) {
      $0.resultType = .updatedObjectIDsResultType
      $0.propertiesToUpdate =  [#keyPath(Car.maker): "FCA"]
      $0.includesSubentities = true
      $0.predicate = fiatPredicate
    }

    let changes = result.updates!
    XCTAssertEqual(changes.count, 103)

    context.reset()
    let newFiatCount = try Car.count(in: context) { $0.predicate = fiatPredicate }
    XCTAssertEqual(newFiatCount, 0)
    let newFCACount = try Car.count(in: context) { $0.predicate = fcaPredicate }
    XCTAssertEqual(newFCACount, fiatCount)
    XCTAssertEqual(result.changes?[NSUpdatedObjectsKey]?.count, 103)
  }

  // TODO: investigate this behaviour (and open a FB)
//    func testFailedBatchUpdateWithResultObjectIDs() throws {
//      guard #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) else { return }
//
//      // Given
//      let context = container.viewContext
//      context.fillWithSampleData()
//      try context.save()
//
//      // numberPlate is not optional constraint for the Car Entity
//      // but in the backing .sqlite file it's actually just an optional string
//
//      XCTAssertThrowsError(try Car.batchUpdate(using: context) {
//        $0.resultType = .statusOnlyResultType
//        $0.propertiesToUpdate = [#keyPath(Car.numberPlate): NSExpression(forConstantValue: "SAME_VALE")]
//        $0.includesSubentities = true
//      })
//
//      let cars = try Car.fetchObjects(in: context)
//      XCTAssertEqual(cars.count, 125) // Nothing changed here
//
//      // While setting the same value for a constraint property throws an exception, setting nil doesn't throw anything but then
//      // all the updated objects are "broken"
//      let result2 = try Car.batchUpdate(using: context) {
//        $0.resultType = .statusOnlyResultType
//        $0.propertiesToUpdate = [#keyPath(Car.numberPlate): NSExpression(forConstantValue: nil)]
//        $0.includesSubentities = true
//      }
//      XCTAssertNotNil(result2.status, "There should be a status for a batch update with statusOnlyResultType option.")
//      XCTAssertTrue(result2.status!)
//
//      // Row (pk = 1) for entity 'Car' is missing mandatory text data for property 'numberPlate'
//      do {
//        let car = try Car.fetchOneObject(in: context, where: NSPredicate(value: true))
//        XCTAssertNotNil(car) // since the object is broken the fetch returns nil
//      }
//
//      try context.save()
//      try Car.delete(in: context)
//      try context.save()
//      let cars2 = try! Car.fetchObjects(in: context)
//      XCTAssertTrue(cars2.isEmpty) // All the cars aren't valid (for the CoreData model) anymore
//
//      do {
//        let car = try Car.fetchOneObject(in: context, where: NSPredicate(value: true))
//        XCTAssertNotNil(car) // since the object is broken the fetch returns nil
//      }
//
//      let count = try Car.count(in: context)
//      XCTAssertEqual(count, 125)
//
//      try Car.batchDelete(using: context, predicate: NSPredicate(format: "%K == NULL", #keyPath(Car.numberPlate)), resultType: .resultTypeCount)
//      let count2 = try Car.count(in: context)
//
//      XCTAssertEqual(count2, 0)
//      // https://developer.apple.com/library/archive/featuredarticles/CoreData_Batch_Guide/BatchUpdates/BatchUpdates.html
//    }

  // MARK: - Async Fetch

  func testAsyncFetch() throws {
    // BUG: Async fetches can't be tested with the ConcurrencyDebug enabled,
    // https://stackoverflow.com/questions/31728425/coredata-asynchronous-fetch-causes-concurrency-debugger-error
    try XCTSkipIf(UserDefaults.standard.integer(forKey: "com.apple.CoreData.ConcurrencyDebug") == 1)

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

    let token = try Car.fetchObjects(in: mainContext, with: { $0.predicate = NSPredicate(value: true) } ) { result in
      switch result {
      case .success(let cars):
        XCTAssertEqual(cars.count, 10_000)
        expectation1.fulfill()
      case .failure(let error):
        XCTFail(error.localizedDescription)
      }
    }

    XCTAssertNotNil(token.progress)

    // ⚠️ progress is not nil only if we create a progress and call the becomeCurrent method
    let currentToken = token.progress?.observe(\.completedUnitCount, options: [.old, .new]) { (progress, change) in
      if change.newValue == 10_000 {
        expectation2.fulfill()
      }
    }

    waitForExpectations(timeout: 30, handler: nil)
    currentProgress.resignCurrent()
    currentToken?.invalidate()
  }

//  @available(swift 5.5)
//  @available(iOS 15.0, iOSApplicationExtension 15.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, macOS 12, *)
//  func testAsyncFetchUsingSwiftConcurrency() async throws {
//    // In testAsyncFetch() the standard implementation doesn't pass the test only if we enable ConcurrencyDebug.
//    // The async/await version (that is, btw, used in WWDC 2021 videos on how to use continuations) always fails due to data races.
//    // https://stackoverflow.com/questions/31728425/coredata-asynchronous-fetch-causes-concurrency-debugger-error
//    try XCTSkipIf(UserDefaults.standard.integer(forKey: "com.apple.CoreData.ConcurrencyDebug") == 1)
//    let mainContext = container.viewContext
//
//    try await mainContext.perform {
//      (1...10_000).forEach {
//        let car = Car(context: mainContext)
//        car.numberPlate = "test\($0)"
//      }
//      try mainContext.save()
//    }
//    let results = try await Car.fetchObjects(in: mainContext) { $0.predicate = .true }
//    XCTAssertEqual(results.count, 10_000)
//  }

  // MARK: - Subquery

  func testInvestigationSubQuery() throws {
    // https://medium.com/@Czajnikowski/subquery-is-not-that-scary-3f95cb9e2d98
    let context = container.viewContext
    context.fillWithSampleData()

    let people = try Person.fetchObjects(in: context)
    let results = people.filter { person in
      let count = person.cars?.filter { object in
        let car = object as! Car
        return car.maker == "FIAT"
      }.count ?? 0
      //print("\t\(person.firstName) \(person.lastName) has \(count) FIAT cars")
      return count > 2
    }

    //let subquery = NSPredicate(format: "SUBQUERY(cars, $car, $car.maker == \"FIAT\").@count > 2")
    let subquery = NSPredicate(format: "SUBQUERY(%K, $car, $car.maker == \"FIAT\").@count > 2", #keyPath(Person.cars))
    let resultsUsingSubquery = try Person.fetchObjects(in: context) { $0.predicate = subquery }
    XCTAssertEqual(Set(results), Set(resultsUsingSubquery))
  }

  // MARK: - Group By

  func testInvestigationGroupBy() throws {
    // https://developer.apple.com/documentation/coredata/nsfetchrequest/1506191-propertiestogroupby
    // https://gist.github.com/pronebird/cca9777af004e9c91f9cd36c23cc821c
    // http://www.cimgf.com/2015/06/25/core-data-and-aggregate-fetches-in-swift/
    // https://medium.com/@cocoanetics/group-by-count-and-sum-in-coredata-63e575fb8bc8

    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    // SELECT maker, count(*) from cars GROUP BY maker

    // expression
    let makerExpression = NSExpression(forKeyPath: #keyPath(Car.maker))
    let expression = NSExpression(forFunction: "count:", arguments: [makerExpression])

    // describes a column to be returned from a fetch that may not appear directly as an attribute or relationship on an entity
    let countExpressionDescription = NSExpressionDescription()
    countExpressionDescription.name = "count" // alias
    countExpressionDescription.expression = expression
    countExpressionDescription.expressionResultType = .integer64AttributeType // in iOS 15 use resultType: NSAttributeDescription.AttributeType

    let request = Car.fetchRequest()
    request.returnsObjectsAsFaults = false
    request.propertiesToGroupBy = [#keyPath(Car.maker)]
    request.propertiesToFetch = [#keyPath(Car.maker), countExpressionDescription]
    request.resultType = .dictionaryResultType
    request.havingPredicate = NSPredicate(format: "%@ > 100", NSExpression(forVariable: "count"))
    let results = try context.fetch(request) as! [Dictionary<String, Any>]

    XCTAssertEqual(results.count, 1)
  }
}

