// CoreDataPlus
//
// Several system frameworks use Core Data internally.
// If you register to receive these notifications from all contexts (by passing nil as the object parameter to a method such as addObserver(_:selector:name:object:)),
// then you may receive unexpected notifications that are difficult to handle.

import CoreData

public extension Notification {
  // swiftlint:disable:next no_line_around_parentheses
  enum CoreDataPlus {
    // swiftlint:disable:next nesting
    public enum Payload { }
  }
}

public typealias Payload = Notification.CoreDataPlus.Payload // TODO

// MARK: - ManagedObjectContextNotification

public protocol NotificationPayload {
  /// **CoreDataPlus**
  ///
  /// Underlying Notification.
  var notification: Notification { get }
  init(notification: Notification)
}

/// **CoreDataPlus**
///
/// A `Notification` involving a `NSManagedObjectContext`.
/// - Note: Since these notifications are received only when a NSManagedObject is changed manually, they aren't triggered when executing *NSBatchUpdateRequest*/*NSBatchDeleteRequest*.
public protocol ManagedObjectContextNotificationPayload: NotificationPayload { }

public extension ManagedObjectContextNotificationPayload {
  /// **CoreDataPlus**
  ///
  /// Returns the notification's `NSManagedObjectContext`.
  var managedObjectContext: NSManagedObjectContext {
    guard let context = notification.object as? NSManagedObjectContext else {
      fatalError("NSManagedObjectContext must be defined.")
    }

    return context
  }

  //  /// **CoreDataPlus**
  //  ///
  //  /// Returns an `AnyIterator<NSManagedObject>` of objects for a given `key`.
  //    fileprivate func iterator(forKey key: String) -> AnyIterator<NSManagedObject> {
  //      guard let set = notification.userInfo?[key] as? NSSet else { return AnyIterator { nil } }
  //
  //      var innerIterator = set.makeIterator()
  //      return AnyIterator { return innerIterator.next() as? NSManagedObject }
  //    }
}

// MARK: - ManagedObjectContextChange

