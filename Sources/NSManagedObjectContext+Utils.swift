//
// CoreDataPlus
//
// Copyright © 2016-2017 Tinrobots.
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
  public final func metaData(for store: NSPersistentStore) throws -> [String: Any] {
    guard let persistentStoreCoordinator = persistentStoreCoordinator else { throw CoreDataPlusError.configurationFailed(reason: .persistentStoreCoordinator(context: self)) }

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
    performSave(after: {
      guard let persistentStoreCoordinator = self.persistentStoreCoordinator else {
        handler?(CoreDataPlusError.configurationFailed(reason: .persistentStoreCoordinator(context: self)))
        return
      }
      var metaData = persistentStoreCoordinator.metadata(for: store)
      metaData[key] = object
      persistentStoreCoordinator.setMetadata(metaData, for: store)
    }, completion: { error in
      handler?(error)
    })
  }

  /// **CoreDataPlus**
  ///
  /// Returns the entity with the specified name from the managed object model associated with the specified managed object context’s persistent store coordinator.
  public final func entity(forEntityName name: String) throws -> NSEntityDescription {
    guard let persistentStoreCoordinator = persistentStoreCoordinator else {
        throw CoreDataPlusError.configurationFailed(reason: .persistentStoreCoordinator(context: self))
    }
    guard let entity = persistentStoreCoordinator.managedObjectModel.entitiesByName[name] else { throw CoreDataPlusError.configurationFailed(reason: .entityName(entityName: name)) }
    
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
  ///   - changes: Changes to be applied in the current context before the saving operation.
  ///   - completion: Block executed (on the context’s queue.) at the end of the saving operation.
  public final func performSave(after changes: @escaping () -> Void, completion: ( (Error?) -> Void )? = nil ) {
    perform { [unowned unownoedSelf = self] in
      changes()
      let result: Error?
      do {
        try unownoedSelf.saveOrRollBack()
        result = nil
      } catch {
        result = error
      }
      completion?(result) // completion is escaping by default
    }
  }

  /// **CoreDataPlus**
  ///
  /// Synchronously performs changes and then saves them or **rollbacks** if any error occurs.
  ///
  /// - Throws: An error in cases of a saving operation failure.
  public final func performSaveAndWait(after changes: () -> Void) throws {
    try withoutActuallyEscaping(changes) { work in
      var saveError: Error? = nil
      performAndWait { [unowned unownoedSelf = self] in
        work()
        do {
          try unownoedSelf.saveOrRollBack()
        } catch {
          saveError = error
        }
      }
      if let error = saveError { throw CoreDataPlusError.contextOperationFailed(reason: .saveFailed(error: error)) }
    }
  }

  /// Saves the `NSManagedObjectContext` if changes are present or **rollbacks** if any error occurs.
  private final func saveOrRollBack() throws {
    guard hasChanges else { return }
    do {
      try save()
    } catch {
      rollback()
      throw CoreDataPlusError.contextOperationFailed(reason: .saveFailed(error: error))
    }
  }

}
