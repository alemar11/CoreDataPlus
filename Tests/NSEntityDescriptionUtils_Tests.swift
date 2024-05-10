// CoreDataPlus

import CoreData
import XCTest

@testable import CoreDataPlus

extension NSManagedObject {
  fileprivate convenience init(usingContext context: NSManagedObjectContext) {
    let name = String(describing: type(of: self))
    let entity = NSEntityDescription.entity(forEntityName: name, in: context)!
    self.init(entity: entity, insertInto: context)
  }
}

// This entity is not mapped in any model and it will trigger an error:
// "No NSEntityDescriptions in any model claim the NSManagedObject subclass 'CoreDataPlus_Tests.FakeEntity' 
// so +entity is confused. Have you loaded your NSManagedObjectModel yet ?"
private class FakeEntity: NSManagedObject { }

final class NSEntityDescriptionUtils_Tests: InMemoryTestCase {
  func test_EntityName() {
    XCTAssertEqual(NSManagedObject.entityName, "NSManagedObject")
    XCTAssertEqual(FakeEntity.entityName, "FakeEntity")
    XCTAssertEqual(SportCar.entityName, "SportCar")
  }
  
  func test_Entity() {
    let context = container.viewContext
    let expensiveCar = ExpensiveSportCar(context: context)
    XCTAssertEqual(SportCar.entityName, "SportCar")
    let entityNames = expensiveCar.entity.ancestorEntities().compactMap { $0.name }
    XCTAssertTrue(entityNames.count == 2)
    XCTAssertTrue(entityNames.contains(Car.entityName))
    XCTAssertTrue(entityNames.contains(SportCar.entityName))
    XCTAssertFalse(
      entityNames.contains(ExpensiveSportCar.entityName), "The hierarchy should contain only super entities")
  }

  func test_TopMostEntity() {
    /// Making sure that all the necessary bits are available

    guard let model = container.viewContext.persistentStoreCoordinator?.managedObjectModel else {
      XCTFail("Missing Model")
      return
    }

    let entities = model.entitiesByName.keys
    guard model.entitiesByName.keys.contains("Car") else {
      XCTFail("Car Entity not found; available entities: \(entities)")
      return
    }
    
    // Car.entity().name can be nil while running tests
    // To avoid some random failed tests, the entity is created by looking in a context.
    guard 
      let carEntity = NSEntityDescription.entity(forEntityName: Car.entityName, in: container.viewContext)
    else {
      XCTFail("Car Entity Not Found.")
      return
    }

    guard let _ = carEntity.name else {
      fatalError("\(carEntity) should have a name.")
    }

    // Using a custom init to avoid some problems during tests.
    let expensiveCar = ExpensiveSportCar(usingContext: container.viewContext)
    let topMostAncestorEntityForExpensiveCar = expensiveCar.entity.topMostAncestorEntity
    XCTAssertTrue(
      topMostAncestorEntityForExpensiveCar == carEntity,
      "\(topMostAncestorEntityForExpensiveCar) should be a Car entity \(String(describing: topMostAncestorEntityForExpensiveCar.name))."
    )

    let car = Car(usingContext: container.viewContext)
    let topMostAncestorEntity = car.entity.topMostAncestorEntity
    XCTAssertTrue(topMostAncestorEntity == carEntity, "\(topMostAncestorEntity) should be a Car entity.")
  }

  func test_CommonEntityAncestor() {
    let context = container.viewContext

    do {
      let expensiveSportCar = ExpensiveSportCar(context: context)
      let sportCar = SportCar(context: context)
      let ancestorCommontEntity = expensiveSportCar.entity.commonAncestorEntity(with: sportCar.entity)
      XCTAssertNotNil(ancestorCommontEntity)
      XCTAssertTrue(ancestorCommontEntity == sportCar.entity)
    }

    do {
      let sportCar = SportCar(context: context)
      let expensiveSportCar = ExpensiveSportCar(context: context)

      let ancestorCommontEntity = sportCar.entity.commonAncestorEntity(with: expensiveSportCar.entity)
      XCTAssertNotNil(ancestorCommontEntity)
      XCTAssertTrue(ancestorCommontEntity == sportCar.entity)
    }

    do {
      let expensiveSportCar = ExpensiveSportCar(context: context)
      let expensiveSportCar2 = ExpensiveSportCar(context: context)

      let ancestorCommontEntity = expensiveSportCar.entity.commonAncestorEntity(with: expensiveSportCar2.entity)
      XCTAssertNotNil(ancestorCommontEntity)
      XCTAssertTrue(ancestorCommontEntity == expensiveSportCar2.entity)
    }

    do {
      let sportCar = SportCar(context: context)
      let sportCar2 = SportCar(context: context)

      let ancestorCommontEntity = sportCar.entity.commonAncestorEntity(with: sportCar2.entity)
      XCTAssertNotNil(ancestorCommontEntity)
      XCTAssertTrue(ancestorCommontEntity == sportCar.entity)
    }

    do {
      let sportCar = SportCar(context: context)
      let car = Car(context: context)

      let ancestorCommontEntity = sportCar.entity.commonAncestorEntity(with: car.entity)
      XCTAssertNotNil(ancestorCommontEntity)
      XCTAssertTrue(ancestorCommontEntity == car.entity)
    }

    do {
      let car = Car(context: context)
      let sportCar = SportCar(context: context)

      let ancestorCommontEntity = car.entity.commonAncestorEntity(with: sportCar.entity)
      XCTAssertNotNil(ancestorCommontEntity)
      XCTAssertTrue(ancestorCommontEntity == car.entity)
    }

    do {
      let sportCar = SportCar(context: context)
      let person = Person(context: context)

      let ancestorCommontEntity = sportCar.entity.commonAncestorEntity(with: person.entity)
      XCTAssertNil(ancestorCommontEntity)
    }

    do {
      let sportCar = SportCar(context: context)
      let person = Person(context: context)

      let ancestorCommontEntity = person.entity.commonAncestorEntity(with: sportCar.entity)
      XCTAssertNil(ancestorCommontEntity)
    }

  }

