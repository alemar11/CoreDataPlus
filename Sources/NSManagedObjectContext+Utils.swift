//
// CoreDataPlus
//
// Copyright © 2016-2019 Tinrobots.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
    performSave(after: { [weak self] in
      guard let strongSelf = self else { return }
      guard let persistentStoreCoordinator = strongSelf.persistentStoreCoordinator else { preconditionFailure("\(strongSelf.description) doesn't have a Persistent Store Coordinator.") }

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
  /// Asynchronously performs changes and then saves them.
  ///
  /// - Parameters:
  ///   - changes: Changes to be applied in the current context before the saving operation. If they fail throwing an execption, the context will be reset.
  ///   - completion: Block executed (on the context’s queue.) at the end of the saving operation.
  public final func performSave(after changes: @escaping () throws -> Void, completion: ( (CoreDataPlusError?) -> Void )? = nil ) {
    perform { [unowned unownedSelf = self] in
      var internalError: CoreDataPlusError?

      do {
        try changes()
      } catch {
        internalError = CoreDataPlusError.executionFailed(underlyingError: error)
      }

      guard internalError == nil else {
        completion?(internalError)
        return
      }

      do {
        try unownedSelf.save()
      } catch {
        internalError = CoreDataPlusError.saveFailed(underlyingError: error)
      }
      completion?(internalError)
    }
  }

  /// **CoreDataPlus**
  ///
  /// Synchronously performs changes and then saves them: if the changes fail throwing an execption, the context will be reset.
  ///
  /// - Throws: It throws an error in cases of failure (while applying changes or saving).
  public final func performSaveAndWait(after changes: () throws -> Void) throws {
    // swiftlint:disable:next identifier_name
    try withoutActuallyEscaping(changes) { _changes in
      var internalError: CoreDataPlusError?

      performAndWait {
        do {
          try _changes()
        } catch {
          internalError = CoreDataPlusError.executionFailed(underlyingError: error)
        }

        guard internalError == nil else { return }

        do {
          try save()
        } catch {
          internalError = CoreDataPlusError.saveFailed(underlyingError: error)
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
      throw CoreDataPlusError.saveFailed(underlyingError: error)
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
        throw CoreDataPlusError.saveFailed(underlyingError: error)
      }
    }
  }
}

// MARK: Perform

extension NSManagedObjectContext {
  /// **CoreDataPlus**
  ///
  /// Synchronously performs a given block on the context’s queue and returns the final result.
  /// - Throws: It throws an error in cases of failure.
  public func performAndWait<T>(_ block: (NSManagedObjectContext) throws -> T) rethrows -> T {
    return try _performAndWait(function: performAndWait, execute: block, rescue: { throw $0 })
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
