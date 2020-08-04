import CoreData

extension NSBatchUpdateResult {
  /// **CoreDataPlus**
  ///
  /// Returns a dictionary containig all the updated `NSManagedObjectID` instances ready to be passed to `NSManagedObjectContext.mergeChanges(fromRemoteContextSave:into:)`.
  public var changes: [String: [NSManagedObjectID]]? {
    guard let updates = updates else { return nil }

    return [NSUpdatedObjectsKey: updates]
  }

  /// **CoreDataPlus**
  ///
  /// Returns all the updated objects `NSManagedObjectID`.
  /// - Note: Make sure the resultType of the `NSBatchUpdateResult` is set to `NSBatchUpdateRequestResultType.updatedObjectIDsResultType` before the request is executed otherwise the value is nil.
  public var updates: [NSManagedObjectID]? {
    switch resultType {
    case .statusOnlyResultType, .updatedObjectsCountResultType:
      return nil

    case .updatedObjectIDsResultType:
      guard let objectIDs = result as? [NSManagedObjectID] else { return nil }
      return objectIDs

    @unknown default:
      return nil
    }
  }

  /// **CoreDataPlus**
  ///
  /// Returns the number of updated objcts.
  /// - Note: Make sure the resultType of the `NSBatchUpdateResult` is set to `NSBatchUpdateRequestResultType.updatedObjectsCountResultType` before the request is executed otherwise the value is nil.
  public var count: Int? {
    switch resultType {
    case .statusOnlyResultType, .updatedObjectIDsResultType:
      return nil

    case .updatedObjectsCountResultType:
      return result as? Int

    @unknown default:
      return nil
    }
  }

  /// **CoreDataPlus**
  ///
  /// Returns `true` if the batch update operation has been completed successfully.
  /// - Note: Make sure the resultType of the `NSBatchUpdateResult` is set to `NSBatchUpdateRequestResultType.statusOnlyResultType` before the request is executed otherwise the value is nil.
  public var status: Bool? {
    switch resultType {
    case .updatedObjectsCountResultType, .updatedObjectIDsResultType:
      return nil

    case .statusOnlyResultType:
      return result as? Bool

    @unknown default:
      return nil
    }
  }
}
