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
    self.destinationVersion = destinationVersion.rawValue
    self.destinationModel = destinationVersion.managedObjectModel()
    self.mappingModels = mappingModels
  }
}
