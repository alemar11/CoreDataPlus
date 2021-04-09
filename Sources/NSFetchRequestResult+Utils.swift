// CoreDataPlus

import CoreData

extension NSFetchRequestResult where Self: NSManagedObject {
  /// Performs the given block in the right thread for the `NSManagedObject`'s managedObjectContext.
  ///
  /// - Parameter block: The closure to be performed.
  /// `block` accepts the current NSManagedObject as its argument and returns a value of the same or different type.
  /// - Throws: It throws an error in cases of failure.
  public func safeAccess<T>(_ block: (Self) throws -> T) rethrows -> T {
    guard let context = managedObjectContext else { fatalError("\(self) doesn't have a managedObjectContext.") }

    return try context.performAndWaitResult { _ -> T in
      return try block(self)
    }
  }
}
