// CoreDataPlus

import CoreData
import Foundation

extension NSSet {
  /// Specifies that all the `NSManagedObject` objects (with a `NSManangedObjectContext`) should be removed from its persistent store when changes are committed.
  public func deleteManagedObjects() {
    for object in self.allObjects {
      if let managedObject = object as? NSManagedObject, let context = managedObject.managedObjectContext {
        context.performAndWait {
          managedObject.delete()
        }
      }
    }
  }

  /// Materializes all the faulted objects in one batch, executing a single fetch request.
  /// Since this method is defined for a NSSet, it does extra work to materialize all the `NSManagedObject` objects (if any) in there; for this reason it's not optimized for performance.
  ///
  /// - Throws: It throws an error in cases of failure.
  /// - Note: Materializing all the objects in one batch is faster than triggering the fault for each object on its own.
  public func materializeManagedObjectFaults() throws {
    guard self.count > 0 else { return }

    let managedObjects = self.compactMap { $0 as? NSManagedObject }
    try managedObjects.materializeFaults()
  }
}

/**
 From: https://developer.apple.com/forums/thread/651325

 Set vs NSSet in Swift accessor methods

 Set in Swift is an immutable value type. We do not recommend making Core Data relationships typed this way despite the obvious convenience.
 Core Data makes heavy use of Futures, especially for relationship values. These are reference types expressed as NSSet. The concrete instance is a future subclass however.
 This lets us optimize memory and performance across your object graph.
 Declaring an accessor as Set forces an immediate copy of the entire relationship so it can be an immutable Swift Set.
 This loads the entire relationship up front and fulfills the Future all the time, immediately. You probably do not want that.

 Similarly for fetch requests with batching enabled, you do not want a Swift Array but instead an NSArray to avoid making an immediate copy of the future.
 */
