// CoreDataPlus

import CoreData

// MARK: NSFetchRequest

extension NSFetchRequest {
  /// - Parameter predicate: A NSPredicate object.
  /// Associates to `self` a `new` compound NSPredicate formed by **AND**-ing the current predicate with a given `predicate`.
  @available(*, deprecated, message: "Deprecated")
  @objc
  public func andPredicate(_ predicate: NSPredicate) {
    guard let currentPredicate = self.predicate else {
      self.predicate = predicate
      return
    }
    self.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [currentPredicate, predicate])
  }
  
  /// - Parameter predicate: A NSPredicate object.
  /// Associates to `self` a `new` compound NSPredicate formed by **OR**-ing the current predicate with a given `predicate`.
  @available(*, deprecated, message: "Deprecated")
  @objc
  public func orPredicate(_ predicate: NSPredicate) {
    guard let currentPredicate = self.predicate else {
      self.predicate = predicate
      return
    }
    self.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [currentPredicate, predicate])
  }
}

// MARK: NSManagedObjectContext

extension NSManagedObjectContext {
  /// The persistent stores associated with the receiver (if any).
  @available(*, deprecated, message: "Deprecated.")
  public final var persistentStores: [NSPersistentStore] {
    return persistentStoreCoordinator?.persistentStores ?? []
  }
  
  /// Returns the entity with the specified name (if any) from the managed object model associated with the specified managed object context’s persistent store coordinator.
  @available(*, deprecated, message: "Deprecated.")
  public final func entity(forEntityName name: String) -> NSEntityDescription? {
    guard let persistentStoreCoordinator = persistentStoreCoordinator else { preconditionFailure("\(self.description) doesn't have a Persistent Store Coordinator.") }
    
    let entity = persistentStoreCoordinator.managedObjectModel.entitiesByName[name]
    return entity
  }
  
  /// Saves the `NSManagedObjectContext` if changes are present or **rollbacks** if any error occurs.
  /// - Note: The rollback removes everything from the undo stack, discards all insertions and deletions, and restores updated objects to their last committed values.
  @available(*, deprecated, message: "Use saveIfNeededOrRollBack instead.")
  public final func saveOrRollBack() throws {
    try saveIfNeededOrRollBack()
  }
  
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

  /// Asynchronously merges the changes specified in a given payload.
  /// This method refreshes any objects which have been updated in the other context,
  /// faults in any newly-inserted objects, and invokes delete(_:): on those which have been deleted.
  ///
  /// - Parameters:
  ///   - payload: A `NSManagedObjectContextDidSave` payload posted by another context.
  ///   - completion: The block to be executed after the merge completes.
  @available(*, deprecated, message: "Deprecated.")
  public func performMergeChanges(from payload: ManagedObjectContextDidSaveObjects, completion: @escaping () -> Void = {}) {
    perform {
      self.mergeChanges(fromContextDidSave: payload.notification)
      completion()
    }
  }

  /// Synchronously merges the changes specified in a given payload.
  /// This method refreshes any objects which have been updated in the other context,
  /// faults in any newly-inserted objects, and invokes delete(_:): on those which have been deleted.
  ///
  /// - Parameters:
  ///   - payload: A `NSManagedObjectContextDidSave` payload posted by another context.
  ///   - completion: The block to be executed after the merge completes.
  @available(*, deprecated, message: "Deprecated.")
  public func performAndWaitMergeChanges(from payload: ManagedObjectContextDidSaveObjects) {
    performAndWait {
      self.mergeChanges(fromContextDidSave: payload.notification)
    }
  }
}
