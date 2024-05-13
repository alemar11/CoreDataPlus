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
//
// In a subclass of NSPersistentStore, you can override this to provide a custom migration manager subclass
// (for example, to take advantage of store-specific functionality to improve migration performance).
// https://developer.apple.com/documentation/coredata/nspersistentstore/1506361-migrationmanagerclass

import CoreData
import os.log

/// An object that handles a multi step CoreData migration for a `SQLite` store.
public final class Migrator<Version: ModelVersion & LegacyMigration>: NSObject, ProgressReporting {
  /// Multi step migration progress.
  public private(set) lazy var progress: Progress = {
    // We don't need to manage any cancellations here:
    // if this progress is cancelled, the cancellation is inherited by all the migration step progresses
    // and, even if they are added (as children) to this progress later, they will inherit the cancellation state
    // and their cancellationHandler will be called.
    var progress = Progress(totalUnitCount: 1)
    return progress
  }()

  /// Enable log.
  public var enableLog: Bool = false {
    didSet {
      if enableLog {
        log = Logger(subsystem: bundleIdentifier, category: "Migrator")
      } else {
        log = .init(.disabled)
      }
    }
  }

  private var log: Logger = .init(.disabled)

  /// Source description used as starting point for the migration steps.
  internal let sourceStoreDescription: NSPersistentStoreDescription

  /// Desitnation description used as final point for the migrations steps.
  internal let destinationStoreDescription: NSPersistentStoreDescription

  /// `Version` to which the database needs to be migrated.
  internal let targetVersion: Version

  /// Creates a `Migrator` instance to handle a multi step migration to a given `Version`
  /// - Parameters:
  ///   - sourceStoreDescription: Initial persistent store description.
  ///   - destinationStoreDescription: Final persistent store description.
  ///   - targetVersion: `Version` to which the database needs to be migrated.
  public required init(
    sourceStoreDescription: NSPersistentStoreDescription,
    destinationStoreDescription: NSPersistentStoreDescription,
    targetVersion: Version
  ) {
    self.sourceStoreDescription = sourceStoreDescription
    self.destinationStoreDescription = destinationStoreDescription
    self.targetVersion = targetVersion
    super.init()
    _ = progress  // lazy init for implicit progress support
  }

  /// Creates a `Migrator` instance to handle a multi step migration at `targetStoreDescription` to a given `Version`.
  public convenience init(targetStoreDescription: NSPersistentStoreDescription, targetVersion: Version) {
    self.init(
      sourceStoreDescription: targetStoreDescription, destinationStoreDescription: targetStoreDescription,
      targetVersion: targetVersion)
  }

  /// Migrates the store to a given `Version`, performing a WAL checkpoint if opted in.
  /// - Parameters:
  ///   - targetVersion: The final `Version`.
  ///   - enableWALCheckpoint: Wheter or not a WAL checkpoint needs to be done.
  ///   A dead lock can occur if a NSPersistentStore with a different journaling mode is currently active and using the database file.
  ///   - managerProvider: Closure to provide a custom `NSMigrationManager` instance.
  /// - Throws: It throws an error if the migration fails.
  public func migrate(enableWALCheckpoint: Bool = false, managerProvider: ((Metadata) -> NSMigrationManager)? = nil)
    throws
  {
    guard let sourceURL = sourceStoreDescription.url else {
      fatalError("Source NSPersistentStoreDescription requires a URL.")
    }
    guard let destinationURL = destinationStoreDescription.url else {
      fatalError("Destination NSPersistentStoreDescription requires a URL.")
    }

    try migrateStore(
      from: sourceURL,
      sourceOptions: sourceStoreDescription.options,
      to: destinationURL,
      destinationOptions: destinationStoreDescription.options,
      targetVersion: targetVersion,
      enableWALCheckpoint: enableWALCheckpoint,
      managerProvider: managerProvider)
  }
}

