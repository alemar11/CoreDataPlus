// 
// CoreDataPlus
//
// Copyright © 2016-2018 Tinrobots.
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

import CoreData

public func migrateStore<Version: ModelVersion>(at sourceURL: URL, targetVersion: Version, progress: Progress? = nil) throws {
  try migrateStore(from: sourceURL, to: sourceURL, targetVersion: targetVersion, deleteSource: false, progress: progress)
}

// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmLightweightMigration.html
// https://developer.apple.com/documentation/coredata/heavyweight_migration
// https://www.objc.io/issues/4-core-data/core-data-migration/
// https://github.com/objcio/issue-4-core-data-migration/blob/02002c93a4531ebcf8f40ee4c77986d01abc790e/BookMigration/MHWMigrationManager.m
public func migrateStore<Version: ModelVersion>(from sourceURL: URL, to targetURL: URL, targetVersion: Version, deleteSource: Bool = false, progress: Progress? = nil) throws {
  guard let sourceVersion = Version(persistentStoreURL: sourceURL as URL) else {
    fatalError("unknown store version at URL \(sourceURL)")
  }

  do {
    let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: sourceURL, options: nil)
    let finalModel = targetVersion.managedObjectModel()

    // Avoid unnecessary migrations
    guard !finalModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) else {
      return
    }
  } catch {
    throw CoreDataPlusError.migrationFailed(error: error)
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

  do {
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

    if (currentURL != sourceURL) {
      try NSPersistentStoreCoordinator.destroyStore(at: currentURL)
    }

    if (targetURL != sourceURL && deleteSource) {
      try NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
    }

  } catch {
    throw CoreDataPlusError.migrationFailed(error: error)
  }

}
