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

/// **CoreDataPlus**
///
/// An instance of AnyManagedObjectContextChange forwards its operations to an underlying base `ManagedObjectContextChange`
/// having the same ManagedObject type, hiding the specifics of the underlying ManagedObjectChange.
public struct AnyManagedObjectContextChange<T: NSManagedObject>: ManagedObjectContextChange {
  public var insertedObjects: Set<T> {
    return _insertedObjects
  }

  public var updatedObjects: Set<T> {
    return _updatedObjects
  }

  public var deletedObjects: Set<T> {
    return _deletedObjects
  }

  public var refreshedObjects: Set<T> {
    return _refreshedObjects
  }

  public var invalidatedObjects: Set<T> {
    return _invalidatedObjects
  }

  public var invalidatedAllObjects: Set<NSManagedObjectID> {
    return _invalidatedAllObjects
  }

  private let _insertedObjects: Set<T>
  private let _updatedObjects: Set<T>
  private let _deletedObjects: Set<T>
  private let _refreshedObjects: Set<T>
  private let _invalidatedObjects: Set<T>
  private let _invalidatedAllObjects: Set<NSManagedObjectID>

  /// **CoreDataPlus**
  ///
  /// Creates a new `AnyManagedObjectContextChange`.
  init<U: ManagedObjectContextChange>(_ change: U) where U.ManagedObject == T {
    self._insertedObjects = change.insertedObjects
    self._updatedObjects = change.updatedObjects
    self._deletedObjects = change.deletedObjects
    self._refreshedObjects = change.refreshedObjects
    self._invalidatedObjects = change.invalidatedObjects
    self._invalidatedAllObjects = change.invalidatedAllObjects
  }

  /// **CoreDataPlus**
  ///
  /// Creates a new `AnyManagedObjectContextChange`.
  init(insertedObjects: Set<T>,
       updatedObjects: Set<T>,
       deletedObjects: Set<T>,
       refreshedObjects: Set<T>,
       invalidatedObjects: Set<T>,
       invalidatedAllObjects: Set<NSManagedObjectID>) {
    self._insertedObjects = insertedObjects
    self._updatedObjects = updatedObjects
    self._deletedObjects = deletedObjects
    self._refreshedObjects = refreshedObjects
    self._invalidatedObjects = invalidatedObjects
    self._invalidatedAllObjects = invalidatedAllObjects
  }

  /// **CoreDataPlus**
  ///
  /// Creates a new `AnyManagedObjectContextChange` with empty change sets.
  static func makeEmpty() -> AnyManagedObjectContextChange<T> {
    return AnyManagedObjectContextChange(insertedObjects: Set(),
                                         updatedObjects: Set(),
                                         deletedObjects: Set(),
                                         refreshedObjects: Set(),
                                         invalidatedObjects: Set(),
                                         invalidatedAllObjects: Set())
  }
}
