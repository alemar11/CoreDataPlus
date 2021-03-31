// CoreDataPlus

import CoreData
import Foundation

extension Notification {
  func objects(forKey key: String) -> Set<NSManagedObject> {
    return userInfo?[key] as? Set<NSManagedObject> ?? Set()
  }

  @available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
  func objects(forKey key: NSManagedObjectContext.NotificationKey) -> Set<NSManagedObject> {
    return userInfo?[key.rawValue] as? Set<NSManagedObject> ?? Set()
  }

  func objectIDs(forKey key: String) -> Set<NSManagedObjectID> {
    if let objectIDs = userInfo?[key] as? Set<NSManagedObjectID> {
      return objectIDs
    } else if let objectIDs = userInfo?[key] as? [NSManagedObjectID] {
      return Set(objectIDs) // Did Change Notification
    }
    return Set()
  }

  @available(iOS 14.0, iOSApplicationExtension 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
  func objectIDs(forKey key: NSManagedObjectContext.NotificationKey) -> Set<NSManagedObjectID> {
    if let objectIDs = userInfo?[key.rawValue] as? Set<NSManagedObjectID> {
      return objectIDs // Did Save ObjectIDs Notification
    } else if let objectIDs = userInfo?[key.rawValue] as? [NSManagedObjectID] {
      return Set(objectIDs) // Did Change Notification
    }
    return Set()
  }

  var managedObjectContext: NSManagedObjectContext? {
    return object as? NSManagedObjectContext
  }
}
