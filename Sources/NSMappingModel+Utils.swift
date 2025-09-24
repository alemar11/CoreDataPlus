// CoreDataPlus

import CoreData

extension NSMappingModel {
  /// Whether or not the mapping model is inferred.
  public var isInferred: Bool {
    entityMappings.allSatisfy { $0.isInferred }
  }
}

extension NSEntityMapping {
  /// Whether or not the mapping entity is inferred.
  public var isInferred: Bool {
    // An inferred entity mapping name starts with IEM (i.e. IEM_Add, IEM_Transform, IEM_Copy).
    // AFAIK it's the only way to detect at runtime an inferred mapping.
    name.starts(with: "IEM")
  }
}
