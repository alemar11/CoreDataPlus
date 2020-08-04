// CoreDataPlus

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
