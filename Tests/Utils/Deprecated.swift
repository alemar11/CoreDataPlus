// CoreDataPlus

import CoreData

extension NSFetchRequestResult where Self: NSManagedObject {
  // MARK: - First

  /// Tries to find the first existing object in the context (memory) matching a predicate.
  /// If it doesn’t find a matching materialized object in the context, tries to load it using a fetch request (if multiple objects are found, returns the **first** one).
  ///
  /// - Parameters:
  ///   - context: Searched context.
  ///   - predicate: Matching predicate.
  /// - Returns: The first materialized matching object (if any).
  /// - Throws: It throws an error in cases of failure.
  public static func materializedObjectOrFetch(in context: NSManagedObjectContext, where predicate: NSPredicate) throws -> Self? {
    // first we should fetch an existing object in the context as a performance optimization
    guard let object = materializedObject(in: context, where: predicate) else {
      // if it's not in memory, we should execute a fetch to see if it exists
      // NSFetchRequest always accesses the underlying persistent stores to retrieve the latest results.
      return try fetchOne(in: context, where: predicate)
    }
    return object
  }

  /// Attempts to find an object matching a predicate or creates a new one and configures it (if multiple objects are found, configures the **first** one).
  ///
  /// For uniqueness, use `findUniqueOrCreate(in:where:with) instead.
  /// - Note: It searches for a matching materialized object in the given context before accessing the underlying persistent stores.
  ///
  /// - Parameters:
  ///   - context: Searched context.
  ///   - predicate: Matching predicate.
  ///   - configuration: Configuration closure called **only** when creating a new object.
  /// - Returns: A matching object or a configured new one.
  /// - Throws: It throws an error in cases of failure.
  public static func findOneOrCreate(in context: NSManagedObjectContext, where predicate: NSPredicate, with configuration: (Self) -> Void) throws -> Self {
    guard let object = try materializedObjectOrFetch(in: context, where: predicate) else {
      let newObject = Self(context: context)
      configuration(newObject)
      return newObject
    }
    return object
  }

  // MARK: - Unique

  /// Attempts to find an unique object matching a predicate or creates a new one and configures it;
  /// if uniqueness is not guaranted (more than one object matching the predicate) a fatal error will occour.
  ///
  /// If uniqueness is not relevant, use `findOneOrCreate(in:where:with) instead.
  /// - Note: it always accesses the underlying persistent stores to retrieve the latest results.
  ///
  /// - Parameters:
  ///   - context: Searched context.
  ///   - predicate: Matching predicate.
  ///   - affectedStores: An array of persistent stores specified for the fetch request.
  ///   - assignedStore: A persistent store in which the newly inserted object will be saved.
  ///   - configuration: Configuration closure called **only** when creating a new object.
  /// - Returns: A matching object or a configured new one.
  /// - Throws: It throws an error in cases of failure.
  public static func findUniqueOrCreate(in context: NSManagedObjectContext,
                                        where predicate: NSPredicate,
                                        affectedStores: [NSPersistentStore]? = nil,
                                        assignedStore: NSPersistentStore? = nil,
                                        with configuration: (Self) -> Void) throws -> Self {
    let uniqueObject = try fetchUnique(in: context, where: predicate, affectedStores: affectedStores)
    guard let object = uniqueObject else {
      let newObject = Self(context: context)
      configuration(newObject)
      if let store = assignedStore {
        context.assign(newObject, to: store)
      }
      return newObject
    }
    return object
  }
}
