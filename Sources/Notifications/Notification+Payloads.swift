// CoreDataPlus

// Several system frameworks use Core Data internally: if you register to receive these notifications from all contexts
// (by passing nil as the object parameter to a method such as addObserver(_:selector:name:object:)),
// then you may receive unexpected notifications that are difficult to handle.

// TODO
// WWDC 2020: there should be a NSManagedObjectContext.NotificationKey.sourceContext to access the context from the userInfo
// but as of Xcode 13b5 it's not there (and the userInfo contains a _PFWeakReference for key "managedObjectContext")

import CoreData
import Foundation

// MARK: - NSManagedObjectContext

// MARK: Will Save

/// Typed payload for a Core Data *will save* notification.
public struct ManagedObjectContextWillSaveObjects {
  /// Notification name.
  public static let notificationName: Notification.Name = {
    NSManagedObjectContext.willSaveObjectsNotification
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

// MARK: Did Save

/// Typed payload for a Core Data *did save* notification.
public struct ManagedObjectContextDidSaveObjects {
  /// Notification name.
  public static let notificationName: Notification.Name = {
    NSManagedObjectContext.didSaveObjectsNotification
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
    notification.objects(forKey: .insertedObjects)
  }

  /// Returns a `Set` of objects that were updated.
  public var updatedObjects: Set<NSManagedObject> {
    notification.objects(forKey: .updatedObjects)
  }

  /// Returns a `Set`of objects that were marked for deletion during the previous event.
  public var deletedObjects: Set<NSManagedObject> {
    notification.objects(forKey: .deletedObjects)
  }

  /// The `NSPersistentHistoryToken` associated to the save operation.
  /// - Note: Optional: NSPersistentHistoryTrackingKey must be enabled.
  public var historyToken: NSPersistentHistoryToken? {
    // FB6840421 (missing documentation for "newChangeToken" key)
    notification.userInfo?["newChangeToken"] as? NSPersistentHistoryToken
  }

  /// The new `NSQueryGenerationToken` associated to the save operation.
  /// - Note: It's only available when you are using a SQLite persistent store.
  public var queryGenerationToken: NSQueryGenerationToken? {
    notification.userInfo?[NSManagedObjectContext.NotificationKey.queryGeneration.rawValue] as? NSQueryGenerationToken
  }

  public init(notification: Notification) {
    assert(notification.name == Self.notificationName)
    self.notification = notification
  }
}

extension NSManagedObjectContext {
  /// Merges the changes specified in a given payload.
  /// This method refreshes any objects which have been updated in the other context,
  /// faults in any newly-inserted objects, and invokes delete(_:): on those which have been deleted.
  ///
  /// - Parameters:
  ///   - payload: A `ManagedObjectContextDidSaveObjects` payload (a typed payload for a notification posted by another context).
  public func mergeChanges(fromContextDidSavePayload payload: ManagedObjectContextDidSaveObjects) {
    mergeChanges(fromContextDidSave: payload.notification)
  }
}

// MARK: Objects Did Change

/// Typed payload for a Core Data *objects did change* notification.
public struct ManagedObjectContextObjectsDidChange {
  /// Notification name.
  public static let notificationName: Notification.Name = {
    NSManagedObjectContext.didChangeObjectsNotification
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
    notification.objects(forKey: .insertedObjects)
  }

  /// Returns a `Set` of objects that were updated.
  public var updatedObjects: Set<NSManagedObject> {
    notification.objects(forKey: .updatedObjects)
  }

  /// Returns a `Set`of objects that were marked for deletion during the previous event.
  public var deletedObjects: Set<NSManagedObject> {
    notification.objects(forKey: .deletedObjects)
  }

  /// A `Set` of objects that were refreshed but were not dirtied in the scope of this context.
  /// - Note: It can be populated only for `NSManagedObjectContextObjectsDidChange` notifications.
  public var refreshedObjects: Set<NSManagedObject> {
    notification.objects(forKey: .refreshedObjects)
  }

  /// A `Set` of objects that were invalidated.
  /// - Note: It can be populated only for `NSManagedObjectContextObjectsDidChange` notifications.
  public var invalidatedObjects: Set<NSManagedObject> {
    notification.objects(forKey: .invalidatedObjects)
  }

  /// When all the object in the context have been invalidated, returns a `Set` containing all the invalidated objects' NSManagedObjectID.
  /// - Note: It can be populated only for `NSManagedObjectContextObjectsDidChange` notifications.
  public var invalidatedAllObjects: Set<NSManagedObjectID> {
    notification.objectIDs(forKey: .invalidatedAllObjects)
  }

  public init(notification: Notification) {
    assert(notification.name == Self.notificationName)
    self.notification = notification
  }
}

// MARK: Did Save IDs

/// Typed payload for a Core Data *object IDs did save* notification.
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

// MARK: Did Merge IDs

/// Typed payload for a Core Data *did merge changes IDs* notification.
public struct ManagedObjectContextDidMergeChangesObjectIDs {
  /// Notification name.
  public static let notificationName: Notification.Name = NSManagedObjectContext.didMergeChangesObjectIDsNotification

  /// Underlying notification object.
  public let notification: Notification

  /// `NSManagedObjectContext` associated with the notification.
  public var managedObjectContext: NSManagedObjectContext {
    guard let context = notification.managedObjectContext else {
      fatalError(
        "A NSManagedObjectContext.didMergeChangesObjectIDsNotification must have a NSManagedObjectContext object.")
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

// MARK: PersistentStore Remote Change

/// Typed payload for a Core Data *persistent store remote change* notification.
public struct PersistentStoreRemoteChange {
  /// Notification name.
  public static let notificationName: Notification.Name = .NSPersistentStoreRemoteChange

  /// Underlying notification object.
  public let notification: Notification

  /// The `NSPersistentHistoryToken` associated to the change operation.
  /// -Note: It's optional because `NSPersistentHistoryTrackingKey` should be enabled.
  public var historyToken: NSPersistentHistoryToken? {
    notification.userInfo?[NSPersistentHistoryTokenKey] as? NSPersistentHistoryToken
  }

  /// The changed store URL.
  public var storeURL: URL {
    guard let url = notification.userInfo?[NSPersistentStoreURLKey] as? URL else {
      fatalError("NSPersistentStoreRemoteChange always contains the NSPersistentStore URL.")
    }
    return url
  }

  /// The store UUID.
  public var storeUUID: UUID {
    guard let uuid = notification.userInfo?[NSStoreUUIDKey] as? String else {
      fatalError("NSPersistentStoreRemoteChange always contains the NSPersistentStore UUID.")
    }
    return UUID(uuidString: uuid)!
  }

  public init(notification: Notification) {
    assert(notification.name == Self.notificationName)
    self.notification = notification
  }
}

// MARK: - NSPersistentStoreCoordinator

// MARK: Will Change

/// Typed payload for a Core Data *persistent store coordinator will change* notification.
public struct PersistentStoreCoordinatorStoresWillChange {
  /// Notification name.
  public static let notificationName = Notification.Name.NSPersistentStoreCoordinatorStoresWillChange

  /// Underlying notification object.
  public let notification: Notification

  /// List of added stores.
  public var addedStores: [NSPersistentStore] {
    notification.userInfo?[NSAddedPersistentStoresKey] as? [NSPersistentStore] ?? []
  }

  /// List of removed stores.
  public var removedStores: [NSPersistentStore] {
    notification.userInfo?[NSRemovedPersistentStoresKey] as? [NSPersistentStore] ?? []
  }

  //  public var ubiquitousTransitionType: NSPersistentStoreUbiquitousTransitionType {
  //    guard
  //      let typeValue = notification.userInfo?[NSPersistentStoreUbiquitousTransitionTypeKey] as? UInt,
  //      let type = NSPersistentStoreUbiquitousTransitionType.init(rawValue: typeValue)
  //    else {
  //      fatalError("A Notification.Name.NSPersistentStoreCoordinatorStoresWillChange must have a NSPersistentStoreUbiquitousTransitionType value.")
  //    }
  //    return type
  //  }

  public init(notification: Notification) {
    assert(notification.name == Self.notificationName)
    self.notification = notification
  }

  // This notification is sent (AFAIK) only for deprecated CoreData options supporting iCloud ubiquity.
  //
  // description.setOption("MY_NAME" as NSString, forKey: NSPersistentStoreUbiquitousContentNameKey)
  // description.setOption("MY_UBIQUITY_CONTAINER_IDENTIFIER" as NSString, forKey: NSPersistentStoreUbiquitousContainerIdentifierKey)
  //
  // swiftlint:disable:next line_length
  // https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/UsingCoreDataWithiCloudPG/UsingSQLiteStoragewithiCloud/UsingSQLiteStoragewithiCloud.html#//apple_ref/doc/uid/TP40013491-CH3
  //
  // Store the sqlite database in a folder defined with this API won't trigger the notification:
  // FileManager.default.url(forUbiquityContainerIdentifier: "MY_UBIQUITY_CONTAINER_IDENTIFIER")
}

// MARK: Did Change

/// Typed payload for a Core Data *persistent store coordinator did change* notification.
public struct PersistentStoreCoordinatorStoresDidChange {
  public struct UUIDChangedStore {
    public let oldStore: NSPersistentStore
    public let newStore: NSPersistentStore
    public let migratedIDs: [NSManagedObjectID]

    fileprivate init(changedStore: NSArray) {
      // swiftlint:disable:next force_cast
      self.oldStore = changedStore[0] as! NSPersistentStore
      // swiftlint:disable:next force_cast
      self.newStore = changedStore[1] as! NSPersistentStore
      // When migration happens, the array contains a third object (at index 2) that is an array
      // containing the new objectIDs for all the migrated objects.
      self.migratedIDs = changedStore[2] as? [NSManagedObjectID] ?? []
    }
  }

  /// Notification name.
  public static let notificationName = Notification.Name.NSPersistentStoreCoordinatorStoresDidChange

  /// Underlying notification object.
  public let notification: Notification

  /// List of added stores.
  public var addedStores: [NSPersistentStore] {
    notification.userInfo?[NSAddedPersistentStoresKey] as? [NSPersistentStore] ?? []
  }

  /// List of removed stores.
  public var removedStores: [NSPersistentStore] {
    notification.userInfo?[NSRemovedPersistentStoresKey] as? [NSPersistentStore] ?? []
  }

  /// Store whose UUID changed.
  public var uuidChangedStore: UUIDChangedStore? {
    guard let uuidChangedStore = notification.userInfo?[NSUUIDChangedPersistentStoresKey] as? NSArray else {
      return nil
    }
    return UUIDChangedStore(changedStore: uuidChangedStore)
  }

  public init(notification: Notification) {
    assert(notification.name == Self.notificationName)
    self.notification = notification
  }
}

// MARK: Will Remove

/// Typed payload for a Core Data *persistent store coordinator will remove* notification.
public struct PersistentStoreCoordinatorWillRemoveStore {
  /// Notification name.
  public static let notificationName = Notification.Name.NSPersistentStoreCoordinatorWillRemoveStore

  /// Underlying notification object.
  public let notification: Notification

  /// The persistent store coordinator that will be removed.
  public var store: NSPersistentStore {
    guard let store = notification.object as? NSPersistentStore else {
      fatalError(
        "A Notification.Name.NSPersistentStoreCoordinatorWillRemoveStore must have a NSPersistentStore object.")
    }
    return store
  }

  public init(notification: Notification) {
    assert(notification.name == Self.notificationName)
    self.notification = notification
  }
}
