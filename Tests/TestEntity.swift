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
@testable import CoreDataPlus

protocol TestEntity {
  var entityName: String { get }
  func matches(_ object: NSManagedObject) -> Bool
}

struct TestVersionData {
  let data: [[TestEntity]]

  func match(with context: NSManagedObjectContext) -> Bool {
    for entityData in data {
      let request = NSFetchRequest<NSManagedObject>(entityName: entityData.first!.entityName)
      let objects = try! context.fetch(request)
      guard objects.count == entityData.count else { return false }

      guard objects.all({ o in entityData.some { $0.matches(o) } }) else { return false }
    }
    return true
  }
}

extension Sequence {
  func all(_ condition: (Iterator.Element) -> Bool) -> Bool {
    for x in self where !condition(x) {
      return false
    }
    return true
  }

  func some(_ condition: (Iterator.Element) -> Bool) -> Bool {
    for x in self where condition(x) {
      return true
    }
    return false
  }
}


enum V2 {

  struct Car2 {
    let entityName = "Car"
    var maker: String?
    var model: String?
    var numberPlate: String!
    var owner: Person2?
  }

  struct Person2 {
    let entityName = "Person"
    public var firstName: String
    public var lastName: String
    public var cars: [Car2]?
    public var updatedAt: Date
  }

  struct LuxuryCar: TestEntity {
    let entityName = "LuxuryCar"
    var maker: String?
    var model: String?
    var numberPlate: String!
    var owner: Person2?

    func matches(_ object: NSManagedObject) -> Bool {
      return false
    }

  }

  
}
