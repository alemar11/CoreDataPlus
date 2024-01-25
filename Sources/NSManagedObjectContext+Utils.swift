// CoreDataPlus

import CoreData

// MARK: - Fetch

extension NSManagedObjectContext {
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
    // swiftlint:enable force_cast
    let results = try fetch(protocolRequest) as NSArray
    return results
  }
}

// MARK: - Child Context

extension NSManagedObjectContext {
  /// Returns a `new` background `NSManagedObjectContext`.
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

  /// Returns a `new` child `NSManagedObjectContext`.
  /// - Parameters:
  ///   - concurrencyType: Specifies the concurrency pattern used by this child context (defaults to the parent type).
  public final func newChildContext(concurrencyType: NSManagedObjectContextConcurrencyType? = nil) -> NSManagedObjectContext {
    let type = concurrencyType ?? self.concurrencyType
    let context = NSManagedObjectContext(concurrencyType: type)
    context.parent = self
    return context
  }
}

// MARK: - Save

extension NSManagedObjectContext {
  /// Returns the number of uncommitted changes (transient changes are included).
  public var changesCount: Int {
    guard hasChanges else { return 0 }
    return insertedObjects.count + deletedObjects.count + updatedObjects.count
  }

  /// Checks whether there are actually changes that will change the persistent store.
  /// - Note: The `hasChanges` method would return `true` for transient changes as well which can lead to false positives.
  public var hasPersistentChanges: Bool {
    guard hasChanges else { return false }
    return !insertedObjects.isEmpty || !deletedObjects.isEmpty || updatedObjects.first(where: { $0.hasPersistentChangedValues }) != nil
  }

  /// Returns the number of changes that will change the persistent store (transient changes are ignored).
  public var persistentChangesCount: Int {
    guard hasChanges else { return 0 }
    return insertedObjects.count + deletedObjects.count + updatedObjects.filter({ $0.hasPersistentChangedValues }).count
  }

  /// Saves the `NSManagedObjectContext` if changes are present.
  public final func saveIfNeeded() throws {
    if hasChanges {
      try save()
    }
  }

  /// Saves the `NSManagedObjectContext` if changes are present or **rollbacks** if any error occurs.
  /// - Note: The rollback removes everything from the undo stack, discards all insertions and deletions, and restores updated objects to their last committed values.
  public final func saveIfNeededOrRollBack() throws {
    do {
      try saveIfNeeded()
    } catch {
      rollback() // rolls back the pending changes (and clears the undo stack if set up)
      throw error
    }
  }
}

// MARK: - Better PerformAndWait

extension NSManagedObjectContext {
  /// Synchronously performs a given block on the context’s queue and returns the final result.
  /// - Throws: It throws an error in cases of failure.
  public final func performAndWait<T>(_ block: (NSManagedObjectContext) throws -> T) rethrows -> T {
    if #available(iOS 15.0, iOSApplicationExtension 15.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, macOS 12, *) {
      return try performAndWait {
        try block(self)
      }
    } else {
      return try _performAndWaitHelper(function: performAndWait, execute: block, rescue: { throw $0 })
    }
  }

  /// Helper function for convincing the type checker that the rethrows invariant holds for performAndWait.
  ///
  /// Source: https://oleb.net/blog/2018/02/performandwait/
  /// Source: https://github.com/apple/swift/blob/bb157a070ec6534e4b534456d208b03adc07704b/stdlib/public/SDK/Dispatch/Queue.swift#L228-L249
  private func _performAndWaitHelper<T>(function: (() -> Void) -> Void,
                                        execute work: (NSManagedObjectContext) throws -> T,
                                        rescue: (Error) throws -> (T)) rethrows -> T {
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
