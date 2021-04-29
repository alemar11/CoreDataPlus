// CoreDataPlus
//
// Readings:
// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmLightweightMigration.html
// https://developer.apple.com/documentation/coredata/heavyweight_migration
// https://www.objc.io/issues/4-core-data/core-data-migration/

// Schema migration & performance
// https://developer.apple.com/forums/thread/651325
//
// You should basically only use lightweight migration with an inferred mapping model.
//
// You should avoid your own custom mapping models and migration managers as these require an unbounded amount of memory.
//
// You can chain migrations together by avoiding NSMigratePersistentStoresAutomaticallyOption and checking for NSPersistentStoreIncompatibleVersionHashError from addPersistentStore.
// The store metadata can drive your decision about a migration to perform and you can migrate to an intermediate schema and massage the data in code.
// When ready you make a second migration to your final (the current app) schema.

import CoreData

public enum Migration {
  /// Migrates a store to a given version.
  ///
  /// - Parameters:
  ///   - sourceURL: the current store URL.
  ///   - targetVersion: the ModelVersion to which the store is needed to migrate to.
  ///   - enableWALCheckpoint: if `true` Core Data will perform a checkpoint operation which merges the data in the `-wal` file to the store file.
  ///   - progress: a Progress instance to monitor the migration.
  /// - Throws: It throws an error in cases of failure.
  ///
  /// During migration, Core Data creates two stacks, one for the source store and one for the destination store.
  /// Core Data then fetches objects from the source stack and inserts the appropriate corresponding objects into the destination stack. Note that Core Data must re-create objects in the new stack.
  public static func migrateStore<Version: ModelVersion>(at sourceURL: URL,
                                                         options: PersistentStoreOptions? = nil,
                                                         targetVersion: Version,
                                                         enableWALCheckpoint: Bool = false,
                                                         progress: Progress? = nil) throws {
    try migrateStore(from: sourceURL,
                     sourceOptions: options,
                     to: sourceURL,
                     targetOptions: options,
                     targetVersion: targetVersion,
                     deleteSource: false,
                     enableWALCheckpoint: enableWALCheckpoint,
                     progress: progress)
  }

  /// Migrates a store to a given version if needed.
  ///
  /// - Parameters:
  ///   - sourceURL: The location of the existing persistent store.
  ///   - targetURL: The location of the destination store.
  ///   - targetVersion: the ModelVersion to which the store is needed to migrate to.
  ///   - deleteSource: if `true` the initial store will be deleted after the migration phase.
  ///   - enableWALCheckpoint: if `true` Core Data will perform a checkpoint operation which merges the data in the -wal file to the store file.
  ///   - progress: a Progress instance to monitor the migration.
  /// - Throws: It throws an error in cases of failure.
  ///
  /// During migration, Core Data creates two stacks, one for the source store and one for the destination store.
  /// Core Data then fetches objects from the source stack and inserts the appropriate corresponding objects into the destination stack. Note that Core Data must re-create objects in the new stack.
  public static func migrateStore<Version: ModelVersion>(from sourceURL: URL,
                                                         sourceOptions: PersistentStoreOptions? = nil,
                                                         to targetURL: URL,
                                                         targetOptions: PersistentStoreOptions? = nil,
                                                         targetVersion: Version,
                                                         deleteSource: Bool = false,
                                                         enableWALCheckpoint: Bool = false,
                                                         progress: Progress? = nil) throws {
    guard let sourceVersion = try Version(persistentStoreURL: sourceURL) else {
      fatalError("A ModelVersion for the store at URL \(sourceURL) could not be found.")
    }

    guard try CoreDataPlus.isMigrationNecessary(for: sourceURL, to: targetVersion) else {
      return
    }

    if enableWALCheckpoint {
      // A dead lock can occur if a NSPersistentStore with a different journaling mode
      // is currently active and using the database file.
      // You need to remove it before performing a WAL checkpoint.
      try Self.performWALCheckpoint(version: sourceVersion, storeURL: sourceURL, storeOptions: sourceOptions)
    }

    let steps = sourceVersion.migrationSteps(to: targetVersion)
    guard steps.count > 0 else { return }

    var migrationProgress: Progress?
    if let progress = progress {
      migrationProgress = Progress(totalUnitCount: Int64(steps.count), parent: progress, pendingUnitCount: progress.totalUnitCount)
    }

    // TODO: if there is only a step and sourceURL != targetURL, we could skip the temporaryURL phase
    // TODO: a callback could provide the partial currentURL

    var currentURL = sourceURL
    for step in steps {
      try autoreleasepool {
        #warning("TODO: review the progress object")
        migrationProgress?.becomeCurrent(withPendingUnitCount: 1)
        //let manager = MigrationManager(sourceModel: step.sourceModel, destinationModel: step.destinationModel)
        migrationProgress?.resignCurrent()
        
        //manager.usesStoreSpecificMigrationManager = false

        let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)

        let stepProgress = Progress(totalUnitCount: Int64(step.mappings.count))
        let token = stepProgress.observe(\.fractionCompleted, options: [.new]) { p, change in
          print("✅", change.newValue)
        }

        for mapping in step.mappings {
          if mapping.isInferred {
            print("➡️➡️ LIGHT MIGRATION")
          } else {
            print("➡️➡️ HEAVY MIGRATION")
          }

          // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmCustomizing.html#//apple_ref/doc/uid/TP40004399-CH8-SW9
          // Usually reusing the same NSMigrationManager for multiple mapping models works fine... until it doesn't
          // (in particular if the model has entities with "uncommon" rules, i.e. relationships with min and max set with custom values).
          // In these cases, one of the migrations could fail (mostly due to validation errors) unless we use different NSMigrationManager instance.
          // Also, we can't add the same child progress multiple times.

          let manager = MigrationManager(sourceModel: step.sourceModel, destinationModel: step.destinationModel)
          stepProgress.addChild(manager.progress, withPendingUnitCount: 1)

          // Reusing the same NSMigrationManager instance seems to cause some validation errors
          //let manager = MigrationManager(sourceModel: step.sourceModel, destinationModel: step.destinationModel)
          // migrations fails if the targetURL points to an already existing file
          try manager.migrateStore(from: currentURL,
                                   sourceType: NSSQLiteStoreType,
                                   options: sourceOptions,
                                   with: mapping,
                                   toDestinationURL: temporaryURL,
                                   destinationType: NSSQLiteStoreType,
                                   destinationOptions: targetOptions)
        }

        // once the migration is done (and the store is migrated to temporaryURL)
        // the store at currentSourceURL can be safely destroyed unless it is the
        // initial store
        if currentURL != sourceURL {
          try NSPersistentStoreCoordinator.destroyStore(at: currentURL)
        }
        currentURL = temporaryURL
      }
    }

