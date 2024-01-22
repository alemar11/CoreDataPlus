// CoreDataPlus

import CoreData
import Foundation

extension Notification {
  func objects(forKey key: String) -> Set<NSManagedObject> {
    userInfo?[key] as? Set<NSManagedObject> ?? Set()
  }

  func objects(forKey key: NSManagedObjectContext.NotificationKey) -> Set<NSManagedObject> {
    userInfo?[key.rawValue] as? Set<NSManagedObject> ?? Set()
  }

  func objectIDs(forKey key: String) -> Set<NSManagedObjectID> {
    if let objectIDs = userInfo?[key] as? Set<NSManagedObjectID> {
      return objectIDs
    } else if let objectIDs = userInfo?[key] as? [NSManagedObjectID] {
      return Set(objectIDs) // Did Change Notification
    }
    return Set()
  }

  func objectIDs(forKey key: NSManagedObjectContext.NotificationKey) -> Set<NSManagedObjectID> {
    if let objectIDs = userInfo?[key.rawValue] as? Set<NSManagedObjectID> {
      return objectIDs // Did Save ObjectIDs Notification
    } else if let objectIDs = userInfo?[key.rawValue] as? [NSManagedObjectID] {
      return Set(objectIDs) // Did Change Notification
    }
    return Set()
  }

  var managedObjectContext: NSManagedObjectContext? {
    object as? NSManagedObjectContext
  }
}
