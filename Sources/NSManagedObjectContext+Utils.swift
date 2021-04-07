// CoreDataPlus

import CoreData

extension NSManagedObjectContext {
  /// **CoreDataPlus**
  ///
  /// The persistent stores associated with the receiver (if any).
  public final var persistentStores: [NSPersistentStore] {
    return persistentStoreCoordinator?.persistentStores ?? []
  }

  /// **CoreDataPlus**
  ///
  /// Returns a dictionary that contains the metadata currently stored or to-be-stored in a given persistent store.
  public final func metaData(for store: NSPersistentStore) -> [String: Any] {
    guard let persistentStoreCoordinator = persistentStoreCoordinator else { preconditionFailure("\(self.description) doesn't have a Persistent Store Coordinator.") }

    return persistentStoreCoordinator.metadata(for: store)
  }

  /// **CoreDataPlus**
  ///
  /// Adds an `object` to the store's metadata and saves it **asynchronously**.
  ///
  /// - Parameters:
  ///   - object: Object to be added to the medata dictionary.
  ///   - key: Object key
  ///   - store: NSPersistentStore where is stored the metadata.
  ///   - handler: The completion handler called when the saving is completed.
  public final func setMetaDataObject(_ object: Any?, with key: String, for store: NSPersistentStore, completion handler: ( (Error?) -> Void )? = nil ) {
    performSave(after: { context in
      guard let persistentStoreCoordinator = context.persistentStoreCoordinator else { preconditionFailure("\(context.description) doesn't have a Persistent Store Coordinator.") }

      var metaData = persistentStoreCoordinator.metadata(for: store)
      metaData[key] = object
      persistentStoreCoordinator.setMetadata(metaData, for: store)
    }, completion: { error in
      handler?(error)
    })
  }

  /// **CoreDataPlus**
  ///
  /// Returns the entity with the specified name (if any) from the managed object model associated with the specified managed object context’s persistent store coordinator.
  public final func entity(forEntityName name: String) -> NSEntityDescription? {
    guard let persistentStoreCoordinator = persistentStoreCoordinator else { preconditionFailure("\(self.description) doesn't have a Persistent Store Coordinator.") }
    let entity = persistentStoreCoordinator.managedObjectModel.entitiesByName[name]

    return entity
  }
}

// MARK: - Fetch

extension NSManagedObjectContext {
  /// **CoreDataPlus**
  ///
  /// Returns an array of objects that meet the criteria specified by a given fetch request.
  /// - Note: When fetching data from Core Data, you don’t always know how many values you’ll be getting back.
  /// Core Data solves this problem by using a subclass of `NSArray` that will dynamically pull in data from the underlying store on demand.
  /// On the other hand, a Swift `Array` requires having every element in the array all at once, and bridging an `NSArray` to a Swift `Array` requires retrieving every single value.
  /// - Warning: **Batched requests** are supported only when returning a `NSArray`.
  /// - SeeAlso:https://developer.apple.com/forums/thread/651325)
  public final func fetchNSArray<T>(_ request: NSFetchRequest<T>) throws -> NSArray {
    // [...] Similarly for fetch requests with batching enabled, you do not want a Swift Array but instead an NSArray to avoid making an immediate copy of the future.
    // https://developer.apple.com/forums/thread/651325.
    // swiftlint:disable force_cast
    let protocolRequest = request as! NSFetchRequest<NSFetchRequestResult>
    let results = try fetch(protocolRequest) as NSArray
    return results
  }
}

// MARK: - Child Context

extension NSManagedObjectContext {
  /// **CoreDataPlus**
  ///
  /// - Returns: a `new` background `NSManagedObjectContext`.
  /// - Parameters:
  ///   - asChildContext: Specifies if this new context is a child context of the current context (default *false*).
  public final func newBackgroundContext(asChildContext isChildContext: Bool = false) -> NSManagedObjectContext {
    let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

    if isChildContext {
      context.parent = self
    } else {
      context.persistentStoreCoordinator = persistentStoreCoordinator
    }

    return context
  }
}

// MARK: - Save

extension NSManagedObjectContext {
  /// **CoreDataPlus**
  ///
  /// Returns the number of uncommitted changes (transient changes are included).
  public var changesCount: Int {
    guard hasChanges else { return 0 }
    return insertedObjects.count + deletedObjects.count + updatedObjects.count
  }

