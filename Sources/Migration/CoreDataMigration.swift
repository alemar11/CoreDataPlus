//
// CoreDataPlus
//
// Copyright © 2016-2020 Tinrobots.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmLightweightMigration.html
// https://developer.apple.com/documentation/coredata/heavyweight_migration
// https://www.objc.io/issues/4-core-data/core-data-migration/

import CoreData

public struct CoreDataMigration {
  private init() { }

  /// **CoreDataPlus**
  ///
  /// Migrates a store to a given version.
  ///
  /// - Parameters:
  ///   - sourceURL: the current store URL.
  ///   - targetVersion: the ModelVersion to which the store is needed to migrate to.
  ///   - progress: a Progress instance to monitor the migration.
  /// - Throws: It throws an error in cases of failure.
  public static func migrateStore<Version: CoreDataModelVersion>(at sourceURL: URL, targetVersion: Version, progress: Progress? = nil) throws {
    try migrateStore(from: sourceURL, to: sourceURL, targetVersion: targetVersion, deleteSource: false, progress: progress)
  }

  /// **CoreDataPlus**
  ///
  /// Migrates a store to a given version.
  ///
  /// - Parameters:
  ///   - sourceURL: the current store URL.
  ///   - targetURL: the store URL after the migration phase.
  ///   - targetVersion: the ModelVersion to which the store is needed to migrate to.
  ///   - deleteSource: if `true` the initial store will be deleted after the migration phase.
  ///   - progress: a Progress instance to monitor the migration.
  /// - Throws: It throws an error in cases of failure.
  public static func migrateStore<Version: CoreDataModelVersion>(from sourceURL: URL, to targetURL: URL, targetVersion: Version, deleteSource: Bool = false, progress: Progress? = nil) throws {
    guard FileManager.default.fileExists(atPath: sourceURL.relativePath) else {
      return //TODO: add error and tests
    }

    guard let sourceVersion = Version(persistentStoreURL: sourceURL as URL) else {
      fatalError("A ModelVersion for the store at URL \(sourceURL) could not be found.")
    }

    do {
      guard try sourceVersion.isMigrationPossible(for: sourceURL, to: targetVersion) else {
        return
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
    } catch {
      throw NSError.migrationFailed(underlyingError: error)
    }
  }
}
