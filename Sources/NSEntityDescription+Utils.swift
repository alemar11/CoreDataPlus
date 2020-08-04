// CoreDataPlus

import CoreData

extension NSEntityDescription {
  /// **CoreDataPlus**
  ///
  /// Returns the topmost ancestor entity.
  var topMostEntity: NSEntityDescription {
    return hierarchyEntities().last ?? self
  }

  /// **CoreDataPlus**
  ///
  /// Returns a collection with the entire super-entity hierarchy of `self`.
  internal func hierarchyEntities() -> [NSEntityDescription] {
    var entities = [self]
    var currentSuperEntity = superentity

    while let entity = currentSuperEntity {
      if !entities.contains(entity) {
        entities.append(entity)
      }
      currentSuperEntity = entity.superentity
    }

    return entities
  }

  /// **CoreDataPlus**
  ///
  /// Returns the common ancestor entity (if any) between `self` and a given `entity.`
  ///
  /// - Parameter entity: the entity to evaluate
  /// - Returns: Returns the common ancestor entity (if any).
  internal func commonEntityAncestor(with entity: NSEntityDescription) -> NSEntityDescription? {
    guard self != entity else { return entity }

    let selfHierarchy = Set(hierarchyEntities())
    let entityHirarchy = Set(entity.hierarchyEntities())
    let intersection = selfHierarchy.intersection(entityHirarchy)

    guard !intersection.isEmpty else { return nil }

    if intersection.contains(self) { return self }

    return entity
  }
}
