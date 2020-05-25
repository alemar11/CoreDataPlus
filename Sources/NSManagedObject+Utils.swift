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

extension NSManagedObject {
  /// **CoreDataPlus**
  ///
  /// Returns the value of a persistent property that has been changed since **last fetching** or **saving operation**.
  /// - Note: This method only reports changes to properties that are defined as persistent properties of the receiver, not changes to transient properties or custom instance variables.
  public final func changedValue(forKey key: String) -> Any? {
    return changedValues()[key]
  }

  /// **CoreDataPlus**
  ///
  /// Returns of the **last fetched** or **saved** value of the propery specified by the given key.
  /// - Note: This method only reports values of properties that are defined as persistent properties of the receiver, not values of transient properties or of custom instance variables.
  public final func committedValue(forKey key: String) -> Any? {
    return committedValues(forKeys: [key])[key]
  }

  /// **CoreDataPlus**
  ///
  /// Turns `self` into a fault.
  public final func fault() {
    refresh(mergeChanges: false)
  }

  /// **CoreDataPlus**
  ///
  /// Materializes `self`.
  public final func materialize() {
    self.willAccessValue(forKey: nil)
  }

  // swiftlint:disable line_length
  /// **CoreDataPlus**
  ///
  /// If `flag` is `true` (default), the object won't turn into a fault; instead, it’ll update its unchanged properties from the row cache, preserving any unsaved changes;
  /// if `flag` is `false`, the object will be forced to turn into a fault without merging and unsaved changes will be lost (which also causes other related managed objects to be released, so you can use this method to trim the portion of your object graph you want to hold in memory).
  ///
  /// - parameter flag: only matters if the object has unsaved changes. In this case, a `true` value won’t turn the object into a fault; instead, it’ll update the unchanged properties from the row cache, preserving any unsaved changes.
  /// If `flag` is set to `false`, the object will be forced to turn into a fault, and unsaved changes will be lost.
  /// - Note: Turning object into a fault means that strong references to related managed objects (that is, those to which object has a reference) are broken, so you can also use this method to trim a portion of your object graph you want to constrain memory usage.
  public final func refresh(mergeChanges flag: Bool = true) {
    managedObjectContext?.refresh(self, mergeChanges: flag)
  }
  // swiftlint:enable line_length

  /// **CoreDataPlus**
  ///
  /// Specifies an object that should be removed from its persistent store when changes are committed.
  public final func delete() {
    managedObjectContext?.delete(self)
  }

  /// **CoreDataPlus**
  /// Converts the object ID to a permanent ID (if the object doesn't already have a permanent ID)
  public func obtainPermanentID() throws -> NSManagedObjectID {
    try managedObjectContext?.obtainPermanentIDs(for: [self])
    return self.objectID
  }
}
