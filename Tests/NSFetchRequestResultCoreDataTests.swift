// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

final class NSFetchRequestResultCoreDataTests: CoreDataPlusInMemoryTestCase {

  func testFetchObjectsIDs() throws {
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

  func testdeleteIncludingSubentities() {
    let context = container.viewContext

    // Given
    context.fillWithSampleData()
    // When
    XCTAssertNoThrow(try SportCar.delete(in: context, where: NSPredicate(format: "%K == %@", #keyPath(SportCar.numberPlate), "302"), limit: 1000))
    // Then
    XCTAssertTrue(try SportCar.fetch(in: context).filter { $0.numberPlate == "302" }.isEmpty)
    XCTAssertTrue(try ExpensiveSportCar.fetch(in: context).filter { $0.numberPlate == "302" }.isEmpty)

    // When
    XCTAssertNoThrow(try ExpensiveSportCar.delete(in: context, where: NSPredicate(format: "%K == %@", #keyPath(SportCar.numberPlate), "301")))
    // Then
    XCTAssertTrue(try SportCar.fetch(in: context).filter { $0.numberPlate == "301" }.isEmpty)
    XCTAssertTrue(try ExpensiveSportCar.fetch(in: context).filter { $0.numberPlate == "301" }.isEmpty)

    // When
    XCTAssertNoThrow(try SportCar.delete(in: context, where: NSPredicate(value: true)))
    // Then
    XCTAssertTrue(try SportCar.fetch(in: context).isEmpty)
    XCTAssertTrue(try ExpensiveSportCar.fetch(in: context).isEmpty)
    XCTAssertTrue(try !Car.fetch(in: context).isEmpty)

    // When
    XCTAssertNoThrow(try Car.delete(in: context))
    // Then
    XCTAssertTrue(try Car.fetch(in: context).isEmpty)

  }

  func testdeleteExcludingSubentities() {
    let context = container.viewContext

    // Given
    context.fillWithSampleData()
    // When
    XCTAssertNoThrow(try SportCar.delete(in: context, includingSubentities: false, where: NSPredicate(format: "%K == %@", #keyPath(SportCar.numberPlate), "302"))) //it's an ExpensiveSportCar
    // Then
    XCTAssertFalse(try SportCar.fetch(in: context).filter { $0.numberPlate == "302" }.isEmpty)
    XCTAssertFalse(try ExpensiveSportCar.fetch(in: context).filter { $0.numberPlate == "302" }.isEmpty)

    // When
    XCTAssertNoThrow(try ExpensiveSportCar.delete(in: context, includingSubentities: false, where: NSPredicate(format: "%K == %@", #keyPath(SportCar.numberPlate), "301")))
    // Then
    XCTAssertTrue(try SportCar.fetch(in: context).filter { $0.numberPlate == "301" }.isEmpty)
    XCTAssertTrue(try ExpensiveSportCar.fetch(in: context).filter { $0.numberPlate == "301" }.isEmpty)

    // When
    XCTAssertNoThrow(try SportCar.delete(in: context, includingSubentities: false, where: NSPredicate(value: true)))
    // Then
    XCTAssertFalse(try SportCar.fetch(in: context).isEmpty)
    XCTAssertFalse(try ExpensiveSportCar.fetch(in: context).isEmpty)

    // When
    XCTAssertNoThrow(try Car.delete(in: context))
    // Then
    XCTAssertTrue(try Car.fetch(in: context).isEmpty)

  }

  func testdeleteExcludingExceptions() throws {
    let context = container.viewContext
    context.fillWithSampleData()

    // Given
    let optonalCar = try Car.fetch(in: context).filter { $0.numberPlate == "5" }.first
    let optionalPerson = try Person.fetch(in: context).filter { $0.firstName == "Theodora" && $0.lastName == "Stone" }.first
    let persons = try Person.fetch(in: context).filter { $0.lastName == "Moreton" }

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
    let cars = try Car.fetch(in: context)
    XCTAssertNotNil(cars.filter { $0.numberPlate == "5" }.first)
    XCTAssertTrue(cars.filter { $0.numberPlate != "5" }.isEmpty)

    /// exceptions
    var exceptions = persons
    exceptions.append(person)
    XCTAssertNoThrow(try Person.delete(in: context, except: exceptions))
    XCTAssertFalse(try Person.fetch(in: context).filter { ($0.firstName == "Theodora" && $0.lastName == "Stone") || ($0.lastName == "Moreton") }.isEmpty)

    /// no exceptions
    XCTAssertNoThrow(try Person.delete(in: context, except: []))
    XCTAssertTrue(try Person.fetch(in: context).isEmpty)

  }

  func testdeleteWithSubentitiesExcludingExceptions() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()

    // When, Then
    let predicate = NSPredicate(format: "%K >= %@ && %K <= %@", #keyPath(Car.numberPlate), "202", #keyPath(Car.numberPlate), "204")
    let sportCars = try SportCar.fetch(in: context, with: { $0.predicate = predicate })
    XCTAssertNotNil(sportCars)
    XCTAssertNoThrow(try Car.delete(in: context, except: sportCars))
    let carsAfterDelete = try Car.fetch(in: context)
    XCTAssertTrue(carsAfterDelete.count == 3)
  }

}
