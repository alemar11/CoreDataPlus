// CoreDataPlus

import CoreData

// MARK: - NSFetchRequestResult

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
  @available(*, deprecated, message: "Deprecated.")
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
  @available(*, deprecated, message: "Deprecated.")
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

// MARK: - NSManagedObjectContext

extension NSManagedObjectContext {
  /// Asynchronously performs changes and then saves them.
  ///
  /// - Parameters:
  ///   - changes: Changes to be applied in the current context before the saving operation. If they fail throwing an execption, the context will be reset.
  ///   - completion: Block executed (on the context’s queue.) at the end of the saving operation.
  @available(*, deprecated, message: "Deprecated.")
  public final func performSave(after changes: @escaping (NSManagedObjectContext) throws -> Void, completion: ( (NSError?) -> Void )? = nil ) {
    // https://stackoverflow.com/questions/37837979/using-weak-strong-self-usage-in-block-core-data-swift
    // `perform` executes the block and then releases it.
    // In Swift terms it is @noescape (and in the future it may be marked that way and you won't need to use self. in noescape closures).
    // Until the block executes, self cannot be deallocated, but after the block executes, the cycle is immediately broken.
    perform {
      var internalError: NSError?
      do {
        try changes(self)
        // TODO
        // add an option flag to decide whether or not a context can be saved if only transient properties are changed
        // in that case hasPersistentChanges should be used instead of hasChanges
        try self.saveIfNeeded()
      } catch {
        internalError = error as NSError
      }
      completion?(internalError)
    }
  }
  
  /// Synchronously performs changes and then saves them: if the changes fail throwing an execption, the context will be reset.
  ///
  /// - Throws: It throws an error in cases of failure (while applying changes or saving).
  @available(*, deprecated, message: "Deprecated.")
  public final func performSaveAndWait(after changes: (NSManagedObjectContext) throws -> Void) throws {
    // swiftlint:disable:next identifier_name
    try withoutActuallyEscaping(changes) { _changes in
      var internalError: NSError?
      performAndWait {
        do {
          try _changes(self)
          try saveIfNeeded()
        } catch {
          internalError = error as NSError
        }
      }
      
      if let error = internalError { throw error }
    }
  }
  
  /// Saves the `NSManagedObjectContext` up to the last parent `NSManagedObjectContext`.
  @available(*, deprecated, message: "Deprecated.")
  internal final func performSaveUpToTheLastParentContextAndWait() throws {
    var parentContext: NSManagedObjectContext? = self
    
    while parentContext != nil {
      var saveError: Error?
      parentContext!.performAndWait {
        do {
          try parentContext!.saveIfNeeded()
        } catch {
          saveError = error
        }
      }
      parentContext = parentContext!.parent
      
      if let error = saveError {
        throw error
      }
    }
  }
}
