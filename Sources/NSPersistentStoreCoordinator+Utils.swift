// CoreDataPlus

import CoreData

extension NSPersistentStoreCoordinator {
  /// Safely deletes a store at a given url.
  public static func destroyStore(at url: URL, options: PersistentStoreOptions? = nil) throws {
    let persistentStoreCoordinator = self.init(managedObjectModel: NSManagedObjectModel())
    /// destroyPersistentStore safely deletes everything in the database and leaves an empty database behind.
    try persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: options)

    let fileManager = FileManager.default

    let storePath = url.path
    try fileManager.removeItem(atPath: storePath)

    let writeAheadLog = storePath + "-wal"
    _ = try? fileManager.removeItem(atPath: writeAheadLog)

    let sharedMemoryfile = storePath + "-shm"
    _ = try? fileManager.removeItem(atPath: sharedMemoryfile)
  }

  /// Replaces the destination persistent store with the source store.
  /// - Attention: The stored must be of SQLite type.
  public static func replaceStore(at destinationURL: URL,
                                  destinationOptions: PersistentStoreOptions? = nil,
                                  withPersistentStoreFrom sourceURL: URL,
                                  sourceOptions: PersistentStoreOptions? = nil) throws {
    // https://mjtsai.com/blog/2021/03/31/replacing-vs-migrating-core-data-stores/
    // https://atomicbird.com/blog/mostly-undocumented/
    // https://github.com/atomicbird/CDMoveDemo
    let persistentStoreCoordinator = self.init(managedObjectModel: NSManagedObjectModel())
    // replacing a store has a side effect of removing the current store from the psc
    try persistentStoreCoordinator.replacePersistentStore(at: destinationURL,
                                                          destinationOptions: destinationOptions,
                                                          withPersistentStoreFrom: sourceURL,
                                                          sourceOptions: sourceOptions,
                                                          ofType: NSSQLiteStoreType)
  }
}

/**
 https://developer.apple.com/forums/thread/651325
 Additionally you should almost never use NSPersistentStoreCoordinator's migratePersistentStore... method but instead use the newer replacePersistentStoreAtURL..
 (you can replace emptiness to make a copy).
 The former loads the store into memory so you can do fairly radical things like write it out as a different store type.
 It pre-dates iOS. The latter will perform an APFS clone where possible.
 */