extension Migrator {
  /// Migrates the store at a given source URL to the store at a given destination URL, performing all the migration steps to the target version.
  fileprivate func migrateStore(
    from sourceURL: URL,
    sourceOptions: PersistentStoreOptions? = nil,
    to destinationURL: URL,
    destinationOptions: PersistentStoreOptions? = nil,
    targetVersion: Version,
    enableWALCheckpoint: Bool = false,
    managerProvider: ((Metadata) -> NSMigrationManager)? = nil
  ) throws {
    log.info("Migrator has started, initial store at: \(sourceURL, privacy: .public)")
    let start = DispatchTime.now()
    guard let sourceVersion = try Version(persistentStoreURL: sourceURL) else {
      log.error("A ModelVersion could not be found for the initial store at: \(sourceURL).")
      fatalError("A ModelVersion could not be found for the initial store at: \(sourceURL).")
    }

    guard try CoreDataPlus.isMigrationNecessary(for: sourceURL, to: targetVersion) else {
      log.info("Migration to \(targetVersion.debugDescription, privacy: .public) is not necessary.")
      return
    }

    if enableWALCheckpoint {
      log.debug("Performing a WAL checkpoint.")
      // A dead lock can occur if a NSPersistentStore with a different journaling mode
      // is currently active and using the database file.
      // You need to remove it before performing a WAL checkpoint.
      try performWALCheckpointForStore(at: sourceURL,
                                       storeOptions: sourceOptions,
                                       model: sourceVersion.managedObjectModel())
    }

    let steps = sourceVersion.migrationSteps(to: targetVersion)
    log.debug("Number of steps: \(steps.count, privacy: .public)")

    guard steps.count > 0 else { return }

    let migrationStepsProgress = Progress(
      totalUnitCount: Int64(steps.count), parent: progress, pendingUnitCount: progress.totalUnitCount)
    var currentURL = sourceURL

    for (stepIndex, step) in steps.enumerated() {
      // swiftlint:disable:next line_length
      log.info(
        "Step \(stepIndex + 1, privacy: .public) (of \(steps.count, privacy: .public)) started: \(step.sourceVersion.debugDescription, privacy: .public) to \(step.destinationVersion.debugDescription, privacy: .public)"
      )
      try autoreleasepool {
        let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(
          UUID().uuidString
        )
        .appendingPathExtension("sqlite")
        let mappingModelMigrationProgress = Progress(totalUnitCount: Int64(step.mappingModels.count))
        migrationStepsProgress.addChild(mappingModelMigrationProgress, withPendingUnitCount: 1)

        for (mappingModelIndex, mappingModel) in step.mappingModels.enumerated() {
          log.info("Starting migration for mapping model \(mappingModelIndex + 1, privacy: .public).")
          log.debug(
            "The store at: \(currentURL, privacy: .public) will be migrated in a temporary store at: \(temporaryURL, privacy: .public)"
          )

          let metadata = Metadata(
            sourceVersion: step.sourceVersion,
            sourceModel: step.sourceModel,
            destinationVersion: step.destinationVersion,
            destinationModel: step.destinationModel,
            mappingModel: mappingModel)
          let manager =
            managerProvider?(metadata)
            ?? NSMigrationManager(sourceModel: step.sourceModel, destinationModel: step.destinationModel)
          // a progress reporter handles a parent progress cancellations automatically
          let progressReporter = manager.makeProgressReporter()
          mappingModelMigrationProgress.addChild(progressReporter.progress, withPendingUnitCount: 1)

          let start = DispatchTime.now()

          do {
            try manager.migrateStore(
              from: currentURL,
              type: .sqlite,
              options: sourceOptions,
              mapping: mappingModel,
              to: temporaryURL,
              type: .sqlite,
              options: destinationOptions)
          } catch {
            log.error(
              "Migration for mapping model \(mappingModelIndex + 1, privacy: .public) failed: \(error, privacy: .private)"
            )
            throw error
          }
          let end = DispatchTime.now()
          // Ligthweight migrations don't report progress, the report needs to be marked as finished to proper adjust its progress status.
          progressReporter.markAsFinishedIfNeeded()
          let nanoseconds = end.uptimeNanoseconds - start.uptimeNanoseconds
          let timeInterval = Double(nanoseconds) / Double(NSEC_PER_SEC)
          log.info(
            "Migration for mapping model \(mappingModelIndex + 1, privacy: .public) finished in \(timeInterval, format: .fixed(precision: 2), privacy: .public) seconds."
          )
        }
        // once the migration is done (and the store is migrated to temporaryURL)
        // the store at currentURL can be safely destroyed unless it is the
        // initial store
        if currentURL != sourceURL {
          log.debug("Destroying store at \(currentURL, privacy: .public)")
          try NSPersistentStoreCoordinator.destroyStore(at: currentURL)
        }
        currentURL = temporaryURL
      }
      log.info("Step \(stepIndex + 1, privacy: .public) (of \(steps.count, privacy: .public) completed.")
    }

    // move the store at currentURL to (final) destinationURL
    log.debug(
      "Moving the store at: \(currentURL, privacy: .public) to final store: \(destinationURL, privacy: .public)")
    try NSPersistentStoreCoordinator.replaceStore(at: destinationURL, withPersistentStoreFrom: currentURL)

    // delete the store at currentURL if it's not the initial store
    if currentURL != sourceURL {
      log.debug("Destroying store at: \(currentURL, privacy: .public)")
      try NSPersistentStoreCoordinator.destroyStore(at: currentURL)
    }

    // delete the initial store only if the option is set to true
    if destinationURL != sourceURL {
      log.debug("Destroying initial store at: \(sourceURL, privacy: .public)")
      try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
    }
    let end = DispatchTime.now()
    let nanoseconds = end.uptimeNanoseconds - start.uptimeNanoseconds
    let timeInterval = Double(nanoseconds) / Double(NSEC_PER_SEC)
    log.info(
      "Migrator has finished in \(timeInterval, format: .fixed(precision: 2), privacy: .public) seconds, final store at: \(destinationURL, privacy: .public)"
    )
  }
}

