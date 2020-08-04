import CoreData

// MARK: - ManagedObjectContextNotification

/// **CoreDataPlus**
///
/// A `Notification` involving a `NSManagedObjectContext`.
/// - Note: Since these notifications are received only when a NSManagedObject is changed manually, they aren't triggered when executing *NSBatchUpdateRequest*/*NSBatchDeleteRequest*.
public protocol ManagedObjectContextNotification {
  var notification: Notification { get }
  init(notification: Notification)
  var managedObjectContext: NSManagedObjectContext { get }
}

public extension ManagedObjectContextNotification {
  /// **CoreDataPlus**
  ///
  /// Returns the notification's `NSManagedObjectContext`.
  var managedObjectContext: NSManagedObjectContext {
    guard let context = notification.object as? NSManagedObjectContext else {
      fatalError("Invalid Notification object.")
    }

    return context
  }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects for a given `key`.
  fileprivate func objects(forKey key: String) -> Set<NSManagedObject> {
    return (notification.userInfo?[key] as? Set<NSManagedObject>) ?? Set()
  }

  /// **CoreDataPlus**
  ///
  /// Returns an `AnyIterator<NSManagedObject>` of objects for a given `key`.
  //  fileprivate func iterator(forKey key: String) -> AnyIterator<NSManagedObject> {
  //    guard let set = notification.userInfo?[key] as? NSSet else { return AnyIterator { nil } }
  //
  //    var innerIterator = set.makeIterator()
  //    return AnyIterator { return innerIterator.next() as? NSManagedObject }
  //  }
}

// MARK: - ManagedObjectContextChange

/// **CoreDataPlus**
///
/// Types conforming to this protocol contains all the `NSManagedObjectContext` changes contained by a notification.
public protocol ManagedObjectContextChange {
  associatedtype ManagedObject: NSManagedObject
  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were inserted into the context.
  var insertedObjects: Set<ManagedObject> { get }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were updated.
  var updatedObjects: Set<ManagedObject> { get }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set`of objects that were marked for deletion during the previous event.
  var deletedObjects: Set<ManagedObject> { get }

  /// **CoreDataPlus**
  ///
  /// A `Set` of objects that were refreshed but were not dirtied in the scope of this context.
  var refreshedObjects: Set<ManagedObject> { get }

  /// **CoreDataPlus**
  ///
  /// A `Set` of objects that were invalidated.
  var invalidatedObjects: Set<ManagedObject> { get }

  /// **CoreDataPlus**
  ///
  /// When all the object in the context have been invalidated, returns a `Set` containing all the invalidated objects' NSManagedObjectID.
  var invalidatedAllObjects: Set<NSManagedObjectID> { get }
}

extension ManagedObjectContextChange {
  /// **CoreDataPlus**
  ///
  /// Returns `true` if there aren't any changes in the `NSManagedObjectContext`.
  public var isEmpty: Bool {
    return insertedObjects.isEmpty && updatedObjects.isEmpty && deletedObjects.isEmpty && refreshedObjects.isEmpty && invalidatedObjects.isEmpty && invalidatedAllObjects.isEmpty
  }
}

// MARK: - ManagedObjectContextChange & ManagedObjectContextNotification

extension ManagedObjectContextChange where Self: ManagedObjectContextNotification {
  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were inserted into the context.
  public var insertedObjects: Set<NSManagedObject> {
    return objects(forKey: NSInsertedObjectsKey)
  }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were updated.
  public var updatedObjects: Set<NSManagedObject> {
    return objects(forKey: NSUpdatedObjectsKey)
  }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set`of objects that were marked for deletion during the previous event.
  public var deletedObjects: Set<NSManagedObject> {
    return objects(forKey: NSDeletedObjectsKey)
  }

  /// **CoreDataPlus**
  ///
  /// A `Set` of objects that were refreshed but were not dirtied in the scope of this context.
  /// - Note: It can be populated only for `NSManagedObjectContextObjectsDidChange` notifications.
  public var refreshedObjects: Set<NSManagedObject> {
    return objects(forKey: NSRefreshedObjectsKey)
  }

  /// **CoreDataPlus**
  ///
  /// A `Set` of objects that were invalidated.
  /// - Note: It can be populated only for `NSManagedObjectContextObjectsDidChange` notifications.
  public var invalidatedObjects: Set<NSManagedObject> {
    return objects(forKey: NSInvalidatedObjectsKey)
  }

