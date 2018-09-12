// 
// CoreDataPlus
//
// Copyright © 2016-2018 Tinrobots.
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

import CoreData

final class V2to3MakerPolicyPolicy: NSEntityMigrationPolicy {

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
