// CoreDataPlus

// Several system frameworks use Core Data internally: if you register to receive these notifications from all contexts
// (by passing nil as the object parameter to a method such as addObserver(_:selector:name:object:)),
// then you may receive unexpected notifications that are difficult to handle.

// TODO
// WWDC 2020: there should be a NSManagedObjectContext.NotificationKey.sourceContext to access the context from the userInfo
// but as of Xcode12b4 it's not there (and the userInfo contains a _PFWeakReference for key "managedObjectContext")

import CoreData
import Foundation

// MARK: - Will Save

public struct ManagedObjectContextWillSaveObjects {
  /// Notification name.
  public static let notificationName: Notification.Name = {
    if #available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, macOS 11, *) {
      return NSManagedObjectContext.willSaveObjectsNotification
    }
    return .NSManagedObjectContextWillSave
  }()

  /// Underlying notification object.
  public let notification: Notification

  /// `NSManagedObjectContext` associated with the notification.
  public var managedObjectContext: NSManagedObjectContext {
    guard let context = notification.managedObjectContext else {
      fatalError("A NSManagedObjectContext.willSaveObjectsNotification must have a NSManagedObjectContext object.")
    }
    return context
  }

  public init(notification: Notification) {
    assert(notification.name == Self.notificationName)
    self.notification = notification
  }
}

// MARK: - Did Save

public struct ManagedObjectContextDidSaveObjects {
  /// Notification name.
  public static let notificationName: Notification.Name = {
    if #available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, macOS 11, *) {
      return NSManagedObjectContext.didSaveObjectsNotification
    }
    return .NSManagedObjectContextDidSave
  }()

  /// Underlying notification object.
  public let notification: Notification

  /// `NSManagedObjectContext` associated with the notification.
  public var managedObjectContext: NSManagedObjectContext {
    guard let context = notification.managedObjectContext else {
      fatalError("A NSManagedObjectContext.didSaveObjectsNotification must have a NSManagedObjectContext object.")
    }
    return context
  }

  /// Returns a `Set` of objects that were inserted into the context.
  public var insertedObjects: Set<NSManagedObject> {
    if #available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, macOS 11, *) {
      return notification.objects(forKey: .insertedObjects)
    } else {
      return notification.objects(forKey: NSInsertedObjectsKey)
    }
  }

  /// Returns a `Set` of objects that were updated.
  public var updatedObjects: Set<NSManagedObject> {
    if #available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, macOS 11, *) {
      return notification.objects(forKey: .updatedObjects)
    } else {
      return notification.objects(forKey: NSUpdatedObjectsKey)
    }
  }

  /// Returns a `Set`of objects that were marked for deletion during the previous event.
  public var deletedObjects: Set<NSManagedObject> {
    if #available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, macOS 11, *) {
      return notification.objects(forKey: .deletedObjects)
    } else {
      return notification.objects(forKey: NSDeletedObjectsKey)
    }
  }

  /// The `NSPersistentHistoryToken` associated to the save operation.
  /// - Note: Optional: NSPersistentHistoryTrackingKey must be enabled.
  public var historyToken: NSPersistentHistoryToken? {
    // FB: 6840421 (missing documentation for "newChangeToken" key)
    return notification.userInfo?["newChangeToken"] as? NSPersistentHistoryToken
  }

  /// The new `NSQueryGenerationToken` associated to the save operation.
  /// - Note: It's only available when you are using a SQLite persistent store.
  @available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
  public var queryGenerationToken: NSQueryGenerationToken? {
    return notification.userInfo?[NSManagedObjectContext.NotificationKey.queryGeneration.rawValue] as? NSQueryGenerationToken
  }

  public init(notification: Notification) {
    assert(notification.name == Self.notificationName)
    self.notification = notification
  }
}

