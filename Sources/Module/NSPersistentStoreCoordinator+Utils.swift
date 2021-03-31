// CoreDataPlus

import CoreData

extension NSPersistentStoreCoordinator {
  /// **CoreDataPlus**
  ///
  /// Safely deletes a store at a given url.
  public static func destroyStore(at url: URL) throws {
    let persistentStoreCoordinator = self.init(managedObjectModel: NSManagedObjectModel())
    /// destroyPersistentStore safely deletes everything in the database and leaves an empty database behind.
    try persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)

    let fileManager = FileManager.default

    let storePath = url.path
    try fileManager.removeItem(atPath: storePath)

    let writeAheadLog = storePath + "-wal"
    _ = try? fileManager.removeItem(atPath: writeAheadLog)

    let sharedMemoryfile = storePath + "-shm"
    _ = try? fileManager.removeItem(atPath: sharedMemoryfile)
  }

  /// **CoreDataPlus**
  ///
  /// Replaces the destination persistent store with the source store.
  /// - Attention: The stored must be SQLite
  public static func replaceStore(at targetURL: URL, withStoreAt sourceURL: URL) throws {
    let persistentStoreCoordinator = self.init(managedObjectModel: NSManagedObjectModel())
    try persistentStoreCoordinator.replacePersistentStore(at: targetURL, destinationOptions: nil, withPersistentStoreFrom: sourceURL, sourceOptions: nil, ofType: NSSQLiteStoreType)
  }
}

/**
 About moving stores disabling the WAL journaling mode
 https://developer.apple.com/library/archive/qa/qa1809/_index.html
 https://www.avanderlee.com/swift/write-ahead-logging-wal/

 ```
 let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]] // the migration will be done without -wal and -shm files
 try! psc!.migratePersistentStore(store, to: url, options: options, withType: NSSQLiteStoreType)
 ```


 https://developer.apple.com/forums/thread/651325
 Additionally you should almost never use NSPersistentStoreCoordinator's migratePersistentStore... method but instead use the newer replacePersistentStoreAtURL..
 (you can replace emptiness to make a copy).
 The former loads the store into memory so you can do fairly radical things like write it out as a different store type.
 It pre-dates iOS. The latter will perform an APFS clone where possible.
 */
