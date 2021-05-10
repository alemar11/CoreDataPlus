// CoreDataPlus

import CoreData

public final class MigrationStep<Version: ModelVersion> {
  public let sourceVersion: Version
  public let sourceModel: NSManagedObjectModel
  public let destinationVersion: Version
  public let destinationModel: NSManagedObjectModel
  public let mappingModels: [NSMappingModel]

  init?(sourceVersion: Version, destinationVersion: Version) {
    guard let mappingModels = sourceVersion.mappingModelsToNextModelVersion() else {
      return nil
    }
    self.sourceVersion = sourceVersion
    self.sourceModel = sourceVersion.managedObjectModel()
    self.destinationVersion = destinationVersion
    self.destinationModel = destinationVersion.managedObjectModel()
    self.mappingModels = mappingModels
  }
}