  /// **CoreDataPlus**
  ///
  /// When all the object in the context have been invalidated, returns a `Set` containing all the invalidated objects' NSManagedObjectID.
  /// - Note: It can be populated only for `NSManagedObjectContextObjectsDidChange` notifications.
  public var invalidatedAllObjects: Set<NSManagedObjectID> {
    guard let objectsID = notification.userInfo?[NSInvalidatedAllObjectsKey] as? [NSManagedObjectID] else {
      return Set()
    }
    return Set(objectsID)
  }
}

// MARK: - NSManagedObjectContextDidSave

/// **CoreDataPlus**
///
/// A type safe `NSManagedObjectContextDidSave` notification.
public struct ManagedObjectContextDidSaveNotification: ManagedObjectContextChange & ManagedObjectContextNotification {
  public let notification: Notification

  /// **CoreDataPlus**
  ///
  /// The `NSPersistentHistoryToken` associated to the save operation.
  @available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  public var historyToken: NSPersistentHistoryToken? {
    // FB: 6840421 (missing documentation for "newChangeToken" key)
    // it's optional because NSPersistentHistoryTrackingKey should be enabled.
    return notification.userInfo?["newChangeToken"] as? NSPersistentHistoryToken
  }

  public init(notification: Notification) {
    guard notification.name == .NSManagedObjectContextDidSave else {
      fatalError("Invalid NSManagedObjectContextDidSave notification object.")
    }

    self.notification = notification
  }
}

extension ManagedObjectContextDidSaveNotification: CustomDebugStringConvertible {
  /// A textual representation of a `ContextDidSaveNotification`, suitable for debugging.
  public var debugDescription: String {
    var components = [notification.name.rawValue]
    components.append(managedObjectContext.description)

    for (name, set) in [("inserted", insertedObjects),
                        ("updated", updatedObjects),
                        ("deleted", deletedObjects),
                        ("refreshed", refreshedObjects),
                        ("invalidated", invalidatedObjects)] {
                          let all = set.map { $0.objectID.description }.joined(separator: ", ")
                          components.append("\(name): {\(all)})")
    }

    return components.joined(separator: " ")
  }
}

// MARK: - NSManagedObjectContextWillSave

/// **CoreDataPlus**
///
/// A type safe `NSManagedObjectContextWillSave` notification.
/// - Note: It doesn't contain any additional info.
public struct ManagedObjectContextWillSaveNotification: ManagedObjectContextNotification {
  public let notification: Notification

  public init(notification: Notification) {
    guard notification.name == .NSManagedObjectContextWillSave else {
      fatalError("Invalid NSManagedObjectContextWillSave notification object.")
    }

    self.notification = notification
  }
}

// MARK: - NSManagedObjectContextObjectsDidChange

/// **CoreDataPlus**
///
/// A type safe `NSManagedObjectContextObjectsDidChange` notification.
public struct ManagedObjectContextObjectsDidChangeNotification: ManagedObjectContextChange & ManagedObjectContextNotification {
  public let notification: Notification

  public init(notification: Notification) {
    // Notification when objects in a context changed: the user info dictionary contains information about the objects that changed and what changed
    guard notification.name == .NSManagedObjectContextObjectsDidChange else {
      fatalError("Invalid NSManagedObjectContextObjectsDidChange notification object.")
    }

    self.notification = notification
  }
}

extension ManagedObjectContextObjectsDidChangeNotification: CustomDebugStringConvertible {
  public var debugDescription: String {
    var components = [notification.name.rawValue]
    components.append(managedObjectContext.description)

    for (name, set) in [("inserted", insertedObjects),
                        ("updated", updatedObjects),
                        ("deleted", deletedObjects),
                        ("refreshed", refreshedObjects),
                        ("invalidated", invalidatedObjects)] {
                          let all = set.map { $0.objectID.description }.joined(separator: ", ")
                          components.append("\(name): {\(all)})")
    }

    for (name, set) in [("invalidatedAll", invalidatedAllObjects)] {
      let all = set.map { $0.description }.joined(separator: ", ")
      components.append("\(name): {\(all)})")
    }

    return components.joined(separator: " ")
  }
}
