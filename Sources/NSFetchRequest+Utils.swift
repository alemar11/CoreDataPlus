// CoreDataPlus

import CoreData

extension NSFetchRequest {
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
