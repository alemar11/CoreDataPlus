// CoreDataPlus

import CoreData

/// Handles migrations with the new `NSStagedMigrationManager`.
/// - Note: `NSStagedMigrationManager` requires `NSMigratePersistentStoresAutomaticallyOption` and `NSInferMappingModelAutomaticallyOption` set to to *true*.
public protocol StagedMigration {
  /// Returns the current `NSManagedObjectModelReference`.
  @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
  func managedObjectModelReference() -> NSManagedObjectModelReference
  
  /// The Base64-encoded 128-bit model version hash.
  @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
  var versionChecksum: String { get }
  
  /// - Returns a `NSMigrationStage` needed to migrate to the next `version` of the store.
  @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
  func migrationStageToNextModelVersion() -> NSMigrationStage?
}

// MARK: - NSMigrationStage

extension ModelVersion where Self: StagedMigration {
  @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
  public var versionChecksum: String {
    managedObjectModel().versionChecksum
  }
  
  /// Protocol `StagedMigration`.
  ///
  /// Returns the `NSManagedObjectModelReference` for this `ModelVersion`.
  @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
  public func managedObjectModelReference() -> NSManagedObjectModelReference {
    .init(model: managedObjectModel(), versionChecksum: versionChecksum)
  }

  /// Protocol `StagedMigration`.
  ///
  /// Returns a `NSMigrationStage` needed to migrate to the next `version` of the store.
  @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
  public func migrationStageToNextModelVersion() -> NSMigrationStage? {
    return nil
  }
}

// MARK: - StagedMigrationStep

extension ModelVersion where Self: StagedMigration  {
  /// Returns a list of `StagedMigrationStep` needed to mirate to the next `version` of the store.
  @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
  public func stagedMigrationSteps(to version: Self) -> [StagedMigrationStep<Self>] {
    guard self != version else {
      return []
    }

    guard let nextVersion = next else {
      return []
    }

    guard let step = StagedMigrationStep(sourceVersion: self, destinationVersion: nextVersion) else {
      fatalError("Couldn't find any mapping stages.")
    }

    return [step] + nextVersion.stagedMigrationSteps(to: version)
  }
}