  /// **CoreDataPlus**
  ///
  /// Checks whether there are actually changes that will change the persistent store.
  /// - Note: The `hasChanges` method would return `true` for transient changes as well which can lead to false positives.
  public var hasPersistentChanges: Bool {
    guard hasChanges else { return false }
    return !insertedObjects.isEmpty || !deletedObjects.isEmpty || updatedObjects.first(where: { $0.hasPersistentChangedValues }) != nil
  }

  /// **CoreDataPlus**
  ///
  /// Returns the number of changes that will change the persistent store (transient changes are ignored).
  public var persistentChangesCount: Int {
    guard hasChanges else { return 0 }
    return insertedObjects.count + deletedObjects.count + updatedObjects.filter({ $0.hasPersistentChangedValues }).count
  }

  /// **CoreDataPlus**
  ///
  /// Asynchronously performs changes and then saves them.
  ///
  /// - Parameters:
  ///   - changes: Changes to be applied in the current context before the saving operation. If they fail throwing an execption, the context will be reset.
  ///   - completion: Block executed (on the context’s queue.) at the end of the saving operation.
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
        if self.hasChanges {
          try self.save()
        }
      } catch {
        internalError = error as NSError
      }
      completion?(internalError)
    }
  }

  /// **CoreDataPlus**
  ///
  /// Synchronously performs changes and then saves them: if the changes fail throwing an execption, the context will be reset.
  ///
  /// - Throws: It throws an error in cases of failure (while applying changes or saving).
  public final func performSaveAndWait(after changes: (NSManagedObjectContext) throws -> Void) throws {
    // swiftlint:disable:next identifier_name
    try withoutActuallyEscaping(changes) { _changes in
      var internalError: NSError?

      performAndWait {
        do {
          try _changes(self)
          if hasChanges {
            try save()
          }
        } catch {
          internalError = error as NSError
        }
      }

      if let error = internalError { throw error }
    }
  }

  /// **CoreDataPlus**
  ///
  /// Saves the `NSManagedObjectContext` if changes are present or **rollbacks** if any error occurs.
  /// - Note: The rollback removes everything from the undo stack, discards all insertions and deletions, and restores updated objects to their last committed values.
  public final func saveOrRollBack() throws {
    guard hasChanges else { return }

    do {
      try save()
    } catch {
      rollback() // rolls back the pending changes
      throw error
    }
  }

  /// **CoreDataPlus**
  ///
  /// Saves the `NSManagedObjectContext` up to the last parent `NSManagedObjectContext`.
  internal final func performSaveUpToTheLastParentContextAndWait() throws {
    var parentContext: NSManagedObjectContext? = self

    while parentContext != nil {
      var saveError: Error?

      parentContext!.performAndWait {
        guard parentContext!.hasChanges else { return }

        do {
          try parentContext!.save()
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

// MARK: - Better PerformAndWait

extension NSManagedObjectContext {
  /// **CoreDataPlus**
  ///
  /// Synchronously performs a given block on the context’s queue and returns the final result.
  /// - Throws: It throws an error in cases of failure.
  public func performAndWaitResult<T>(_ block: (NSManagedObjectContext) throws -> T) rethrows -> T {
    return try _performAndWait(function: performAndWait, execute: block, rescue: { throw $0 })
  }

  /// **CoreDataPlus**
  ///
  /// Synchronously performs a given block on the context’s queue.
  /// - Throws: It throws an error in cases of failure.
  public func performAndWait(_ block: (NSManagedObjectContext) throws -> Void) rethrows {
    try _performAndWait(function: performAndWait, execute: block, rescue: { throw $0 })
  }

  /// Helper function for convincing the type checker that the rethrows invariant holds for performAndWait.
  ///
  /// Source: https://oleb.net/blog/2018/02/performandwait/
  /// Source: https://github.com/apple/swift/blob/bb157a070ec6534e4b534456d208b03adc07704b/stdlib/public/SDK/Dispatch/Queue.swift#L228-L249
  private func _performAndWait<T>(function: (() -> Void) -> Void, execute work: (NSManagedObjectContext) throws -> T, rescue: ((Error) throws -> (T))) rethrows -> T {
    var result: T?
    var error: Error?
    // swiftlint:disable:next identifier_name
    withoutActuallyEscaping(work) { _work in
      function {
        do {
          result = try _work(self)
        } catch let catchedError {
          error = catchedError
        }
      }
    }
    if let error = error {
      return try rescue(error)
    } else {
      return result!
    }
  }
}
