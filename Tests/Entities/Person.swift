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

import Foundation
import CoreData
import CoreDataPlus

@objc(Person)
final public class Person: NSManagedObject {
  @NSManaged public var firstName: String
  @NSManaged public var lastName: String
  @NSManaged public var cars: Set<Car>?
}

extension Person: UpdateTimestampable {
  @NSManaged public var updatedAt: Date
}

extension Person {

  /// Primitive accessor for `updateAt` property.
  /// It's created by default from Core Data with a *primitive* suffix*.
  @NSManaged private var primitiveUpdatedAt: Date

  public override func awakeFromInsert() {
    super.awakeFromInsert()
    primitiveUpdatedAt = Date()
    //setPrimitiveValue(NSDate(), forKey: "updatedAt") // we can use one of these two options to set the value
  }

  public override func willSave() {
    super.willSave()
    refreshUpdateDate(observingChanges: false) // we don't want to get notified when this value changes.
  }

}