// MARK: - WAL Checkpoint

/// Forces Core Data to perform a checkpoint operation, which merges the data in the `-wal` file to the store file.
private func performWALCheckpointForStore(at storeURL: URL,
                                           storeOptions: PersistentStoreOptions? = nil,
                                           model: NSManagedObjectModel) throws {
  // "If the -wal file is not present, using this approach to add the store won't cause any exceptions,
  // but the transactions recorded in the missing -wal file will be lost." (from: https://developer.apple.com/library/archive/qa/qa1809/_index.html)
  // credits:
  // https://williamboles.me/progressive-core-data-migration/
  // http://pablin.org/2013/05/24/problems-with-core-data-migration-manager-and-journal-mode-wal/
  // https://www.avanderlee.com/swift/write-ahead-logging-wal/
  let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
  var options: PersistentStoreOptions = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
  if let persistentHistoryTokenKey = storeOptions?[NSPersistentHistoryTrackingKey] as? NSNumber,
    persistentHistoryTokenKey.boolValue
  {
    // Once NSPersistentHistoryTrackingKey is enabled, it can't be reverted back.
    // During a WAL checkpoint this step prevents this warning in the console:
    // "Store opened without NSPersistentHistoryTrackingKey but previously had been opened
    // with NSPersistentHistoryTrackingKey - Forcing into Read Only mode store at ..."
    // https://developer.apple.com/forums/thread/118924
    options[NSPersistentHistoryTrackingKey] = [NSPersistentHistoryTrackingKey: true as NSNumber]
  }

  let store = try persistentStoreCoordinator.addPersistentStore(type: .sqlite,
                                                                configuration: nil, 
                                                                at: storeURL,
                                                                options: options)

  try persistentStoreCoordinator.remove(store)
}

extension Migrator {
  /// Metadata about a single migration phase.
  public struct Metadata {
    let sourceVersion: Version
    let sourceModel: NSManagedObjectModel
    let destinationVersion: Version
    let destinationModel: NSManagedObjectModel
    let mappingModel: NSMappingModel

    fileprivate init(
      sourceVersion: Version,
      sourceModel: NSManagedObjectModel,
      destinationVersion: Version,
      destinationModel: NSManagedObjectModel,
      mappingModel: NSMappingModel
    ) {
      self.sourceVersion = sourceVersion
      self.sourceModel = sourceModel
      self.destinationVersion = destinationVersion
      self.destinationModel = destinationModel
      self.mappingModel = mappingModel
    }
  }
}

// About NSPersistentStoreRemoteChangeNotificationPostOptionKey and migrations
// https://developer.apple.com/forums/thread/118924
//
// That error is because you also removed the history tracking option. Which you shouldn't do after you've enabled it.
// You can disable CloudKit sync simply by setting the cloudKitContainer options property on your store description to nil.
// However, you should leave history tracking on so that NSPersitentCloudKitContainer can catch up if you turn it on again.
//
// About logs:
// https://developer.apple.com/documentation/os/logging/generating_log_messages_from_your_code
