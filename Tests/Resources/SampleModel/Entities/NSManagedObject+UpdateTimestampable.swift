// CoreDataPlus

import CoreData

private let updateTimestampKey = "updatedAt"

/// Objects adopting the `UpdateTimestampable` have an `updateAt` property.
public protocol UpdateTimestampable: AnyObject {
  var updatedAt: Date { get set }
}

extension UpdateTimestampable where Self: NSManagedObject {
  /// Protocol `UpdateTimestampable`.
  ///
  /// Refreshes the update date if and only if the object has not unsaved update date.
  /// - Parameter observingTheChange: if `true` Core Data will observe the changes for this value.
  /// - Note: If an object is flagged as deleted, the update date will be not set/refreshed.
  public func refreshUpdateDate(observingChanges: Bool = true) {
    guard !isDeleted else { return }
    guard changedValue(forKey: updateTimestampKey) == nil else { return }

    if observingChanges {
      updatedAt = Date()
    } else {
      setPrimitiveValue(Date(), forKey: updateTimestampKey)
    }
  }
}
