// CoreDataPlus

import CoreData

/// Provides a `Progress` instance during a `NSMigrationManager` migration phase.
public final class MigrationProgressReporter: NSObject, ProgressReporting {
  /// Migration progress.
  public private(set) lazy var progress: Progress = {
    let progress = Progress(totalUnitCount: Int64(totalUnitCount))
    progress.cancellationHandler = { [weak self] in
      self?.cancel()
    }
    progress.pausingHandler = nil // not supported
    return progress
  }()

  private let totalUnitCount: Int64 = 100
  private let manager: NSMigrationManager
  private var token: NSKeyValueObservation?

  public init(manager: NSMigrationManager) {
    self.manager = manager
    super.init()
    self.token = manager.observe(\.migrationProgress, options: [.new]) { [weak self] (_, change) in
      guard let self = self else { return }

      if let newProgress = change.newValue {
        self.progress.completedUnitCount = Int64(newProgress * Float(self.totalUnitCount))
      }
    }
    // force lazy init for implicit progress support
    // https://developer.apple.com/documentation/foundation/progress
    _ = progress
  }

  deinit {
    token?.invalidate()
    token = nil
  }

  /// Marks the progress as finished if it's not already.
  /// - Note: Since lightweight migrations don't support progress, this method ensures that a lightweight migration is at least finished.
  public func markAsFinishedIfNeeded() {
    if !progress.isFinished {
      progress.completedUnitCount = progress.totalUnitCount
    }
  }

  func cancel() {
    let error = NSError.migrationCancelled
    manager.cancelMigrationWithError(error)
  }
}

public extension NSMigrationManager {
  /// Creates a new `MigrationProgressReporter` for the migration manager.
  func makeProgressReporter() -> MigrationProgressReporter {
    MigrationProgressReporter(manager: self)
  }
}

public extension NSError {
  /// NSError generated when a migration is cancelled by a `Progress` cancel method.
  static let migrationCancelled: NSError = {
    let info: [String: Any] = [NSDebugDescriptionErrorKey: "Progress has cancelled this migration."]
    return NSError(domain: bundleIdentifier, code: NSMigrationCancelledError, userInfo: info)
  }()
}
