// CoreDataPlus

import CoreData

@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
extension NSBatchInsertResult {
  /// **CoreDataPlus**
  ///
  /// Returns a dictionary containig all the inserted `NSManagedObjectID` instances ready to be passed to `NSManagedObjectContext.mergeChanges(fromRemoteContextSave:into:)`.
  public var changes: [String: [NSManagedObjectID]]? {
    guard let inserts = inserts else { return nil }

    return [NSInsertedObjectsKey: inserts]
  }

  /// **CoreDataPlus**
  ///
  /// Returns all the inserted objects `NSManagedObjectID`.
  /// - Note: Make sure the resultType of the `NSBatchInsertResult` is set to `NSBatchInsertRequestResultType.objectIDs` before the request is executed otherwise the value is nil.
  public var inserts: [NSManagedObjectID]? {
    switch resultType {
    case .count, .statusOnly:
      return nil

    case .objectIDs:
      guard let objectIDs = result as? [NSManagedObjectID] else { return nil }
      let changes = objectIDs
      return changes

    @unknown default:
      return nil
    }
  }

  /// **CoreDataPlus**
  ///
  /// Returns the number of inserted objcts.
  /// - Note: Make sure the resultType of the `NSBatchInsertResult` is set to `NSBatchInsertRequestResultType.count` before the request is executed otherwise the value is nil.
  public var count: Int? {
    switch resultType {
    case .statusOnly, .objectIDs:
      return nil

    case .count:
      return result as? Int

    @unknown default:
      return nil
    }
  }

  /// **CoreDataPlus**
  ///
  /// Returns `true` if the batch insert operation has been completed successfully.
  /// - Note: Make sure the resultType of the `NSBatchInsertResult` is set to `NSBatchInsertRequestResultType.statusOnly` before the request is executed otherwise the value is nil.
  public var status: Bool? {
    switch resultType {
    case .count, .objectIDs:
      return nil

    case .statusOnly:
      return result as? Bool

    @unknown default:
      return nil
    }
  }
}
