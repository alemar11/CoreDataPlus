// CoreDataPlus

import CoreData
import Foundation

extension NSSet {
  /// Specifies that all the `NSManagedObject` objects (with a `NSManangedObjectContext`) should be removed from its persistent store when changes are committed.
  public func deleteManagedObjects() {
    for object in self.allObjects {
      if let managedObject = object as? NSManagedObject, managedObject.managedObjectContext != nil {
        managedObject.safeAccess {
          $0.delete()
        }
      }
    }
  }

  /// **CoreDataPlus**
  ///
  /// Materializes all the faulted objects in one batch, executing a single fetch request.
  /// - Throws: It throws an error in cases of failure.
  /// - Note: Materializing all the objects in one batch is faster than triggering the fault for each object on its own.
  public func materializeFaultedManagedObjects() throws {
    guard self.count > 0 else { return }

    let managedObjects = self.compactMap { $0 as? NSManagedObject }
    try managedObjects.materializeFaults()
  }
}
