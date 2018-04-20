//
// CoreDataPlus
//
// Copyright © 2016-2018 Tinrobots.
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
    //TODO: better management?
    if !ProcessInfo.isRunningUnitTests {
      assertionFailure("\(self.description) doesn't have a Persistent Store Coordinator.")
    }
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
  /// Asynchronously performs changes and then saves them or **rollbacks** if any error occurs.
  ///
  /// - Parameters:
  ///   - changes: Changes to be applied in the current context before the saving operation. If they fail throwing an execption, the context will be reset.
  ///   - completion: Block executed (on the context’s queue.) at the end of the saving operation.
  public final func performSave(after changes: () throws -> Void, completion: ( (Error?) -> Void )? = nil ) {
    // swiftlint:disable:next identifier_name
    withoutActuallyEscaping(changes) { _changes in
      perform { [unowned unownedSelf = self] in
        var result: Error?
        do {
          try _changes()
          result = nil
        } catch {
          result = error
        }

        guard result == nil else {
          unownedSelf.reset()
          completion?(result)
          return
        }

        do {
          try unownedSelf.saveOrRollBack()
          result = nil
        } catch {
          result = error
        }
        completion?(result)
      }
    }
  }

  /// **CoreDataPlus**
  ///
  /// Synchronously performs changes and then saves them or **rollbacks** if any error occurs. If the changes fail throwing an execption, the context will be reset.
  ///
  /// - Throws: An error in cases of a saving operation failure.
  public final func performSaveAndWait(after changes: () throws -> Void) throws {
    // swiftlint:disable:next identifier_name
    try withoutActuallyEscaping(changes) { _changes in
      var closureError: Error? = nil
      var saveError: Error? = nil

      performAndWait { [unowned unownedSelf = self] in
        do {
          try _changes()
        } catch {
          closureError = error
        }

        guard closureError == nil else {
          rollback()
          return
        }

        do {
          try unownedSelf.saveOrRollBack()
        } catch {
          saveError = error
        }

      }

      if let error = closureError { throw CoreDataPlusError.executionFailed(error: error) }
      if let error = saveError { throw CoreDataPlusError.saveFailed(error: error) }
    }
  }

  /// **CoreDataPlus**
  ///
  /// Saves the `NSManagedObjectContext` if changes are present or **rollbacks** if any error occurs.
  private final func saveOrRollBack() throws {
    guard hasChanges else { return }
    do {
      try save()
    } catch {
      rollback()
      throw CoreDataPlusError.saveFailed(error: error)
    }
  }

  /// **CoreDataPlus**
  ///
  /// Saves the `NSManagedObjectContext` up to the last parent `NSManagedObjectContext`.
  private final func performSaveUpToTheLastParentContextAndWait() throws {
    var parentContext: NSManagedObjectContext? = self

    while parentContext != nil {
      var saveError: Error? = nil

      parentContext!.performAndWait {
        do {
          try parentContext!.save()
        } catch {
          saveError = error
        }
      }
      parentContext = parentContext!.parent
      if let error = saveError { throw CoreDataPlusError.saveFailed(error: error) }
    }
  }

}

// MARK: Perform

extension NSManagedObjectContext {

  /// **CoreDataPlus**
  ///
  /// Synchronously performs a given block on the context’s queue and returns the final result.
  public func performAndWait<T>(_ block: (NSManagedObjectContext) throws -> T) rethrows -> T {
    return try _performAndWait(function: performAndWait, execute: block, rescue: { throw $0 })
  }

  /// Helper function for convincing the type checker that
  /// the rethrows invariant holds for performAndWait.
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