extension NSManagedObjectContext {
  /// Asynchronously merges the changes specified in a given payload.
  /// This method refreshes any objects which have been updated in the other context,
  /// faults in any newly-inserted objects, and invokes delete(_:): on those which have been deleted.
  ///
  /// - Parameters:
  ///   - payload: A `NSManagedObjectContextDidSave` payload posted by another context.
  ///   - completion: The block to be executed after the merge completes.
  public func performMergeChanges(from payload: ManagedObjectContextDidSaveObjects, completion: @escaping () -> Void = {}) {
    perform {
      self.mergeChanges(fromContextDidSave: payload.notification)
      completion()
    }
  }

  /// Synchronously merges the changes specified in a given payload.
  /// This method refreshes any objects which have been updated in the other context,
  /// faults in any newly-inserted objects, and invokes delete(_:): on those which have been deleted.
  ///
  /// - Parameters:
  ///   - payload: A `NSManagedObjectContextDidSave` payload posted by another context.
  ///   - completion: The block to be executed after the merge completes.
  public func performAndWaitMergeChanges(from payload: ManagedObjectContextDidSaveObjects) {
    performAndWait {
      self.mergeChanges(fromContextDidSave: payload.notification)
    }
  }
}

// MARK: - Objects Did Change

public struct ManagedObjectContextObjectsDidChange {
  /// Notification name.
  public static let notificationName: Notification.Name = {
    if #available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, macOS 11, *) {
      return NSManagedObjectContext.didChangeObjectsNotification
    }
    return .NSManagedObjectContextObjectsDidChange
  }()

  /// Underlying notification object.
  public let notification: Notification

  /// `NSManagedObjectContext` associated with the notification.
  public var managedObjectContext: NSManagedObjectContext {
    guard let context = notification.managedObjectContext else {
      fatalError("A NSManagedObjectContext.didChangeObjectsNotification must have a NSManagedObjectContext object.")
    }
    return context
  }

  /// Returns a `Set` of objects that were inserted into the context.
  public var insertedObjects: Set<NSManagedObject> {
    if #available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, macOS 11, *) {
      return notification.objects(forKey: .insertedObjects)
    } else {
      return notification.objects(forKey: NSInsertedObjectsKey)
    }
  }

  /// Returns a `Set` of objects that were updated.
  public var updatedObjects: Set<NSManagedObject> {
    if #available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, macOS 11, *) {
      return notification.objects(forKey: .updatedObjects)
    } else {
      return notification.objects(forKey: NSUpdatedObjectsKey)
    }
  }

  /// Returns a `Set`of objects that were marked for deletion during the previous event.
  public var deletedObjects: Set<NSManagedObject> {
    if #available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, macOS 11, *) {
      return notification.objects(forKey: .deletedObjects)
    } else {
      return notification.objects(forKey: NSDeletedObjectsKey)
    }
  }

  /// A `Set` of objects that were refreshed but were not dirtied in the scope of this context.
  /// - Note: It can be populated only for `NSManagedObjectContextObjectsDidChange` notifications.
  public var refreshedObjects: Set<NSManagedObject> {
    if #available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, macOS 11, *) {
      return notification.objects(forKey: .refreshedObjects)
    } else {
      return notification.objects(forKey: NSRefreshedObjectsKey)
    }
  }

  /// A `Set` of objects that were invalidated.
  /// - Note: It can be populated only for `NSManagedObjectContextObjectsDidChange` notifications.
  public var invalidatedObjects: Set<NSManagedObject> {
    if #available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, macOS 11, *) {
      return notification.objects(forKey: .invalidatedObjects)
    } else {
      return notification.objects(forKey: NSInvalidatedObjectsKey)
    }
  }

  /// When all the object in the context have been invalidated, returns a `Set` containing all the invalidated objects' NSManagedObjectID.
  /// - Note: It can be populated only for `NSManagedObjectContextObjectsDidChange` notifications.
  public var invalidatedAllObjects: Set<NSManagedObjectID> {
    if #available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, macOS 11, *) {
      return notification.objectIDs(forKey: .invalidatedAllObjects)
    } else {
      return notification.objectIDs(forKey: NSInvalidatedAllObjectsKey)
    }
  }

  public init(notification: Notification) {
    assert(notification.name == Self.notificationName)
    self.notification = notification
  }
}

// MARK: - Did Save IDs

