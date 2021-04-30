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
      self?.cancel()
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

  private var error: Error?

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

  //let lock = NSLock()

  open override func cancelMigrationWithError(_ error: Error) {
//    lock.lock()
//    defer { lock.unlock() }
    // TODO: lock
    if !progress.isCancelled {
      self.error = error
      progress.cancel()
    }
  }

  private func cancel() {
    let error = self.error ?? NSError.migrationCancelled
    self.error = nil // the NSMigrationManager instance may be used for multiple migrations
    super.cancelMigrationWithError(error)
  }
}

extension NSError {
  static let migrationCancelled = NSError(domain: bundleIdentifier, code: NSMigrationCancelledError, userInfo: nil)
}
