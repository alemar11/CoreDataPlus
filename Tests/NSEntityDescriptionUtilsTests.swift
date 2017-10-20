// 
// CoreDataPlus
//
// Copyright © 2016-2017 Tinrobots.
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

import XCTest
import CoreData
@testable import CoreDataPlus

class NSEntityDescriptionUtilsTests: XCTestCase {

  func testEntity() {
    let stack = CoreDataStack()!
    let context = stack.mainContext
    
    let ec = ExpensiveSportCar(context: context)
    print(ec.entity.hierarchyEntities().map{$0.name})
  }

  func testCommonEntityAncestor() {
    let stack = CoreDataStack()!
    let context = stack.mainContext

    do {
      let expensiveSportCar = ExpensiveSportCar(context: context)
      let sportCar = SportCar(context: context)
      let ancestorCommontEntity = expensiveSportCar.entity.commonEntityAncestor(with: sportCar.entity)
      XCTAssertNotNil(ancestorCommontEntity)
      XCTAssertTrue(ancestorCommontEntity == sportCar.entity)
    }

    do {
      let sportCar = SportCar(context: context)
      let expensiveSportCar = ExpensiveSportCar(context: context)
     
      let ancestorCommontEntity = sportCar.entity.commonEntityAncestor(with: expensiveSportCar.entity)
      XCTAssertNotNil(ancestorCommontEntity)
      XCTAssertTrue(ancestorCommontEntity == sportCar.entity)
    }

    do {
      let expensiveSportCar = ExpensiveSportCar(context: context)
      let expensiveSportCar2 = ExpensiveSportCar(context: context)

      let ancestorCommontEntity = expensiveSportCar.entity.commonEntityAncestor(with: expensiveSportCar2.entity)
      XCTAssertNotNil(ancestorCommontEntity)
      XCTAssertTrue(ancestorCommontEntity == expensiveSportCar2.entity)
    }

    do {
      let sportCar = SportCar(context: context)
      let sportCar2 = SportCar(context: context)

      let ancestorCommontEntity = sportCar.entity.commonEntityAncestor(with: sportCar2.entity)
      XCTAssertNotNil(ancestorCommontEntity)
      XCTAssertTrue(ancestorCommontEntity == sportCar.entity)
    }

    do {
      let sportCar = SportCar(context: context)
      let car = Car(context: context)

      let ancestorCommontEntity = sportCar.entity.commonEntityAncestor(with: car.entity)
      XCTAssertNotNil(ancestorCommontEntity)
      XCTAssertTrue(ancestorCommontEntity == car.entity)
    }
    
    do {
      let car = Car(context: context)
      let sportCar = SportCar(context: context)
      
      let ancestorCommontEntity = car.entity.commonEntityAncestor(with: sportCar.entity)
      XCTAssertNotNil(ancestorCommontEntity)
      XCTAssertTrue(ancestorCommontEntity == car.entity)
    }

    do {
      let sportCar = SportCar(context: context)
      let person = Person(context: context)

      let ancestorCommontEntity = sportCar.entity.commonEntityAncestor(with: person.entity)
      XCTAssertNil(ancestorCommontEntity)
    }

    do {
      let sportCar = SportCar(context: context)
      let person = Person(context: context)

      let ancestorCommontEntity = person.entity.commonEntityAncestor(with: sportCar.entity)
      XCTAssertNil(ancestorCommontEntity)
    }

  }


  func testEntitiesKeepingOnlyCommonEntityAncestors() {
    let stack = CoreDataStack()!
    let context = stack.mainContext

    do {
      let entities = [ExpensiveSportCar(context: context).entity, ExpensiveSportCar(context: context).entity, SportCar(context: context).entity, SportCar(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonEntityAncestors()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == SportCar(context: context).entity)
    }

    do {
      let entities = [ExpensiveSportCar(context: context).entity, ExpensiveSportCar(context: context).entity, SportCar(context: context).entity, Car(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonEntityAncestors()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == Car(context: context).entity)
    }

    do {
      let entities = [Car(context: context).entity, ExpensiveSportCar(context: context).entity, ExpensiveSportCar(context: context).entity, SportCar(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonEntityAncestors()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == Car(context: context).entity)
    }

    do {
      let entities = [SportCar(context: context).entity, Car(context: context).entity, ExpensiveSportCar(context: context).entity, ExpensiveSportCar(context: context).entity, ]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonEntityAncestors()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == Car(context: context).entity)
    }

    do {
      let entities = [Car(context: context).entity, Car(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonEntityAncestors()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == Car(context: context).entity)
    }

    do {
      let entities = [SportCar(context: context).entity, Car(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonEntityAncestors()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == Car(context: context).entity)
    }

    do {
      let entities = [ExpensiveSportCar(context: context).entity, ExpensiveSportCar(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonEntityAncestors()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == ExpensiveSportCar(context: context).entity)
    }

    do {
      let entities = [ExpensiveSportCar(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonEntityAncestors()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == ExpensiveSportCar(context: context).entity)
    }

    do {
      let entities = [SportCar(context: context).entity, SportCar(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonEntityAncestors()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == SportCar(context: context).entity)
    }

    do {
      let entities = [SportCar(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonEntityAncestors()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 1)
      XCTAssertTrue(ancestors.first == SportCar(context: context).entity)
    }

    /// 2+

    do {
      let entities = [ExpensiveSportCar(context: context).entity, ExpensiveSportCar(context: context).entity, SportCar(context: context).entity, SportCar(context: context).entity, Person(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonEntityAncestors()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 2)
      XCTAssertTrue(ancestors.contains(SportCar(context: context).entity))
      XCTAssertTrue(ancestors.contains(Person(context: context).entity))
    }

    do {
      let entities = [ExpensiveSportCar(context: context).entity, ExpensiveSportCar(context: context).entity, SportCar(context: context).entity, SportCar(context: context).entity, Person(context: context).entity, Car(context: context).entity]
      let ancestors = Set(entities).entitiesKeepingOnlyCommonEntityAncestors()
      XCTAssertTrue(!ancestors.isEmpty)
      XCTAssertTrue(ancestors.count == 2)
      XCTAssertTrue(ancestors.contains(Car(context: context).entity))
      XCTAssertTrue(ancestors.contains(Person(context: context).entity))
    }

  }

}