@available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
public struct ManagedObjectContextDidSaveObjectIDs {
  /// Notification name.
  public static let notificationName: Notification.Name = NSManagedObjectContext.didSaveObjectIDsNotification

  /// Underlying notification object.
  public let notification: Notification

  /// `NSManagedObjectContext` associated with the notification.
  public var managedObjectContext: NSManagedObjectContext {
    guard let context = notification.managedObjectContext else {
      fatalError("A NSManagedObjectContext.didSaveObjectIDsNotification must have a NSManagedObjectContext object.")
    }
    return context
  }

  /// Returns a `Set` of object IDs that were inserted into the context.
  public var insertedObjectIDs: Set<NSManagedObjectID> {
    notification.objectIDs(forKey: .insertedObjectIDs)
  }

  /// Returns a `Set` of object IDs that were updated.
  public var updatedObjectIDs: Set<NSManagedObjectID> {
    notification.objectIDs(forKey: .updatedObjectIDs)
  }

  /// Returns a `Set`of object IDs that were marked for deletion during the previous event.
  public var deletedObjectIDs: Set<NSManagedObjectID> {
    notification.objectIDs(forKey: .deletedObjectIDs)
  }

  public init(notification: Notification) {
    assert(notification.name == Self.notificationName)
    self.notification = notification
  }
}

// MARK: - Did Merge IDs

@available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
public struct ManagedObjectContextDidMergeChangesObjectIDs {
  /// Notification name.
  public static let notificationName: Notification.Name = NSManagedObjectContext.didMergeChangesObjectIDsNotification

  /// Underlying notification object.
  public let notification: Notification

  /// `NSManagedObjectContext` associated with the notification.
  public var managedObjectContext: NSManagedObjectContext {
    guard let context = notification.managedObjectContext else {
      fatalError("A NSManagedObjectContext.didMergeChangesObjectIDsNotification must have a NSManagedObjectContext object.")
    }
    return context
  }

  /// Returns a `Set` of object IDs that were inserted into the context.
  public var insertedObjectIDs: Set<NSManagedObjectID> {
    notification.objectIDs(forKey: .insertedObjectIDs)
  }

  /// Returns a `Set` of object IDs that were updated.
  public var updatedObjectIDs: Set<NSManagedObjectID> {
    notification.objectIDs(forKey: .updatedObjectIDs)
  }

  /// Returns a `Set`of object IDs that were marked for deletion during the previous event.
  public var deletedObjectIDs: Set<NSManagedObjectID> {
    notification.objectIDs(forKey: .deletedObjectIDs)
  }

  /// A `Set` of objects that were refreshed but were not dirtied in the scope of this context.
  public var refreshedObjectIDs: Set<NSManagedObjectID> {
    notification.objectIDs(forKey: .refreshedObjectIDs)
  }

  /// A `Set` of object IDs that were invalidated.
  public var invalidatedObjectIDs: Set<NSManagedObjectID> {
    notification.objectIDs(forKey: .invalidatedObjectIDs)
  }

  public init(notification: Notification) {
    assert(notification.name == Self.notificationName)
    self.notification = notification
  }
}

// MARK: - PersistentStore Remote Change

public struct PersistentStoreRemoteChange {
  /// Notification name.
  public static let notificationName: Notification.Name = .NSPersistentStoreRemoteChange

  /// Underlying notification object.
  public let notification: Notification

  /// The `NSPersistentHistoryToken` associated to the change operation.
  /// -Note: It's optional because `NSPersistentHistoryTrackingKey` should be enabled.
  public var historyToken: NSPersistentHistoryToken? {
    return notification.userInfo?[NSPersistentHistoryTokenKey] as? NSPersistentHistoryToken
  }

  /// The changed store URL.
  public var storeURL: URL {
    guard let url = notification.userInfo?[NSPersistentStoreURLKey] as? URL else {
      fatalError("NSPersistentStoreRemoteChange always contains the NSPersistentStore URL.")
    }
    return url
  }

  public init(notification: Notification) {
    assert(notification.name == Self.notificationName)
    self.notification = notification
  }
}
