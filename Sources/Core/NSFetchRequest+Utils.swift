// CoreDataPlus

import CoreData

extension NSFetchRequest {
  /// **CoreDataPlus**
  ///
  /// Creates a NSFetchRequest.
  ///
  /// - parameter entity:    Core Data entity description.
  /// - parameter predicate: Fetch request predicate.
  /// - parameter batchSize: Breaks the result set into batches.
  ///
  /// - Returns: a `new` NSFetchRequest.
  @objc
  public convenience init(entity: NSEntityDescription, predicate: NSPredicate? = nil, batchSize: Int = 0) {
    self.init()
    self.entity = entity
    self.predicate = predicate
    self.fetchBatchSize = batchSize
  }

  /// **CoreDataPlus**
  ///
  /// - Parameter predicate: A NSPredicate object.
  /// Associates to `self` a `new` compound NSPredicate formed by **AND**-ing the current predicate with a given `predicate`.
  @objc
  public func andPredicate(_ predicate: NSPredicate) {
    guard let currentPredicate = self.predicate else {
      self.predicate = predicate
      return
    }
    self.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [currentPredicate, predicate])
  }

  /// **CoreDataPlus**
  ///
  /// - Parameter predicate: A NSPredicate object.
  /// Associates to `self` a `new` compound NSPredicate formed by **OR**-ing the current predicate with a given `predicate`.
  @objc
  public func orPredicate(_ predicate: NSPredicate) {
    guard let currentPredicate = self.predicate else {
      self.predicate = predicate
      return
    }
    self.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [currentPredicate, predicate])
  }

  /// **CoreDataPlus**
  ///
  /// - Parameter descriptors: An array of NSSortDescriptor objects.
  /// Appends to the current sort descriptors an array of `descriptors`.
  @objc
  public func addSortDescriptors(_ descriptors: [NSSortDescriptor]) {
    if self.sortDescriptors != nil {
      self.sortDescriptors?.append(contentsOf: descriptors)
    } else {
      self.sortDescriptors = descriptors
    }
  }
}
