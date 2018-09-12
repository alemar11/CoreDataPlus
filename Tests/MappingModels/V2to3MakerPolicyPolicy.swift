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

//    guard let continentCode = sInstance.isoContinent else { return }
//    guard let country = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance]).first
//      else { fatalError("must return country") }
//    guard let context = country.managedObjectContext else { fatalError("must have context") }
//    let continent = context.findOrCreateContinent(withISOCode: continentCode)
//    country.setContinent(continent)

  }

}


//private let NumericISO3166CodeKey = "numericISO3166Code"
//private let IsoContinentKey = "isoContinent"
//private let ContinentKey = "continent"
//private let ContinentEntityName = "Continent"
//private let CountryEntityName = "Country"
//
//extension NSManagedObject {
//  fileprivate var isoContinent: NSNumber? {
//    return value(forKey: IsoContinentKey) as? NSNumber
//  }
//
//  fileprivate func setContinent(_ continent: NSManagedObject) {
//    setValue(continent, forKey: ContinentKey)
//  }
//
//  fileprivate func isContinent(withCode code: NSNumber) -> Bool {
//    return entity.name == ContinentEntityName && (value(forKey: NumericISO3166CodeKey) as? NSNumber) == code
//  }
//}
//
//extension NSManagedObjectContext {
//  fileprivate func findOrCreateContinent(withISOCode isoCode: NSNumber) -> NSManagedObject {
//    guard let continent = materializedObject(matching: { $0.isContinent(withCode:isoCode) }) else {
//      let continent = NSEntityDescription.insertNewObject(forEntityName: ContinentEntityName, into: self)
//      continent.setValue(isoCode, forKey: NumericISO3166CodeKey)
//      return continent
//    }
//    return continent
//  }
//
//  fileprivate func materializedObject(matching condition: (NSManagedObject) -> Bool) -> NSManagedObject? {
//    for object in registeredObjects where !object.isFault {
//      guard condition(object) else { continue }
//      return object
//    }
//    return nil
//  }
//}
