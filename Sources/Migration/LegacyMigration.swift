// CoreDataPlus

import CoreData

/// Handles migrations with the old `NSMigrationManager`.
public protocol LegacyMigration {
  /// Returns a list of mapping models needed to migrate the current version of the database to the next one.
  func mappingModelsToNextModelVersion() -> [NSMappingModel]?
}

// MARK: - MigrationStep

extension ModelVersion where Self: LegacyMigration {
  /// Returns a list of `MigrationStep` needed to mirate to the next `version` of the store.
  public func migrationSteps(to version: Self) -> [LegacyMigrationStep<Self>] {
    guard self != version else {
      return []
    }

    guard let nextVersion = next else {
      return []
    }

    guard let step = LegacyMigrationStep(sourceVersion: self, destinationVersion: nextVersion) else {
      fatalError("Couldn't find any mapping models.")
    }

    return [step] + nextVersion.migrationSteps(to: version)
  }

  /// Returns a `NSMappingModel` that specifies how to map a model to the next version model.
  public func mappingModelToNextModelVersion() -> NSMappingModel? {
    guard let nextVersion = next else {
      return nil
    }

    guard
      let mappingModel = NSMappingModel(
        from: [modelBundle], forSourceModel: managedObjectModel(), destinationModel: nextVersion.managedObjectModel())
    else {
      fatalError("No NSMappingModel found for \(self) to \(nextVersion).")
    }

    return mappingModel
  }

  /// Returns a newly created mapping model that will migrate data from the source to the destination model.
  ///
  /// - Note:
  /// A model will be created only if all changes are simple enough to be able to reasonably infer a mapping such as:
  ///
  ///  - Adding, removing, and renaming attributes
  ///  - Adding, removing, and renaming relationships
  ///  - Adding, removing, and renaming entities
  ///  - Changing the optional status of attributes
  ///  - Adding or removing indexes on attributes
  ///  - Adding, removing, or changing compound indexes on entities
  ///  - Adding, removing, or changing unique constraints on entities
  ///
  ///  There are a few gotchas to this list:
  ///
  /// - if you change an attribute from optional to non-optional, specify a default value.
  /// - changing indexes (on attributes as well as compound indexes) won’t be picked up as a model change; specify a hash modifier on the changed
  /// attributes or entities in order to force Core Data to do the right thing during migration.
  public func inferredMappingModelToNextModelVersion() -> NSMappingModel? {
    guard let nextVersion = next else {
      return nil
    }

    return try? NSMappingModel.inferredMappingModel(forSourceModel: managedObjectModel(),
                                                    destinationModel: nextVersion.managedObjectModel())
  }

  /// - Returns: a list of `NSMappingModel` from a list of mapping model names.
  /// - Note: The mapping models must be inside the NSBundle object containing the model file.
  public func mappingModels(for mappingModelNames: [String]) -> [NSMappingModel] {
    var results = [NSMappingModel]()

    guard mappingModelNames.count > 0 else {
      return results
    }

    guard
      let allMappingModelsURLs = modelBundle.urls(forResourcesWithExtension: ModelVersionFileExtension.cdm,
                                                  subdirectory: nil),
      allMappingModelsURLs.count > 0
    else {
      return results
    }

    for name in mappingModelNames {
      let expectedFileName = "\(name).\(ModelVersionFileExtension.cdm)"
      if let url = allMappingModelsURLs.first(where: { $0.lastPathComponent == expectedFileName }),
         let mappingModel = NSMappingModel(contentsOf: url)
      {
        results.append(mappingModel)
      }
    }

    return results
  }
}
