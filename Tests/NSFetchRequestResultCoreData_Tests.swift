// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

final class NSFetchRequestResultCoreDataTests: InMemoryTestCase {

  func test_FetchObjectsIDs() throws {
    let context = container.viewContext

    // Given
    context.fillWithSampleData()
    try context.save()
    XCTAssertFalse(context.registeredObjects.isEmpty)
    context.reset()
    XCTAssertTrue(context.registeredObjects.isEmpty)

    // When
    let predicate = NSPredicate(format: "%K == %@", #keyPath(Car.maker), "McLaren")
    let ids = try Car.fetchObjectIDs(in: context, where: predicate)
    let idCar = try Car.fetchObjectIDs(in: context, includingSubentities: false, where: predicate)
    let idSportCar = try SportCar.fetchObjectIDs(in: context, includingSubentities: false, where: predicate)
    let idExpensiveSportCar = try ExpensiveSportCar.fetchObjectIDs(in: context, includingSubentities: false, where: predicate)
    let noIds = try Car.fetchObjectIDs(in: context, where: NSPredicate(format: "%K == %@", #keyPath(SportCar.numberPlate), "not-existing-number-plage"))

    // Then
    XCTAssertEqual(ids.count, 2)
    XCTAssertEqual(idCar.count, 0)
    XCTAssertEqual(idSportCar.count, 1)
    XCTAssertEqual(idExpensiveSportCar.count, 1)
    XCTAssertEqual(noIds.count, 0)
    XCTAssertTrue(context.registeredObjects.isEmpty)
  }

  func test_deleteIncludingSubentities() {
    let context = container.viewContext

    // Given
    context.fillWithSampleData()
    // When
    XCTAssertNoThrow(try SportCar.delete(in: context, where: NSPredicate(format: "%K == %@", #keyPath(SportCar.numberPlate), "302"), limit: 1000))
    // Then
    XCTAssertTrue(try SportCar.fetchObjects(in: context).filter { $0.numberPlate == "302" }.isEmpty)
    XCTAssertTrue(try ExpensiveSportCar.fetchObjects(in: context).filter { $0.numberPlate == "302" }.isEmpty)

    // When
    XCTAssertNoThrow(try ExpensiveSportCar.delete(in: context, where: NSPredicate(format: "%K == %@", #keyPath(SportCar.numberPlate), "301")))
    // Then
    XCTAssertTrue(try SportCar.fetchObjects(in: context).filter { $0.numberPlate == "301" }.isEmpty)
    XCTAssertTrue(try ExpensiveSportCar.fetchObjects(in: context).filter { $0.numberPlate == "301" }.isEmpty)

    // When
    XCTAssertNoThrow(try SportCar.delete(in: context, where: NSPredicate(value: true)))
    // Then
    XCTAssertTrue(try SportCar.fetchObjects(in: context).isEmpty)
    XCTAssertTrue(try ExpensiveSportCar.fetchObjects(in: context).isEmpty)
    XCTAssertTrue(try !Car.fetchObjects(in: context).isEmpty)

    // When
    XCTAssertNoThrow(try Car.delete(in: context))
    // Then
    XCTAssertTrue(try Car.fetchObjects(in: context).isEmpty)

  }

  func test_deleteExcludingSubentities() {
    let context = container.viewContext

    // Given
    context.fillWithSampleData()
    // When
    XCTAssertNoThrow(try SportCar.delete(in: context, includingSubentities: false, where: NSPredicate(format: "%K == %@", #keyPath(SportCar.numberPlate), "302"))) //it's an ExpensiveSportCar
    // Then
    XCTAssertFalse(try SportCar.fetchObjects(in: context).filter { $0.numberPlate == "302" }.isEmpty)
    XCTAssertFalse(try ExpensiveSportCar.fetchObjects(in: context).filter { $0.numberPlate == "302" }.isEmpty)

    // When
    XCTAssertNoThrow(try ExpensiveSportCar.delete(in: context, includingSubentities: false, where: NSPredicate(format: "%K == %@", #keyPath(SportCar.numberPlate), "301")))
    // Then
    XCTAssertTrue(try SportCar.fetchObjects(in: context).filter { $0.numberPlate == "301" }.isEmpty)
    XCTAssertTrue(try ExpensiveSportCar.fetchObjects(in: context).filter { $0.numberPlate == "301" }.isEmpty)

    // When
    XCTAssertNoThrow(try SportCar.delete(in: context, includingSubentities: false, where: NSPredicate(value: true)))
    // Then
    XCTAssertFalse(try SportCar.fetchObjects(in: context).isEmpty)
    XCTAssertFalse(try ExpensiveSportCar.fetchObjects(in: context).isEmpty)

    // When
    XCTAssertNoThrow(try Car.delete(in: context))
    // Then
    XCTAssertTrue(try Car.fetchObjects(in: context).isEmpty)

  }

  func test_deleteExcludingExceptions() throws {
    let context = container.viewContext
    context.fillWithSampleData()

    // Given
    let optonalCar = try Car.fetchObjects(in: context).filter { $0.numberPlate == "5" }.first
    let optionalPerson = try Person.fetchObjects(in: context).filter { $0.firstName == "Theodora" && $0.lastName == "Stone" }.first
    let persons = try Person.fetchObjects(in: context).filter { $0.lastName == "Moreton" }

    // When
    guard let car = optonalCar, let person = optionalPerson, !persons.isEmpty else {
      XCTAssertNotNil(optonalCar)
      XCTAssertNotNil(optionalPerson)
      XCTAssertFalse(persons.isEmpty)
      return
    }

    // Then

    /// Car exception
    XCTAssertNoThrow(try Car.delete(in: context, except: [car]))
    let cars = try Car.fetchObjects(in: context)
    XCTAssertNotNil(cars.filter { $0.numberPlate == "5" }.first)
    XCTAssertTrue(cars.filter { $0.numberPlate != "5" }.isEmpty)

    /// exceptions
    var exceptions = persons
    exceptions.append(person)
    XCTAssertNoThrow(try Person.delete(in: context, except: exceptions))
    XCTAssertFalse(try Person.fetchObjects(in: context).filter { ($0.firstName == "Theodora" && $0.lastName == "Stone") || ($0.lastName == "Moreton") }.isEmpty)

    /// no exceptions
    XCTAssertNoThrow(try Person.delete(in: context, except: []))
    XCTAssertTrue(try Person.fetchObjects(in: context).isEmpty)

  }

  func test_deleteWithSubentitiesExcludingExceptions() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()

    // When, Then
    let predicate = NSPredicate(format: "%K >= %@ && %K <= %@", #keyPath(Car.numberPlate), "202", #keyPath(Car.numberPlate), "204")
    let sportCars = try SportCar.fetchObjects(in: context, with: { $0.predicate = predicate })
    XCTAssertNotNil(sportCars)
    XCTAssertNoThrow(try Car.delete(in: context, except: sportCars))
    let carsAfterDelete = try Car.fetchObjects(in: context)
    XCTAssertTrue(carsAfterDelete.count == 3)
  }

}