  func test_EntitiesKeepingOnlyCommonEntityAncestors() {
    let context = container.viewContext

    do {
      let entities = [
        ExpensiveSportCar(context: context).entity, 
        ExpensiveSportCar(context: context).entity,
        SportCar(context: context).entity,
        SportCar(context: context).entity,
      ]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonAncestorEntities()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == SportCar(context: context).entity)
    }

    do {
      let entities = [
        ExpensiveSportCar(context: context).entity, ExpensiveSportCar(context: context).entity,
        SportCar(context: context).entity,
        Car(context: context).entity,
      ]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonAncestorEntities()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == Car(context: context).entity)
    }

    do {
      let entities = [
        Car(context: context).entity, ExpensiveSportCar(context: context).entity,
        ExpensiveSportCar(context: context).entity,
        SportCar(context: context).entity,
      ]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonAncestorEntities()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == Car(context: context).entity)
    }

    do {
      let entities = [
        SportCar(context: context).entity, Car(context: context).entity, ExpensiveSportCar(context: context).entity,
        ExpensiveSportCar(context: context).entity,
      ]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonAncestorEntities()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == Car(context: context).entity)
    }

    do {
      let entities = [Car(context: context).entity, Car(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonAncestorEntities()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == Car(context: context).entity)
    }

    do {
      let entities = [SportCar(context: context).entity, Car(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonAncestorEntities()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == Car(context: context).entity)
    }

    do {
      let entities = [ExpensiveSportCar(context: context).entity, ExpensiveSportCar(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonAncestorEntities()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == ExpensiveSportCar(context: context).entity)
    }

    do {
      let entities = [ExpensiveSportCar(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonAncestorEntities()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == ExpensiveSportCar(context: context).entity)
    }

    do {
      let entities = [SportCar(context: context).entity, SportCar(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonAncestorEntities()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == SportCar(context: context).entity)
    }

    do {
      let entities = [SportCar(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonAncestorEntities()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == SportCar(context: context).entity)
    }

    /// 2+

    do {
      let entities = [
        ExpensiveSportCar(context: context).entity, ExpensiveSportCar(context: context).entity,
        SportCar(context: context).entity,
        SportCar(context: context).entity, Person(context: context).entity,
      ]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonAncestorEntities()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 2)
      XCTAssertTrue(ancestors.contains(SportCar(context: context).entity))
      XCTAssertTrue(ancestors.contains(Person(context: context).entity))
    }

    do {
      let entities = [
        ExpensiveSportCar(context: context).entity, ExpensiveSportCar(context: context).entity,
        SportCar(context: context).entity,
        SportCar(context: context).entity, Person(context: context).entity, Car(context: context).entity,
      ]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonAncestorEntities()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 2)
      XCTAssertTrue(ancestors.contains(Car(context: context).entity))
      XCTAssertTrue(ancestors.contains(Person(context: context).entity))
    }
  }

  func test_IsSubEntity() {
    let context = container.viewContext
    let car = Car(context: context).entity
    let sportCar = SportCar(context: context).entity
    let expensiveCar = ExpensiveSportCar(context: context).entity

    XCTAssertFalse(car.isDescendantEntity(of: car))
    XCTAssertFalse(car.isDescendantEntity(of: car, recursive: true))

    XCTAssertTrue(sportCar.isDescendantEntity(of: car))
    XCTAssertTrue(sportCar.isDescendantEntity(of: car, recursive: true))

    XCTAssertFalse(expensiveCar.isDescendantEntity(of: car))  // ExpensiveSportCar is a sub entity of SportCar
    XCTAssertTrue(expensiveCar.isDescendantEntity(of: car, recursive: true))

    XCTAssertTrue(expensiveCar.isDescendantEntity(of: sportCar))
    XCTAssertTrue(expensiveCar.isDescendantEntity(of: sportCar, recursive: true))

    XCTAssertFalse(car.isDescendantEntity(of: expensiveCar))
    XCTAssertFalse(car.isDescendantEntity(of: expensiveCar, recursive: true))

    XCTAssertFalse(sportCar.isDescendantEntity(of: expensiveCar))
    XCTAssertFalse(sportCar.isDescendantEntity(of: expensiveCar, recursive: true))
  }
}
