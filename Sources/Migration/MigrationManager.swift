// CoreDataPlus

import CoreData
import Foundation

/// A subclass of `NSMigrationManager` conforming to `ProgressReporting`.
/// - Note: When you use a custom `NSMigrationManager`, Core Data ignores `usesStoreSpecificMigrationManager`, because you are using a custom manager class.
open class MigrationManager: NSMigrationManager, ProgressReporting {

  // MARK: - ProgressReporting

  public private(set) lazy var progress: Progress = {
    let progress = Progress(totalUnitCount: 100)
    progress.cancellationHandler = { [weak self] in
      let error = NSError(domain: bundleIdentifier, code: NSMigrationCancelledError, userInfo: nil)
      self?.cancel(error)
    }
    return progress
  }()


  // MARK: - NSObject

  open override func didChangeValue(forKey key: String) {
    guard key == #keyPath(NSMigrationManager.migrationProgress) else { return }

    progress.completedUnitCount = max(progress.completedUnitCount,
                                      Int64(Float(progress.totalUnitCount) * self.migrationProgress)
    )
    print("🚩", progress.completedUnitCount, self.migrationProgress)
  }

  // MARK: - NSMigrationManager

  open override func migrateStore(from sourceURL: URL,
                             sourceType sStoreType: String,
                             options sOptions: [AnyHashable : Any]? = nil,
                             with mappings: NSMappingModel?,
                             toDestinationURL dURL: URL,
                             destinationType dStoreType: String,
                             destinationOptions dOptions: [AnyHashable : Any]? = nil) throws {
    progress.completedUnitCount = 0 // the NSMigrationManager instance may be used for multiple migrations
    try super.migrateStore(from: sourceURL,
                       sourceType: sStoreType,
                       options: sOptions,
                       with: mappings,
                       toDestinationURL: dURL,
                       destinationType: dStoreType,
                       destinationOptions: dOptions)
  }

  open override func cancelMigrationWithError(_ error: Error) {
    // TODO: lock
    if !progress.isCancelled {
      progress.cancel()
    }
  }

  private func cancel(_ error: Error) {
    super.cancelMigrationWithError(error)
  }
}
