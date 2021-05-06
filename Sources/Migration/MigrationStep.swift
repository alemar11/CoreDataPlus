// CoreDataPlus

import CoreData

public final class MigrationStep<Version: ModelVersion> {
  public let sourceVersion: Version.RawValue
  public let sourceModel: NSManagedObjectModel
  public let destinationVersion: Version.RawValue
  public let destinationModel: NSManagedObjectModel
  public let mappingModels: [NSMappingModel]

  init?(sourceVersion: Version, destinationVersion: Version) {
    guard let mappingModels = sourceVersion.mappingModelsToNextModelVersion() else {
      return nil
    }
    self.sourceVersion = sourceVersion.rawValue
    self.sourceModel = sourceVersion.managedObjectModel()
    self.destinationVersion = sourceVersion.rawValue
    self.destinationModel = destinationVersion.managedObjectModel()
    self.mappingModels = mappingModels
  }
}
