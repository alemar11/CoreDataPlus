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
  public static func migrateStore<Version: ModelVersion>(at sourceURL: URL, targetVersion: Version, enableWALCheckpoint: Bool = false, progress: Progress? = nil) throws {
    try migrateStore(from: sourceURL, to: sourceURL, targetVersion: targetVersion, deleteSource: false, enableWALCheckpoint: enableWALCheckpoint, progress: progress)
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
  public static func migrateStore<Version: ModelVersion>(from sourceURL: URL,
                                                         to targetURL: URL,
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
      try Self.performWALCheckpoint(version: sourceVersion, storeURL: sourceURL)
    }
    
    var currentURL = sourceURL
    let steps = sourceVersion.migrationSteps(to: targetVersion)
    
    guard steps.count > 0 else {
      return
    }
    
    var migrationProgress: Progress?
    
    if let progress = progress {
      migrationProgress = Progress(totalUnitCount: Int64(steps.count), parent: progress, pendingUnitCount: progress.totalUnitCount)
    }
    
    for step in steps {
      try autoreleasepool {
        migrationProgress?.becomeCurrent(withPendingUnitCount: 1)
        let manager = NSMigrationManager(sourceModel: step.sourceModel, destinationModel: step.destinationModel)
        migrationProgress?.resignCurrent()
        
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)
        
        for mapping in step.mappings {
          try manager.migrateStore(from: currentURL,
                                   sourceType: NSSQLiteStoreType,
                                   options: nil,
                                   with: mapping,
                                   toDestinationURL: destinationURL,
                                   destinationType: NSSQLiteStoreType,
                                   destinationOptions: nil)
        }
        
        if currentURL != sourceURL {
          try NSPersistentStoreCoordinator.destroyStore(at: currentURL)
        }
        currentURL = destinationURL
      }
    }
    
    try NSPersistentStoreCoordinator.replaceStore(at: targetURL, withStoreAt: currentURL)
    
    if currentURL != sourceURL {
      try NSPersistentStoreCoordinator.destroyStore(at: currentURL)
    }
    
    if targetURL != sourceURL && deleteSource {
      try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
    }
  }
  
  // MARK: - WAL Checkpoint
  
  // Forces Core Data to perform a checkpoint operation, which merges the data in the `-wal` file to the store file.
  static func performWALCheckpoint<V: ModelVersion>(version: V, storeURL: URL) throws {
    // If the -wal file is not present, using this approach to add the store won't cause any exceptions, but the transactions recorded in the missing -wal file will be lost.
    // https://developer.apple.com/library/archive/qa/qa1809/_index.html
    // credits:
    // https://williamboles.me/progressive-core-data-migration/
    // http://pablin.org/2013/05/24/problems-with-core-data-migration-manager-and-journal-mode-wal/
    // https://www.avanderlee.com/swift/write-ahead-logging-wal/
    try performWALCheckpointForStore(at: storeURL, model: version.managedObjectModel())
  }
  
  /// Forces Core Data to perform a checkpoint operation, which merges the data in the `-wal` file to the store file.
  private static func performWALCheckpointForStore(at storeURL: URL, model: NSManagedObjectModel) throws {
    let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
    let store = try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
    try persistentStoreCoordinator.remove(store)
  }
}
