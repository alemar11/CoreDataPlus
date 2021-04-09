// CoreDataPlus

import CoreData

extension NSEntityDescription {
  /// Returns the topmost ancestor entity.
  var topMostEntity: NSEntityDescription {
    return hierarchyEntities().last ?? self
  }

  /// Returns the super entities hierarchy of `self`.
  internal func hierarchyEntities() -> [NSEntityDescription] {
    var entities = [NSEntityDescription]()
    var currentSuperEntity = superentity

    while let entity = currentSuperEntity {
      if !entities.contains(entity) {
        entities.append(entity)
      }
      currentSuperEntity = entity.superentity
    }

    return entities
  }

  /// Returns the common ancestor entity (if any) between `self` and a given `entity.`
  ///
  /// - Parameter entity: the entity to evaluate
  /// - Returns: Returns the common ancestor entity (if any).
  internal func commonEntityAncestor(with entity: NSEntityDescription) -> NSEntityDescription? {
    guard self != entity else { return entity }

    let selfHierarchy = Set(hierarchyEntities() + [self])
    let entityHirarchy = Set(entity.hierarchyEntities() + [entity])
    let intersection = selfHierarchy.intersection(entityHirarchy)

    guard !intersection.isEmpty else { return nil }

    if intersection.contains(self) { return self }

    return entity
  }

  /// - Returns: Wheter or not `self` is a subentity of a given `entity`.
  /// If `recursive` is set to `true`, it will be evaluated if `self` super entities hierarchy contains the given `entity` at some point.
  func isSubEntity(of entity: NSEntityDescription, recursive: Bool = false) -> Bool {
    if recursive {
      return hierarchyEntities().contains(entity)
    } else {
      return entity.subentities.contains(self)
    }
  }
}
