// CoreDataPlus

import CoreData

extension Migration {
  /// Represents a single step during a migration process.
  public final class Step {
    public let sourceModel: NSManagedObjectModel
    public let destinationModel: NSManagedObjectModel
    public let mappingModels: [NSMappingModel]

    init(source: NSManagedObjectModel, destination: NSManagedObjectModel, mappings: [NSMappingModel]) {
      self.sourceModel = source
      self.destinationModel = destination
      self.mappingModels = mappings
    }
  }
}

public final class MigrationStep<Version: ModelVersion> {
  public let sourceVersionName: String
  public let sourceModel: NSManagedObjectModel
  public let destinationVersionName: String
  public let destinationModel: NSManagedObjectModel
  public let mappingModels: [NSMappingModel]

  init?(sourceVersion: Version, destinationVersion: Version) {
    guard let mappingModels = sourceVersion.mappingModelsToNextModelVersion() else {
      return nil
    }
    self.sourceVersionName = sourceVersion.modelName
    self.sourceModel = sourceVersion.managedObjectModel()
    self.destinationVersionName = destinationVersion.modelName
    self.destinationModel = destinationVersion.managedObjectModel()
    self.mappingModels = mappingModels
  }
}
