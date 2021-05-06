// CoreDataPlus
//
// Readings:
// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmLightweightMigration.html
// https://developer.apple.com/documentation/coredata/heavyweight_migration
// https://www.objc.io/issues/4-core-data/core-data-migration/

// # Schema migration & performance
// https://developer.apple.com/forums/thread/651325
//
// You should basically only use lightweight migration with an inferred mapping model.
// You should avoid your own custom mapping models and migration managers as these require an unbounded amount of memory.
//
// You can chain migrations together by avoiding NSMigratePersistentStoresAutomaticallyOption and checking for NSPersistentStoreIncompatibleVersionHashError from addPersistentStore.
// The store metadata can drive your decision about a migration to perform and you can migrate to an intermediate schema and massage the data in code.
// When ready you make a second migration to your final (the current app) schema.
//
// # Lightweight Migrations
//
// You don't want to use a subclass of NSMigrationManager for lightweight migrations because it's way more slow and consume more RAM.
// Also, for the same reasons, don't set usesStoreSpecificMigrationManager to "true".
// However, NSMigrationManager with usesStoreSpecificMigrationManager set to "true" won't report its progress; that's why we may want to
// to fake it (again: the benefits in terms of performance and RAM consumption are too important that is better to fake the progress).
// In addition to that, NSMigrationManager with usesStoreSpecificMigrationManager set to "true" ignores cancel commands done via its cancelMigrationWithError(_:) method.
//
// # Heavyweight Migrations
// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmCustomzing.html#//apple_ref/doc/uid/TP40004399-CH8-SW9
//
// Usually reusing the same NSMigrationManager for multiple mapping models works fine... until it doesn't!
// (in particular if the model has entities with "particular" rules, i.e. relationships with min and max set with custom values).
// In these cases, one of the migrations could fail (mostly due to validation errors) unless we use different NSMigrationManager instance.

import CoreData

// TODO: os_log

open class Migrator<Version: ModelVersion>: NSObject, ProgressReporting {
  public private(set) lazy var progress: Progress = {
    // We don't need to manage any cancellations here:
    // if this progress is cancelled, the cancellation is inherited by all the migration step progresses
    // and, even if they are added (as children) to this progress later, they will inherit the cancellation state
    // and their cancellationHandler will be called.
    var progress = Progress(totalUnitCount: 1)
    return progress
  }()
  
  let sourceStoreDescription: NSPersistentStoreDescription
  let destinationStoreDescription: NSPersistentStoreDescription
  
  public init(sourceStoreDescription: NSPersistentStoreDescription, destinationStoreDescription: NSPersistentStoreDescription) {
    self.sourceStoreDescription = sourceStoreDescription
    self.destinationStoreDescription = destinationStoreDescription
    super.init()
    _ = progress // lazy init for implicit progress support
  }
  
  public func migrate(to targetVersion: Version, enableWALCheckpoint: Bool = false) throws {
    guard let sourceURL = sourceStoreDescription.url else { fatalError("Source NSPersistentStoreDescription requires a URL.") }
    guard let destinationURL = destinationStoreDescription.url else { fatalError("Destination NSPersistentStoreDescription requires a URL.") }
    
    try migrateStore(from: sourceURL,
                     sourceOptions: sourceStoreDescription.options,
                     to: destinationURL,
                     targetOptions: destinationStoreDescription.options,
                     targetVersion: targetVersion,
                     enableWALCheckpoint: enableWALCheckpoint)
  }
  
  /// Returns a `NSMigrationManager` instance for a migration step.
  open func migrationManager(sourceVersion: Version.RawValue,
                             sourceModel: NSManagedObjectModel,
                             destinationVersion: Version.RawValue,
                             destinationModel: NSManagedObjectModel,
                             mappingModel: NSMappingModel) -> NSMigrationManager {
    NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
  }
}

extension Migrator {
  fileprivate func migrateStore(from sourceURL: URL,
                                sourceOptions: PersistentStoreOptions? = nil,
                                to targetURL: URL,
                                targetOptions: PersistentStoreOptions? = nil,
                                targetVersion: Version,
                                enableWALCheckpoint: Bool = false) throws {
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
      try performWALCheckpointForStore(at: sourceURL, storeOptions: sourceOptions, model: sourceVersion.managedObjectModel())
    }
    
    let steps = sourceVersion.migrationSteps(to: targetVersion)
    
    guard steps.count > 0 else { return }
    
    let migrationStepsProgress = Progress(totalUnitCount: Int64(steps.count), parent: progress, pendingUnitCount: progress.totalUnitCount)
    
    
    // TODO: if there is only a step and sourceURL != targetURL, we could skip the temporaryURL phase
    // TODO: a callback could provide the partial currentURL
    
    var currentURL = sourceURL
    for step in steps {
      try autoreleasepool {
        let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)
        
        let mappingModelMigrationProgress = Progress(totalUnitCount: Int64(step.mappingModels.count))
        migrationStepsProgress.addChild(mappingModelMigrationProgress, withPendingUnitCount: 1)
        
        for mappingModel in step.mappingModels {
          let manager = migrationManager(sourceVersion: step.sourceVersion,
                                         sourceModel: step.sourceModel,
                                         destinationVersion: step.destinationVersion,
                                         destinationModel: step.destinationModel,
                                         mappingModel: mappingModel)
          mappingModelMigrationProgress.becomeCurrent(withPendingUnitCount: 1)
          // a reporter instance handles parent progress cancellations automatically
          let progressReporter = manager.makeProgressReporter()
          mappingModelMigrationProgress.resignCurrent()
          
          try manager.migrateStore(from: currentURL,
                                   sourceType: NSSQLiteStoreType,
                                   options: sourceOptions,
                                   with: mappingModel,
                                   toDestinationURL: temporaryURL,
                                   destinationType: NSSQLiteStoreType,
                                   destinationOptions: targetOptions)
          progressReporter.markAsFinishedIfNeeded() // Ligthweight migrations don't report progress
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
    if targetURL != sourceURL {
      try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
    }
  }
  
}

// MARK: - WAL Checkpoint

/// Forces Core Data to perform a checkpoint operation, which merges the data in the `-wal` file to the store file.
private func performWALCheckpointForStore(at storeURL: URL, storeOptions: PersistentStoreOptions? = nil, model: NSManagedObjectModel) throws {
  // "If the -wal file is not present, using this approach to add the store won't cause any exceptions, but the transactions recorded in the missing -wal file will be lost." (from: https://developer.apple.com/library/archive/qa/qa1809/_index.html)
  // credits:
  // https://williamboles.me/progressive-core-data-migration/
  // http://pablin.org/2013/05/24/problems-with-core-data-migration-manager-and-journal-mode-wal/
  // https://www.avanderlee.com/swift/write-ahead-logging-wal/
  let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
  var options: PersistentStoreOptions = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
  if
    let persistentHistoryTokenKey = storeOptions?[NSPersistentHistoryTrackingKey] as? NSNumber,
    persistentHistoryTokenKey.boolValue {
    // Once NSPersistentHistoryTrackingKey is enabled, it can't be reverted back.
    // During a WAL checkpoint this step prevents this warning in the console:
    // "Store opened without NSPersistentHistoryTrackingKey but previously had been opened
    // with NSPersistentHistoryTrackingKey - Forcing into Read Only mode store at ..."
    // https://developer.apple.com/forums/thread/118924
    options[NSPersistentHistoryTrackingKey] = [NSPersistentHistoryTrackingKey: true as NSNumber]
  }
  
  let store = try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
  try persistentStoreCoordinator.remove(store)
}
