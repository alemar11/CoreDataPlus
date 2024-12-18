// CoreDataPlus

import CoreData
import XCTest

@testable import CoreDataPlus

final class NSManagedObjectUtils_Tests: InMemoryTestCase {

  func test_Refresh() {
    // Given
    let context = container.viewContext

    do {
      // When
      let person = Person(context: context)
      context.performAndWait {
        person.firstName = "Myname"
        person.lastName = "MyLastName"
        try! context.save()
      }
      // Then
      person.firstName = "NewName"
      person.refresh()
      XCTAssertTrue(!person.isFault)
    }

    do {
      // When
      let person = Person(context: context)
      context.performAndWait {
        person.firstName = "Myname2"
        person.lastName = "MyLastName2"
        try! context.save()
      }
      // Then
      person.firstName = "NewName2"
      person.refresh(mergeChanges: false)
      XCTAssertTrue(person.isFault)
      XCTAssertTrue(person.firstName == "Myname2")
    }

  }

  func test_ChangedAndCommittedValue() throws {
    let context = container.viewContext

    let carNumberPlate = #keyPath(Car.numberPlate)
    let carModel = #keyPath(Car.model)

    // Given
    // https://cocoacasts.com/how-to-observe-a-managed-object-context/
    // http://mentalfaculty.tumblr.com/post/65682908577/how-does-core-data-save
    do {
      // When
      let car = Car(context: context)
      let person = Person(context: context)
      XCTAssertNil(car.changedValue(forKey: carNumberPlate))
      XCTAssertNil(car.changedValue(forKey: carModel))
      car.model = "MyModel"
      car.numberPlate = "123456"
      person.firstName = "Alessandro"
      person.lastName = "Marzoli"
      car.owner = person
      // Then
      XCTAssertNotNil(car.changedValue(forKey: carNumberPlate) as? String)
      XCTAssertNotNil(car.changedValue(forKey: carModel) as? String)
      XCTAssertEqual(car.changedValue(forKey: carNumberPlate) as! String, "123456")
      XCTAssertNil(car.committedValue(forKey: carNumberPlate))
      XCTAssertNil(car.committedValue(forKey: carModel))

      // When
      try context.save()
      XCTAssertNotNil(car.committedValue(forKey: carNumberPlate))
      XCTAssertNotNil(car.committedValue(forKey: carModel))
      XCTAssertEqual(car.committedValue(forKey: carNumberPlate) as! String, "123456")
      XCTAssertEqual(car.committedValue(forKey: carModel) as! String, "MyModel")
      // Then
      XCTAssertNil(car.changedValue(forKey: carNumberPlate))
      XCTAssertNil(car.changedValue(forKey: carModel))

      // When
      car.numberPlate = "101"
      // Then
      XCTAssertEqual(car.changedValue(forKey: carNumberPlate) as! String, "101")
      XCTAssertNotNil(car.committedValue(forKey: carNumberPlate))

      // When
      car.numberPlate = "202"
      // Then
      XCTAssertNotNil(car.changedValue(forKey: carNumberPlate))
      XCTAssertNotNil(car.committedValue(forKey: carNumberPlate))
      XCTAssertEqual(car.changedValue(forKey: carNumberPlate) as! String, "202")
      XCTAssertEqual(car.committedValue(forKey: carNumberPlate) as! String, "123456")

      // When
      try context.save()
      // Then
      XCTAssertNil(car.changedValue(forKey: carNumberPlate))
      XCTAssertNotNil(car.committedValue(forKey: carNumberPlate))

      let request = NSFetchRequest<Car>(entityName: "Car")
      request.predicate = NSPredicate(
        format: "\(#keyPath(Car.model)) == %@ AND \(#keyPath(Car.numberPlate)) == %@", "MyModel", "202")
      request.fetchBatchSize = 1
      if let fetchedCar = try! context.fetch(request).first {
        XCTAssertNotNil(car.committedValue(forKey: carNumberPlate))
        XCTAssertNil(car.changedValue(forKey: carNumberPlate))
        fetchedCar.numberPlate = "999"
        XCTAssertNil(car.changedValue(forKey: carModel))
        XCTAssertNotNil(car.changedValue(forKey: carNumberPlate))
        XCTAssertNotNil(car.committedValue(forKey: carNumberPlate))
        XCTAssertNotNil(car.committedValue(forKey: carModel))
        XCTAssertEqual(car.committedValue(forKey: carNumberPlate) as! String, "202")
      } else {
        XCTFail("No cars found for request: \(request.description)")
      }
    }
  }

  func test_FaultAndMaterialize() throws {
    let context = container.viewContext

    // Given
    let sportCar1 = SportCar(context: context)
    sportCar1.maker = "McLaren"
    sportCar1.model = "570GT"
    sportCar1.numberPlate = "203"
    XCTAssertFalse(sportCar1.isFault)

    // When
    sportCar1.fault()
    // Then
    XCTAssertTrue(sportCar1.isFault)

    // When
    sportCar1.materialize()
    // Then
    XCTAssertFalse(sportCar1.isFault)

    // When
    sportCar1.fault()
    // Then
    XCTAssertTrue(sportCar1.isFault)
  }

  func test_Delete() {
    let context = container.viewContext

    // Given
    let sportCar1 = SportCar(context: context)
    sportCar1.maker = "McLaren"
    sportCar1.model = "570GT"
    sportCar1.numberPlate = "203"

    // When
    sportCar1.delete()

    // Then
    XCTAssertTrue(sportCar1.isDeleted)
  }

  func test_CreatePermanentID() throws {
    let context = container.viewContext
    let car = Car(context: context)
    car.maker = "McLaren"
    car.model = "570GT"
    car.numberPlate = "203"

    let tempID = car.objectID
    XCTAssertTrue(tempID.isTemporaryID)
    let permanentID = try car.obtainPermanentID()
    XCTAssertNotEqual(tempID, permanentID)
    try context.save()
    XCTAssertEqual(car.objectID, permanentID)
    XCTAssertFalse(car.objectID.isTemporaryID)
  }

  func test_EvaluatePredicate() {
    let context = container.viewContext
    do {
      let car = Car(context: context)
      XCTAssertTrue(car.evaluate(with: .init(value: true)))
    }

    do {
      let predicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
      let car = Car(context: context)
      XCTAssertFalse(car.evaluate(with: predicate))
    }

    do {
      let predicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
      let car = Car(context: context)
      car.maker = "McLaren"
      XCTAssertFalse(car.evaluate(with: predicate))
    }

    do {
      let predicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "FIAT")
      let car = Car(context: context)
      car.maker = "FIAT"
      XCTAssertTrue(car.evaluate(with: predicate))
    }
    do {
      let predicate = NSPredicate(
        format: "%K == %@ AND %K == %@", #keyPath(Car.maker), "FIAT", #keyPath(Car.numberPlate), "123")
      let car = Car(context: context)
      car.maker = "FIAT"
      car.numberPlate = "000"
      XCTAssertFalse(car.evaluate(with: predicate))
    }
    do {
      let predicate = NSPredicate(
        format: "%K == %@ AND %K == %@", #keyPath(Car.maker), "FIAT", #keyPath(Car.numberPlate), "123")
      let car = Car(context: context)
      car.maker = "FIAT"
      car.numberPlate = "123"
      XCTAssertTrue(car.evaluate(with: predicate))
    }
  }
}
