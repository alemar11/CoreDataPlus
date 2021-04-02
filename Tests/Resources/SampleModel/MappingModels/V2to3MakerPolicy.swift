// CoreDataPlus

import CoreData

final class V2to3MakerPolicy: NSEntityMigrationPolicy {
  override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
    try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)

    guard let makerName = sInstance.value(forKey: MakerKey) as? String else {
      return
    }

    guard let car = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance]).first else {
      fatalError("must return car") }

    guard let context = car.managedObjectContext else {
      fatalError("must have context")
    }

    let maker = context.findOrCreateMaker(withName: makerName)
    if var currentCars = maker.value(forKey: CarsKey) as? Set<NSManagedObject> {
      currentCars.insert(car)
      maker.setValue(currentCars, forKey: CarsKey)
    } else {
      var cars = Set<NSManagedObject>()
      cars.insert(car)
      maker.setValue(cars, forKey: CarsKey)
    }
  }
}

private let CarsKey = "cars"
private let MakerKey = "maker"
private let NameKey = "name"
private let MakerEntityName = "Maker"
private let CountryEntityName = "Country"

extension NSManagedObject {
  fileprivate func isMaker(withName name: String) -> Bool {
    return entity.name == MakerEntityName && (value(forKey: NameKey) as? String) == name
  }
}

extension NSManagedObjectContext {
  fileprivate func findOrCreateMaker(withName name: String) -> NSManagedObject {
    guard let maker = materializedObject(matching: { $0.isMaker(withName: name) }) else {
      let maker = NSEntityDescription.insertNewObject(forEntityName: MakerEntityName, into: self)
      maker.setValue(name, forKey: NameKey)
      return maker
    }
    return maker
  }

  fileprivate func materializedObject(matching condition: (NSManagedObject) -> Bool) -> NSManagedObject? {
    for object in registeredObjects where !object.isFault {
      guard condition(object) else { continue }
      return object
    }
    return nil
  }
}
