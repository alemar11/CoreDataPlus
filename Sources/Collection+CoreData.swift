//
// CoreDataPlus
//
// Copyright © 2016-2020 Tinrobots.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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

  @available(*, deprecated, message: "Use materializeFaultedObjects() instead.")
  public func fetchFaultedObjects() throws {
    try materializeFaultedManagedObjects()
  }

  /// **CoreDataPlus**
  ///
  /// Materializes all the faulted objects in one batch, executing a single fetch request.
  /// - Throws: It throws an error in cases of failure.
  /// - Note: Materializing all the objects in one batch is faster than triggering the fault for each object on its own.
  public func materializeFaultedManagedObjects() throws {
    guard !self.isEmpty else { return }

    let faults = self.filter { $0.isFault }
    guard !faults.isEmpty else { return }

    let faultedObjectsByContext = Dictionary(grouping: faults) { $0.managedObjectContext }

    for (context, objects) in faultedObjectsByContext where !objects.isEmpty {
      // objects without context can trigger their fault one by one
      guard let context = context else {
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
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entity
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "self IN %@", faults)

        do {
          _ = try context.performAndWait { _ in
            try context.fetch(request)
          }
        } catch {
          throw NSError.fetchFailed(underlyingError: error)
        }
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
