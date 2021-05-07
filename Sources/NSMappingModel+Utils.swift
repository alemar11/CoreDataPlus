// CoreDataPlus

import CoreData

public extension NSMappingModel {
  /// Wheter or not the mapping model is inferred.
  var isInferred: Bool {
    entityMappings.allSatisfy { mapping in
      result && mapping.isInferred
    }
  }
}

public extension NSEntityMapping {
  /// Wheter or not the mapping entity is inferred.
  var isInferred: Bool {
    // An inferred entity mapping name starts with IEM (i.e. IEM_Add, IEM_Transform, IEM_Copy).
    // AFAIK it's the only way to detect at runtim an inferred mapping.
    name.starts(with: "IEM")
  }
}
