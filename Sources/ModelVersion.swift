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

private enum ModelVersionExtension {
  static let momd = "momd"
  static let omo  = "omo"
  static let mom  = "mom"
}

/// **CoreDataPlus**
///
/// Types adopting the `ModelVersion` protocol can be used to describe a Core Data Model and its versioning.
public protocol ModelVersion: Equatable {

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersion`.
  ///
  /// List with all versions until now.
  static var allVersions: [Self] { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersion`.
  ///
  /// Current model version.
  static var currentVersion: Self { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersion`.
  ///
  /// Version name.
  var versionName: String { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersion`.
  ///
  /// The next `ModelVersion` in the progressive migration.
  var successor: Self? { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersion`.
  ///
  /// NSBundle object containing the model file.
  var modelBundle: Bundle { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersion`.
  ///
  /// Model name.
  var modelName: String { get }


  func mappingModelsToNextModelVersion() -> [NSMappingModel]?
}

extension ModelVersion {

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersion`.
  ///
  /// Model file name.
  var momd: String { return "\(modelName).\(ModelVersionExtension.momd)" }

}

extension ModelVersion {

  /// **CoreDataPlus**
  ///
  /// Initializes a ModelVersion from a `NSPersistentStore` URL.
  public init?(persistentStoreURL: URL) {
    guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: persistentStoreURL, options: nil) else {
      return nil
    }

    let version = Self.allVersions.first {
      $0.managedObjectModel().isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
    }

    guard let modelVersion = version else {
      return nil
    }

    self = modelVersion
  }

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersion`.
  ///
  /// Return the NSManagedObjectModel for this `ModelVersion`.
  public func managedObjectModel() -> NSManagedObjectModel {
    let momURL = modelBundle.url(forResource: versionName, withExtension: "\(ModelVersionExtension.mom)", subdirectory: momd)

    /**
     As of iOS 11, Apple is advising that opening the .omo file for a managed object model is not supported, since the file format can change from release to release
     **/
    // let omoURL = modelBundle.url(forResource: versionName, withExtension: "\(ModelVersionKey.omo)", subdirectory: momd)
    // guard let url = omoURL ?? momURL else { fatalError("Model version \(self) not found.") }

    guard let url = momURL else {
      preconditionFailure("Model version '\(self)' not found.")
    }

    guard let model = NSManagedObjectModel(contentsOf: url) else {
      preconditionFailure("Error initializing Managed Object Model: cannot open model at \(url).")
    }

    return model
  }

  /// Returns a list of mapping models needed to migrate the current version of the database to the next one.
  /// - Note: By default it calls on // TODO
  public func mappingModelsToNextModelVersion() -> [NSMappingModel]? {
    guard let mapping = mappingModelToNextModelVersion() else {
      return nil
    }

    return [mapping]
  }

  /// Returns a `NSMappingModel` for a 
  public func mappingModelToNextModelVersion() -> NSMappingModel? {
    guard let nextVersion = successor else {
      return nil
    }

    guard let mappingModel = NSMappingModel(from: [modelBundle], forSourceModel: managedObjectModel(), destinationModel: nextVersion.managedObjectModel()) else {
      fatalError("No mapping model found for \(self) to \(nextVersion).")
    }

    return mappingModel
  }

  /// Returns a newly created mapping model that will migrate data from the source to the destination model.
  /// A model will be created only if all changes are simple enough to be able to reasonably infer a mapping
  /// (for example, removing or renaming an attribute, adding an optional attribute or relationship, or adding renaming or deleting an entity).
  /// Element IDs are used to track renamed properties and entities.
  public func inferredMappingModelToNextModelVersion() -> NSMappingModel? {
    guard let nextVersion = successor else {
      return nil
    }

    /*
     INFERRED MAPPING MODEL LIMITATIONS
    Adding, removing, and renaming attributes
    Adding, removing, and renaming relationships
    Adding, removing, and renaming entities
    Changing the optional status of attributes
    Adding or removing indexes on attributes
    Adding, removing, or changing compound indexes on entities
    Adding, removing, or changing unique constraints on entities
    There are a few gotchas to this list. First, if you change an attribute from optional to non-optional, you have to specify a default value. The second, more subtle pitfall is that changing indexes (on attributes as well as compound indexes) won’t be picked up as a model change. You have to specify a hash modifier on the changed attributes or entities in order to force Core Data to do the right thing during migration.
     */

    do {
    return try NSMappingModel.inferredMappingModel(forSourceModel: managedObjectModel(), destinationModel: nextVersion.managedObjectModel())
    } catch {
      print(error)
      return nil
    }
  }

  public func migrationSteps(to version: Self) -> [MigrationStep] {
    guard self != version else {
      return []
    }

    guard let mappings = mappingModelsToNextModelVersion(), let nextVersion = successor else {
      fatalError("Couldn't find mapping models")
    }

    let step = MigrationStep(source: managedObjectModel(), destination: nextVersion.managedObjectModel(), mappings: mappings)

    return [step] + nextVersion.migrationSteps(to: version)
  }

}

extension ModelVersion {

  /// **CoreDataPlus**
  ///
  /// The next model version.
  public var successor: Self? { return nil }

}

public final class MigrationStep {
  var source: NSManagedObjectModel
  var destination: NSManagedObjectModel
  var mappings: [NSMappingModel]

  init(source: NSManagedObjectModel, destination: NSManagedObjectModel, mappings: [NSMappingModel]) {
    self.source = source
    self.destination = destination
    self.mappings = mappings
  }
}

// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmLightweightMigration.html
// https://developer.apple.com/documentation/coredata/heavyweight_migration
// https://www.objc.io/issues/4-core-data/core-data-migration/
public func migrateStore<Version: ModelVersion>(from sourceURL: URL, to targetURL: URL, targetVersion: Version, deleteSource: Bool = false, progress: Progress? = nil) throws {
  guard let sourceVersion = Version(persistentStoreURL: sourceURL as URL) else {
    fatalError("unknown store version at URL \(sourceURL)")
  }

  var currentURL = sourceURL
  let migrationSteps = sourceVersion.migrationSteps(to: targetVersion)
  var migrationProgress: Progress?
  // https://github.com/objcio/issue-4-core-data-migration/blob/02002c93a4531ebcf8f40ee4c77986d01abc790e/BookMigration/MHWMigrationManager.m
  let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: sourceURL, options: nil)
  let finalModel = targetVersion.managedObjectModel()

  guard !finalModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) else {
    // TODO: check if the initial and final version are the same
    return
  }

  if let p = progress {
    migrationProgress = Progress(totalUnitCount: Int64(migrationSteps.count), parent: p, pendingUnitCount: p.totalUnitCount)
  }

  for step in migrationSteps {
    //TODO: autoreleasepool
    migrationProgress?.becomeCurrent(withPendingUnitCount: 1)
    let manager = NSMigrationManager(sourceModel: step.source, destinationModel: step.destination)
    migrationProgress?.resignCurrent()
    let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)

    for mapping in step.mappings {
      try manager.migrateStore(from: currentURL, sourceType: NSSQLiteStoreType, options: nil, with: mapping, toDestinationURL: destinationURL, destinationType: NSSQLiteStoreType, destinationOptions: nil)
    }

    if currentURL != sourceURL {
      NSPersistentStoreCoordinator.destroyStore(at: currentURL)
    }
    currentURL = destinationURL
  }

  try NSPersistentStoreCoordinator.replaceStore(at: targetURL, withStoreAt: currentURL)

  if (currentURL != sourceURL) {
    NSPersistentStoreCoordinator.destroyStore(at: currentURL)
  }

  if (targetURL != sourceURL && deleteSource) {
    NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
  }
}

