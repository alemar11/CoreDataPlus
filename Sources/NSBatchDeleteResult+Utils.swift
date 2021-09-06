// CoreDataPlus

import CoreData

extension NSBatchDeleteResult {
  /// Returns a dictionary containig all the deleted `NSManagedObjectID` instances ready to be passed to `NSManagedObjectContext.mergeChanges(fromRemoteContextSave:into:)`.
  public var changes: [String: [NSManagedObjectID]]? {
    guard let deletes = deletes else { return nil }

    return [NSDeletedObjectsKey: deletes]
  }

  /// Returns all the deleted objects `NSManagedObjectID`.
  /// - Note: Make sure the resultType of the `NSBatchDeleteRequest` is set to `NSBatchDeleteRequestResultType.resultTypeObjectIDs` before the request is executed otherwise the value is nil.
  public var deletes: [NSManagedObjectID]? {
    switch resultType {
    case .resultTypeStatusOnly, .resultTypeCount:
      return nil
    case .resultTypeObjectIDs:
      guard let objectIDs = result as? [NSManagedObjectID] else { return nil }
      return objectIDs
    @unknown default:
      return nil
    }
  }

  /// Returns the number of deleted objects.
  /// - Note: Make sure the resultType of the `NSBatchDeleteRequest` is set to `NSBatchDeleteRequestResultType.resultTypeCount` before the request is executed otherwise the value is nil.
  public var count: Int? {
    switch resultType {
    case .resultTypeStatusOnly, .resultTypeObjectIDs:
      return nil
    case .resultTypeCount:
      return result as? Int
    @unknown default:
      return nil
    }
  }

  /// Returns `true` if the batc delete operation has been completed successfully.
  /// - Note: Make sure the resultType of the `NSBatchDeleteRequest` is set to `NSBatchDeleteRequestResultType.resultTypeStatusOnly` before the request is executed otherwise the value is nil.
  public var status: Bool? {
    switch resultType {
    case .resultTypeCount, .resultTypeObjectIDs:
      return nil
    case .resultTypeStatusOnly:
      return result as? Bool
    @unknown default:
      return nil
    }
  }
}
