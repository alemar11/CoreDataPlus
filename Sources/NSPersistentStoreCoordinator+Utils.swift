// CoreDataPlus

import CoreData

// TODO: should these method run inside the psc.performAndWait { ... }

extension NSPersistentStoreCoordinator {
  /// Adds an `object` to the store's metadata.
  ///
  /// After updating the metadata, save the managed object context referring to the store’s coordinator to actually persist the changes.
  ///
  /// - Parameters:
  ///   - object: Object to be added to the medata dictionary.
  ///   - key: Object key
  ///   - store: NSPersistentStore where is stored the metadata.
  /// - Important: Setting the metadata for a store does not change the information on disk until the store is actually saved.
  public final func setMetadataObject(_ object: Any?, with key: String, for store: NSPersistentStore) {
    // TODO: Any -> Codable or SecureCopying?
    var metaData = metadata(for: store)
    metaData[key] = object
    setMetadata(metaData, for: store)
    // https://www.meandmark.com/blog/2017/11/saving-settings-with-core-data-metadata/
    // https://paysonwallach.com/posts/storing-metadata-in-core-data/
    // https://github.com/objcio/core-data/blob/master/SharedCode/NSManagedObjectContext%2BExtensions.swift
  }

  /// Safely deletes a store at a given url.
  public static func destroyStore(at url: URL, options: PersistentStoreOptions? = nil) throws {
    let persistentStoreCoordinator = self.init(managedObjectModel: NSManagedObjectModel())
    /// destroyPersistentStore safely deletes everything in the database and leaves an empty database behind.
    if #available(iOS 15.0, iOSApplicationExtension 15.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, macOS 12, *) {
      try persistentStoreCoordinator.destroyPersistentStore(at: url, type: .sqlite, options: options)
    } else {
      try persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: options)
    }

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

    if #available(iOS 15.0, iOSApplicationExtension 15.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, macOS 12, *) {
      try persistentStoreCoordinator.replacePersistentStore(at: destinationURL,
                                                            destinationOptions: destinationOptions,
                                                            withPersistentStoreFrom: sourceURL,
                                                            sourceOptions: sourceOptions,
                                                            type: .sqlite)
    } else {
      try persistentStoreCoordinator.replacePersistentStore(at: destinationURL,
                                                            destinationOptions: destinationOptions,
                                                            withPersistentStoreFrom: sourceURL,
                                                            sourceOptions: sourceOptions,
                                                            ofType: NSSQLiteStoreType)
    }
  }

  /// Removes all the stores associated with the coordinator.
  public func removeAllStores() throws {
    try persistentStores.forEach { try remove($0) }
  }
}

/**
 https://developer.apple.com/forums/thread/651325
 Additionally you should almost never use NSPersistentStoreCoordinator's migratePersistentStore method but instead use the newer replacePersistentStoreAtURL.
 (you can replace emptiness to make a copy).
 The former loads the store into memory so you can do fairly radical things like write it out as a different store type.
 It pre-dates iOS. The latter will perform an APFS clone where possible.
 */
