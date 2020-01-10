//
// CoreDataPlus
//
// Copyright © 2016-2020 Tinrobots.
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
import XCTest
@testable import CoreDataPlus

class NSSetCoreDataTests: XCTestCase {

  // Only V3 of the model as a relationship defined as NSSet (in the Maker entity)
  func testBatchFaultingToManyNSSetRelationship() throws {
    let container = OnDiskPersistentContainer.makeNew(id: UUID(), version: .version3)
    let context = container.viewContext

    try context.performSaveAndWait { context in
      let person1 = Person(context: context)
      person1.firstName = "Edythe"
      person1.lastName = "Moreton"

      let person2 = Person(context: context)
      person2.firstName = "Ellis"
      person2.lastName = "Khoury"

      let person3 = Person(context: context)
      person3.firstName = "Faron"
      person3.lastName = "Moreton"

      let fiat = Maker(context: context)
      fiat.name = "FIAT"

      /// FIAT
      let car1 = Car(context: context)
      car1.model = "Panda"
      car1.numberPlate = "1"

      let car2 = Car(context: context)
      car2.model = "Punto"
      car2.numberPlate = "2"

      let car3 = Car(context: context)
      car3.model = "Tipo"
      car3.numberPlate = "3"

      fiat.cars = NSSet(array: [car1, car2, car3])

      /// Alpha Romeo
      let alphaRomeo = Maker(context: context)
      alphaRomeo.name = "Alfa Romeo"

      let car4 = Car(context: context)
      car4.model = "Giulietta"
      car4.numberPlate = "4"

      let car5 = Car(context: context)
      car5.model = "Giulia"
      car5.numberPlate = "5"

      let car6 = Car(context: context)
      car6.model = "Mito"
      car6.numberPlate = "6"

      alphaRomeo.cars = NSSet(array: [car4, car5, car6])

      person1.cars = [car1, car4]
      person2.cars = [car2, car3]
      person3.cars = [car5, car6]
    }

    context.refreshAllObjects() //re-fault objects that don't have pending changes

    let request = Maker.newFetchRequest()
    request.predicate = NSPredicate(format: "\(#keyPath(Maker.name)) == %@", "FIAT")

    let makers = try context.fetch(request)

    XCTAssertNotNil(makers)
    XCTAssertTrue(!makers.isEmpty)

    let maker = makers.first!
    let previousFaultsCount = maker.cars?.filter { ($0 as! NSManagedObject).isFault }.count

    XCTAssertNoThrow(try maker.cars?.materializeFaultedObjects())
    let currentNotFaultsCount = maker.cars?.filter { !($0 as! NSManagedObject).isFault }.count
    let currentFaultsCount = maker.cars?.filter { ($0 as! NSManagedObject).isFault }.count

    XCTAssertTrue(previousFaultsCount == currentNotFaultsCount)
    XCTAssertTrue(currentFaultsCount == 0)

    try container.destroy()
  }

  func testNSSetRelationshipDelete() throws {
    let container = OnDiskPersistentContainer.makeNew(id: UUID(), version: .version3)
    let context = container.viewContext

    try context.performSaveAndWait { context in
      let person1 = Person(context: context)
      person1.firstName = "Edythe"
      person1.lastName = "Moreton"

      let person2 = Person(context: context)
      person2.firstName = "Ellis"
      person2.lastName = "Khoury"

      let person3 = Person(context: context)
      person3.firstName = "Faron"
      person3.lastName = "Moreton"

      let fiat = Maker(context: context)
      fiat.name = "FIAT"

      /// FIAT
      let car1 = Car(context: context)
      car1.model = "Panda"
      car1.numberPlate = "1"

      let car2 = Car(context: context)
      car2.model = "Punto"
      car2.numberPlate = "2"

      let car3 = Car(context: context)
      car3.model = "Tipo"
      car3.numberPlate = "3"

      fiat.cars = NSSet(array: [car1, car2, car3])

      /// Alpha Romeo
      let alphaRomeo = Maker(context: context)
      alphaRomeo.name = "Alfa Romeo"

      let car4 = Car(context: context)
      car4.model = "Giulietta"
      car4.numberPlate = "4"

      let car5 = Car(context: context)
      car5.model = "Giulia"
      car5.numberPlate = "5"

      let car6 = Car(context: context)
      car6.model = "Mito"
      car6.numberPlate = "6"

      alphaRomeo.cars = NSSet(array: [car4, car5, car6])

      person1.cars = [car1, car4]
      person2.cars = [car2, car3]
      person3.cars = [car5, car6]
    }

    context.refreshAllObjects() //re-fault objects that don't have pending changes

    let request = Maker.newFetchRequest()
    request.predicate = NSPredicate(format: "\(#keyPath(Maker.name)) == %@", "FIAT")

    let makers = try context.fetch(request)

    XCTAssertNotNil(makers)
    XCTAssertTrue(!makers.isEmpty)

    let maker = makers.first!
    XCTAssertEqual(maker.cars?.count ?? -1, 3)

    maker.cars?.delete()
    try context.save()
    XCTAssertEqual(maker.cars?.count ?? -1, 0)

    try container.destroy()
  }

}
