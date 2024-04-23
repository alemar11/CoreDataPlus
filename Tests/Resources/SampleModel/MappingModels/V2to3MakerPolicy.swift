// CoreDataPlus

import CoreData

final class V2to3MakerPolicy: NSEntityMigrationPolicy {
  override func createDestinationInstances(
    forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager
  ) throws {
    try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)

    guard let makerName = sInstance.value(forKey: makerKey) as? String else {
      return
    }

    guard let car = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance]).first
    else {
      fatalError("must return car")
    }

    guard let context = car.managedObjectContext else {
      fatalError("must have context")
    }

    // implementation 1
    let maker = context.findOrCreateMaker(withName: makerName)

    // implementation 2
    //
    // This implementation relies on the NSMigrationManager userInfo as lookup table to avoid fetch request
    // (the previous implementation is fine too because it searches for already registered object, no actual fetch request are done)
    // In general you may want to avoid to do many fetch requests doing a migration (mostly because you need to check for performance
    // and memory pressure)
    // let maker = context.findOrCreateMaker(withName: makerName, in: manager)

    if var currentCars = maker.value(forKey: carsKey) as? Set<NSManagedObject> {
      currentCars.insert(car)
      maker.setValue(currentCars, forKey: carsKey)
    } else {
      var cars = Set<NSManagedObject>()
      cars.insert(car)
      maker.setValue(cars, forKey: carsKey)
    }
  }
  override func endInstanceCreation(forMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
    try super.endInstanceCreation(forMapping: mapping, manager: manager)
    // This could be a good place to do same cleaning (i.e. NSMigrationManager userInfo) if they are needed
  }
}

private let carsKey = "cars"
private let makerKey = "maker"
private let nameKey = "name"
private let makerEntityName = "Maker"
private let countryEntityName = "Country"

extension NSManagedObject {
  fileprivate func isMaker(withName name: String) -> Bool {
    entity.name == makerEntityName && (value(forKey: nameKey) as? String) == name
  }
}

extension NSManagedObjectContext {
  fileprivate func findOrCreateMaker(withName name: String, in manager: NSMigrationManager) -> NSManagedObject {
    // It's pretty common to use the NSMigrationManager userInfo property as a lookup table to avoid fetch requests
    var userInfo: [AnyHashable: Any]
    if let managerUserInfo = manager.userInfo {
      userInfo = managerUserInfo
    } else {
      userInfo = [AnyHashable: Any]()
    }
    var makersLookup: [String: NSManagedObject]
    if let lookup = userInfo["makers"] as? [String: NSManagedObject] {
      makersLookup = lookup
    } else {
      makersLookup = [String: NSManagedObject]()
      userInfo["makers"] = makersLookup
    }

    if let maker = makersLookup[name] {
      return maker
    }

    let maker = NSEntityDescription.insertNewObject(forEntityName: makerEntityName, into: self)
    maker.setValue(name, forKey: nameKey)
    makersLookup[name] = maker
    userInfo["makers"] = makersLookup
    manager.userInfo = userInfo
    return maker
  }

  fileprivate func findOrCreateMaker(withName name: String) -> NSManagedObject {
    guard let maker = materializedObject(matching: { $0.isMaker(withName: name) }) else {
      let maker = NSEntityDescription.insertNewObject(forEntityName: makerEntityName, into: self)
      maker.setValue(name, forKey: nameKey)
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
