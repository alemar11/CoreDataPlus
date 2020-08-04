// CoreDataPlus

import CoreData

private let markedForDeletionKey = "markedForDeletionAsOf"

/// **CoreDataPlus**
///
/// Objects adopting the `DelayedDeletable` support *two-step* deletion.
public protocol DelayedDeletable: class {
  /// **CoreDataPlus**
  ///
  /// Protocol `DelayedDeletable`.
  ///
  /// Checks whether or not the managed object’s `markedForDeletion` property has unsaved changes.
  var hasChangedForDelayedDeletion: Bool { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `DelayedDeletable`.
  ///
  /// This object can be deleted starting from this particular date.
  var markedForDeletionAsOf: Date? { get set }

  /// **CoreDataPlus**
  ///
  /// Protocol `DelayedDeletable`.
  ///
  /// Marks an object to be deleted at a later point in time.
  func markForDelayedDeletion()
}

// MARK: - DelayedDeletable Extension

extension DelayedDeletable where Self: NSManagedObject {
  /// **CoreDataPlus**
  ///
  /// Protocol `DelayedDeletable`.
  ///
  /// Predicate to filter for objects that haven’t a deletion date.
  public static var notMarkedForLocalDeletionPredicate: NSPredicate {
    return NSPredicate(format: "%K == NULL", markedForDeletionKey)
  }

  /// **CoreDataPlus**
  ///
  /// Protocol `DelayedDeletable`.
  ///
  /// Predicate to filter for objects that have a deletion date.
  public static var markedForLocalDeletionPredicate: NSPredicate {
    return NSPredicate(format: "%K != NULL", markedForDeletionKey)
  }
}

// MARK: - NSManagedObject

extension DelayedDeletable where Self: NSManagedObject {
  /// **CoreDataPlus**
  ///
  /// Protocol `DelayedDeletable`.
  ///
  /// Returns true if `self` has been marked for deletion.
  public var hasChangedForDelayedDeletion: Bool {
    return changedValue(forKey: markedForDeletionKey) as? Date != nil
  }

  /// **CoreDataPlus**
  ///
  /// Marks an object to be deleted at a later point in time (if not already marked).
  /// An object marked for local deletion will no longer match the `notMarkedForDeletionPredicate`.
  public func markForDelayedDeletion() {
    guard markedForDeletionAsOf == nil else { return }

    markedForDeletionAsOf = Date()
  }
}

// MARK: - Batch Delete

extension NSFetchRequestResult where Self: NSManagedObject & DelayedDeletable {
  // swiftlint:disable line_length

  /// **CoreDataPlus**
  ///
  /// Makes a batch delete operation for object conforming to `DelayedDeletable` older than the `cutOffDate` date.
  ///
  /// - Parameters:
  ///   - context: The NSManagedObjectContext where is executed the batch delete request.
  ///   - cutOffDate: Objects marked for local deletion more than this time (in seconds) ago will get permanently deleted (default: 2 minutes).
  ///   - resultType: The type of the batch delete result (default: `NSBatchDeleteRequestResultType.resultTypeStatusOnly`).
  /// - Returns: a NSBatchDeleteResult result.
  /// - Throws: An error in cases of a batch delete operation failure.
  public static func batchDeleteObjectsMarkedForDeletion(with context: NSManagedObjectContext, olderThan cutOffDate: Date = Date(timeIntervalSinceNow: -TimeInterval(120)), resultType: NSBatchDeleteRequestResultType = .resultTypeStatusOnly) throws -> NSBatchDeleteResult {
    let predicate = NSPredicate(format: "%K <= %@", markedForDeletionKey, cutOffDate as NSDate)

    return try batchDeleteObjects(with: context, resultType: resultType, configuration: { $0.predicate = predicate })
  }
  // swiftlint:enable line_length
}
