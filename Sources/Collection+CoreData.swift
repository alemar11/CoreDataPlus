// CoreDataPlus

import CoreData

// MARK: - NSManagedObject

extension Collection where Element: NSManagedObject {
  /// Specifies that all the `NSManagedObject` objects (with a `NSManangedObjectContext`) should be removed from its persistent store when changes are committed.
  public func deleteManagedObjects() {
    let managedObjectsWithtContext = self.filter { $0.managedObjectContext != nil }
    for object in managedObjectsWithtContext {
      object.safeAccess {
        $0.delete()
      }
    }
  }

  /// **CoreDataPlus**
  ///
  /// Materializes all the faulted objects in one batch, executing a single fetch request.
  /// Since this method is defined for a Collection of `NSManagedObject`, it does extra work to materialize all the objects; for this reason it's not optimized for performance.
  ///
  /// - Throws: It throws an error in cases of failure.
  /// - Note: Materializing all the objects in one batch is faster than triggering the fault for each object on its own.
  public func materializeFaults() throws {
    guard !self.isEmpty else { return }

    let faults = self.filter { $0.isFault }
    guard !faults.isEmpty else { return }

    let faultedObjectsByContext = Dictionary(grouping: faults) { $0.managedObjectContext }

    for (context, objects) in faultedObjectsByContext where !objects.isEmpty {
      // objects without context can trigger their fault one by one
      guard let context = context else {
        // important bits
        objects.forEach { $0.materialize() }
        continue
      }

      // objects not yet saved can trigger their fault one by one
      let temporaryObjects = objects.filter { $0.objectID.isTemporaryID }
      if !temporaryObjects.isEmpty {
        temporaryObjects.forEach { $0.materialize() }
      }

      // avoid multiple fetches for subclass entities.
      let entities = objects.entities().entitiesKeepingOnlyCommonEntityAncestors()

      for entity in entities {
        // important bits
        // about batch faulting:
        // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/Performance.html
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entity
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "self IN %@", faults)

        try context.performAndWait { try $0.fetch(request) }
      }
    }
  }

  /// **CoreDataPlus**
  ///
  /// Returns all the different `NSEntityDescription` defined in the collection.
  public func entities() -> Set<NSEntityDescription> {
    return Set(self.map { $0.entity })
  }
}

// MARK: - NSEntityDescription

extension Collection where Element: NSEntityDescription {
  /// **CoreDataPlus**
  ///
  /// Returns a collection of `NSEntityDescription` with only the commong entity ancestors.
  internal func entitiesKeepingOnlyCommonEntityAncestors() -> Set<NSEntityDescription> {
    let grouped = Dictionary(grouping: self) { return $0.topMostEntity }
    var result = [NSEntityDescription]()

    grouped.forEach { _, entities in
      let set = Set(entities)
      let test = set.reduce([]) { (result, entity) -> [NSEntityDescription] in
        var newResult = result
        guard !newResult.isEmpty else { return [entity] }

        for (index, entityResult) in result.enumerated() {
          if let ancestor = entityResult.commonEntityAncestor(with: entity) {
            if !newResult.contains(ancestor) {
              newResult.remove(at: index)
              newResult.append(ancestor)
            }
          } else { // this condition should be never verified
            newResult.append(entity)
          }
        }

        return newResult
      }

      result.append(contentsOf: test)
    }

    return Set(result)
  }
}