/// **CoreDataPlus**
///
/// Types conforming to this protocol contains all the `NSManagedObjectContext` changes contained by a notification.
public protocol ManagedObjectContextChangePayload: ManagedObjectContextNotificationPayload {
  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were inserted into the context.
  var insertedObjects: Set<NSManagedObject> { get }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were updated.
  var updatedObjects: Set<NSManagedObject> { get }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set`of objects that were marked for deletion during the previous event.
  var deletedObjects: Set<NSManagedObject> { get }

  /// **CoreDataPlus**
  ///
  /// A `Set` of objects that were refreshed but were not dirtied in the scope of this context.
  var refreshedObjects: Set<NSManagedObject> { get }

  /// **CoreDataPlus**
  ///
  /// A `Set` of objects that were invalidated.
  var invalidatedObjects: Set<NSManagedObject> { get }

  /// **CoreDataPlus**
  ///
  /// When all the object in the context have been invalidated, returns a `Set` containing all the invalidated objects' NSManagedObjectID.
  var invalidatedAllObjects: Set<NSManagedObjectID> { get }
}

// MARK: - ManagedObjectContextChange & ManagedObjectContextNotification

extension ManagedObjectContextChangePayload {
  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects for a given `key`.
  fileprivate func objects(forKey key: String) -> Set<NSManagedObject> {
    return (notification.userInfo?[key] as? Set<NSManagedObject>) ?? Set()
  }

  /// **CoreDataPlus**
  ///
  /// Returns `true` if there aren't any changes in the `NSManagedObjectContext`.
  public var isEmpty: Bool {
    return insertedObjects.isEmpty && updatedObjects.isEmpty && deletedObjects.isEmpty && refreshedObjects.isEmpty && invalidatedObjects.isEmpty && invalidatedAllObjects.isEmpty
  }

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

// MARK: - NSManagedObjectContextWillSave

extension Notification.CoreDataPlus.Payload {
  /// **CoreDataPlus**
  ///
  /// A type safe `NSManagedObjectContextWillSave` notification.
  /// - Note: It doesn't contain any additional info.
  public struct NSManagedObjectContextWillSave: ManagedObjectContextNotificationPayload {
    public let notification: Notification

    public init(notification: Notification) {
      guard notification.name == .NSManagedObjectContextWillSave else {
        fatalError("Invalid NSManagedObjectContextWillSave notification object.")
      }
      self.notification = notification
    }
  }
}

// MARK: - NSManagedObjectContextDidSave

extension Notification.CoreDataPlus.Payload {
  /// **CoreDataPlus**
  ///
  /// A type safe `NSManagedObjectContextDidSave` notification.
  public struct NSManagedObjectContextDidSave: ManagedObjectContextChangePayload & ManagedObjectContextNotificationPayload {
    public let notification: Notification

    /// **CoreDataPlus**
    ///
    /// The `NSPersistentHistoryToken` associated to the save operation.
    /// - Note: It's optional because NSPersistentHistoryTrackingKey should be enabled.
    public var historyToken: NSPersistentHistoryToken? {
      // FB: 6840421 (missing documentation for "newChangeToken" key)
      return notification.userInfo?["newChangeToken"] as? NSPersistentHistoryToken
    }

    public init(notification: Notification) {
      guard notification.name == .NSManagedObjectContextDidSave else {
        fatalError("Invalid NSManagedObjectContextDidSave notification object.")
      }

      self.notification = notification
    }
  }
}

extension Notification.CoreDataPlus.Payload.NSManagedObjectContextDidSave: CustomDebugStringConvertible {
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

extension NSManagedObjectContext {
  /// **CoreDataPlus**
  ///
  /// Asynchronously merges the changes specified in a given payload.
  /// This method refreshes any objects which have been updated in the other context,
  /// faults in any newly-inserted objects, and invokes delete(_:): on those which have been deleted.
  ///
  /// - Parameters:
  ///   - payload: A `NSManagedObjectContextDidSave` payload posted by another context.
  ///   - completion: The block to be executed after the merge completes.
  public func performMergeChanges(from payload: Notification.CoreDataPlus.Payload.NSManagedObjectContextDidSave, completion: @escaping () -> Void = {}) {
    perform {
      self.mergeChanges(fromContextDidSave: payload.notification)
      completion()
    }
  }

  /// **CoreDataPlus**
  ///
  /// Synchronously merges the changes specified in a given payload.
  /// This method refreshes any objects which have been updated in the other context,
  /// faults in any newly-inserted objects, and invokes delete(_:): on those which have been deleted.
  ///
  /// - Parameters:
  ///   - payload: A `NSManagedObjectContextDidSave` payload posted by another context.
  ///   - completion: The block to be executed after the merge completes.
  public func performAndWaitMergeChanges(from payload: Notification.CoreDataPlus.Payload.NSManagedObjectContextDidSave) {
    performAndWait {
      self.mergeChanges(fromContextDidSave: payload.notification)
    }
  }
}

// MARK: - NSManagedObjectContextObjectsDidChange

extension Notification.CoreDataPlus.Payload {
  /// **CoreDataPlus**
  ///
  /// A type safe `NSManagedObjectContextObjectsDidChange` notification.
  public struct NSManagedObjectContextObjectsDidChange: ManagedObjectContextChangePayload & ManagedObjectContextNotificationPayload {
    public let notification: Notification

    public init(notification: Notification) {
      // Notification when objects in a context changed: the user info dictionary contains information about the objects that changed and what changed
      guard notification.name == .NSManagedObjectContextObjectsDidChange else {
        fatalError("Invalid NSManagedObjectContextObjectsDidChange notification object.")
      }

      self.notification = notification
    }
  }
}

extension Notification.CoreDataPlus.Payload.NSManagedObjectContextObjectsDidChange: CustomDebugStringConvertible {
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

// MARK: - NSPersistentStoreRemoteChange

extension Notification.CoreDataPlus.Payload {
  /// **CoreDataPlus**
  ///
  /// A type safe `NSPersistentStoreRemoteChange` notification payload.
  public struct NSPersistentStoreRemoteChange: NotificationPayload {
    public let notification: Notification

    /// **CoreDataPlus**
    ///
    /// The `NSPersistentHistoryToken` associated to the change operation.
    /// -Note: It's optional because `NSPersistentHistoryTrackingKey` should be enabled.
    var historyToken: NSPersistentHistoryToken? {
      return notification.userInfo?[NSPersistentHistoryTokenKey] as? NSPersistentHistoryToken
    }

    /// **CoreDataPlus**
    ///
    // The changed store URL.
    var storeURL: URL {
      guard let url = notification.userInfo?[NSPersistentStoreURLKey] as? URL else {
        fatalError("NSPersistentStoreRemoteChange always contains the NSPersistentStore URL.")
      }
      return url
    }

    public init(notification: Notification) {
      guard notification.name == Notification.Name.NSPersistentStoreRemoteChange else {
        fatalError("Invalid NSPersistentStoreRemoteChange notification object.")
      }

      self.notification = notification
    }
  }
}
