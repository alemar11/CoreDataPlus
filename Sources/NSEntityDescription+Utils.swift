// CoreDataPlus

import CoreData

extension NSEntityDescription {
  /// Returns the topmost ancestor entity.
  public final var topMostAncestorEntity: NSEntityDescription {
    return ancestorEntities().last ?? self
  }

  /// Returns the common ancestor entity (if any) between `self` and a given `entity.`
  ///
  /// - Parameter entity: the entity to evaluate
  /// - Returns: Returns the common ancestor entity (if any).
  public final func commonEntityAncestor(with entity: NSEntityDescription) -> NSEntityDescription? {
    guard self != entity else { return entity }

    let selfHierarchy = Set(ancestorEntities() + [self])
    let entityHirarchy = Set(entity.ancestorEntities() + [entity])
    let intersection = selfHierarchy.intersection(entityHirarchy)

    guard !intersection.isEmpty else { return nil }

    if intersection.contains(self) { return self }

    return entity
  }

  /// - Returns: Wheter or not `self` is a subentity of a given `entity`.
  /// If `recursive` is set to `true`, it will be evaluated if `self` super entities hierarchy contains the given `entity` at some point.
  public final func isSubEntity(of entity: NSEntityDescription, recursive: Bool = false) -> Bool {
    if recursive {
      return ancestorEntities().contains(entity)
    } else {
      return entity.subentities.contains(self)
    }
  }
  
  /// Returns a list with a hierarchy of all the ancestor (super) entities of `self`.
  internal final func ancestorEntities() -> [NSEntityDescription] {
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
}