    // move the store at currentURL to (final) targetURL
    try NSPersistentStoreCoordinator.replaceStore(at: targetURL, withPersistentStoreFrom: currentURL)

    // delete the store at currentURL if it's not the initial store
    if currentURL != sourceURL {
      try NSPersistentStoreCoordinator.destroyStore(at: currentURL)
    }

    // delete the initial store only if the option is set to true
    if targetURL != sourceURL && deleteSource {
      try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
    }
  }

  // MARK: - WAL Checkpoint

  // Forces Core Data to perform a checkpoint operation, which merges the data in the `-wal` file to the store file.
  static func performWALCheckpoint<V: ModelVersion>(version: V, storeURL: URL, storeOptions: PersistentStoreOptions? = nil) throws {
    // If the -wal file is not present, using this approach to add the store won't cause any exceptions, but the transactions recorded in the missing -wal file will be lost.
    // https://developer.apple.com/library/archive/qa/qa1809/_index.html
    // credits:
    // https://williamboles.me/progressive-core-data-migration/
    // http://pablin.org/2013/05/24/problems-with-core-data-migration-manager-and-journal-mode-wal/
    // https://www.avanderlee.com/swift/write-ahead-logging-wal/
    try performWALCheckpointForStore(at: storeURL, model: version.managedObjectModel(), storeOptions: storeOptions)
  }

  /// Forces Core Data to perform a checkpoint operation, which merges the data in the `-wal` file to the store file.
  private static func performWALCheckpointForStore(at storeURL: URL, model: NSManagedObjectModel, storeOptions: PersistentStoreOptions? = nil) throws {
    // TODO: see https://williamboles.me/progressive-core-data-migration/
    let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    var options: PersistentStoreOptions = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
    if
      let persistentHistoryTokenKey = storeOptions?[NSPersistentHistoryTrackingKey] as? NSNumber,
      persistentHistoryTokenKey.boolValue {
      // once this key is enabled, it can be reverted back
      // for WAL checkpoint this step prevents this warning in the console:
      // "Store opened without NSPersistentHistoryTrackingKey but previously had been opened
      // with NSPersistentHistoryTrackingKey - Forcing into Read Only mode store at ..."
      // https://developer.apple.com/forums/thread/118924
      options[NSPersistentHistoryTrackingKey] = [NSPersistentHistoryTrackingKey: true as NSNumber]
    }

    let store = try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
    try persistentStoreCoordinator.remove(store)
  }
}

/// About moving stores disabling the WAL journaling mode
/// https://developer.apple.com/library/archive/qa/qa1809/_index.html
/// https://www.avanderlee.com/swift/write-ahead-logging-wal/
///
/// ```
/// let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]] // the migration will be done without -wal and -shm files
/// try! psc!.migratePersistentStore(store, to: url, options: options, withType: NSSQLiteStoreType)
/// ```

extension Migration {
  static func migrateStore<Version: ModelVersion>(from sourceStoreDescription: NSPersistentStoreDescription,
                                                  to destinationStoreDescription: NSPersistentStoreDescription,
                                                  targetVersion: Version,
                                                  deleteSource: Bool = false,
                                                  enableWALCheckpoint: Bool = false,
                                                  progress: Progress? = nil) throws {
    guard let sourceURL = sourceStoreDescription.url else { fatalError("Source NSPersistentStoreDescription requires a URL.") }
    guard let destinationURL = destinationStoreDescription.url else { fatalError("Destination NSPersistentStoreDescription requires a URL.") }

    try Self.migrateStore(from: sourceURL,
                          sourceOptions: sourceStoreDescription.options,
                          to: destinationURL,
                          targetOptions: destinationStoreDescription.options,
                          targetVersion: targetVersion,
                          deleteSource: deleteSource,
                          enableWALCheckpoint: enableWALCheckpoint,
                          progress: progress)
  }
}
