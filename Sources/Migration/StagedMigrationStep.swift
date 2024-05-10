// CoreDataPlus

import CoreData

// Representation of a Core Data staged migration step.
@available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, macCatalystApplicationExtension 17.0, *)
public struct StagedMigrationStep<Version: ModelVersion> {
  public let sourceVersion: Version
  public let sourceModelReference: NSManagedObjectModelReference
  public let destinationVersion: Version
  public let destinationModelReference: NSManagedObjectModelReference
  public let stages: [NSMigrationStage]
  
  init?(sourceVersion: Version, destinationVersion: Version) {
    guard let stages = sourceVersion.migrationStagesToNextModelVersion() else {
      return nil
    }
    self.sourceVersion = sourceVersion
    self.sourceModelReference = sourceVersion.managedObjectModelReference()
    self.destinationVersion = destinationVersion
    self.destinationModelReference = destinationVersion.managedObjectModelReference()
    self.stages = stages
  }
}
