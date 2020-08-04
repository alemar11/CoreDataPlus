// CoreDataPlus

import CoreData

/// Describes a Core Data model file exention type based on the
/// [Model File Format and Versions](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmModelFormat.html)
/// documentation.
private enum ModelVersionFileExtension {
  /// The extension for a model bundle, or a `.xcdatamodeld` file package.
  static let momd = "momd"
  /// The extension for a versioned model file, or a `.xcdatamodel` file.
  static let mom  = "mom"
  /// The extension for an optimized version for the '.mom' file
  static let omo  = "omo"
  /// The extension for a mapping model file, or a `.xcmappingmodel` file.
  static let cdm  = "cdm"
}

/// **CoreDataPlus**
///
/// Types adopting the `CoreDataModelVersion` protocol can be used to describe a Core Data Model and its versioning.
public protocol CoreDataModelVersion: Equatable, RawRepresentable {
  /// **CoreDataPlus**
  ///
  /// Protocol `CoreDataModelVersion`.
  ///
  /// List with all versions until now.
  static var allVersions: [Self] { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `CoreDataModelVersion`.
  ///
  /// Current model version.
  static var currentVersion: Self { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `CoreDataModelVersion`.
  ///
  /// Version name.
  var versionName: String { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `CoreDataModelVersion`.
  ///
  /// The next `CoreDataModelVersion` in the progressive migration.
  var successor: Self? { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `CoreDataModelVersion`.
  ///
  /// NSBundle object containing the model file.
  var modelBundle: Bundle { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `CoreDataModelVersion`.
  ///
  /// Model name.
  var modelName: String { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersions`.
  ///
  /// Return the NSManagedObjectModel for this `CoreDataModelVersion`.
  func managedObjectModel() -> NSManagedObjectModel

  /// **CoreDataPlus**
  ///
  /// Protocol `CoreDataModelVersion`.
  ///
  /// Returns a list of mapping models needed to migrate the current version of the database to the next one.
  func mappingModelsToNextModelVersion() -> [NSMappingModel]?
}

extension CoreDataModelVersion {
  /// **CoreDataPlus**
  ///
  /// Protocol `CoreDataModelVersion`.
  ///
  /// Model file name.
  var momd: String { return "\(modelName).\(ModelVersionFileExtension.momd)" }
}

extension CoreDataModelVersion {
  /// **CoreDataPlus**
  ///
  // Searches for the first CoreDataModelVersion whose model is compatible with the persistent store metedata
  public static subscript(_ metadata: [String: Any]) -> Self? {
    let version = Self.allVersions.first {
      $0.managedObjectModel().isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
    }

    return version
  }

  /// **CoreDataPlus**
  ///
  /// Initializes a `CoreDataModelVersion` from a `NSPersistentStore` URL.
  public init?(persistentStoreURL: URL) {
    guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: persistentStoreURL, options: nil) else {
      return nil
    }

    let version = Self[metadata]

    guard let modelVersion = version else {
      return nil
    }

    self = modelVersion
  }

  /// **CoreDataPlus**
  ///
  /// Protocol `CoreDataModelVersion`.
  ///
  /// Returns the NSManagedObjectModel for this `CoreDataModelVersion`.
  public func managedObjectModel() -> NSManagedObjectModel {
    return _managedObjectModel()
  }

  // swiftlint:disable:next identifier_name
  internal func _managedObjectModel() -> NSManagedObjectModel {
    let momURL = modelBundle.url(forResource: versionName, withExtension: "\(ModelVersionFileExtension.mom)", subdirectory: momd)

    //  As of iOS 11, Apple is advising that opening the .omo file for a managed object model is not supported, since the file format can change from release to release
    // let omoURL = modelBundle.url(forResource: versionName, withExtension: "\(ModelVersionExtension.omo)", subdirectory: momd)
    // guard let url = omoURL ?? momURL else { fatalError("Model version \(self) not found.") }

    guard let url = momURL else {
      preconditionFailure("Model version '\(self)' not found.")
    }

    guard let model = NSManagedObjectModel(contentsOf: url) else {
      preconditionFailure("Error initializing the NSManagedObjectModel: cannot open the model at \(url).")
    }

    return model
  }
}

// MARK: - Migration

/// **CoreDataPlus**
///
/// Returns `true` if a migration to a given `CoreDataModelVersion` is necessary for the persistent store at a given `URL`.
///
/// - Parameters:
///   - storeURL: the current store URL.
///   - version: the ModelVersion to which the store is compared.
/// - Throws: It throws an error in cases of failure.
public func isMigrationNecessary<Version: CoreDataModelVersion>(for storeURL: URL, to version: Version) throws -> Bool {
  // Before you initiate a migration process, you should first determine whether it is necessary.
  // If the target model configuration is compatible with the persistent store metadata, there is no need to migrate
  // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmCustomizing.html#//apple_ref/doc/uid/TP40004399-CH8-SW2
  let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil)
  let targetModel = version.managedObjectModel()
  return !targetModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
}

extension CoreDataModelVersion {
  /// **CoreDataPlus**
  ///
  /// Returns a list of `MigrationStep` needed to mirate to the next `version` of the store.
  public func migrationSteps(to version: Self) -> [CoreDataMigration.Step] {
    guard self != version else {
      return []
    }

    guard let mappings = mappingModelsToNextModelVersion(), let nextVersion = successor else {
      fatalError("Couldn't find any mapping models.")
    }

    let step = CoreDataMigration.Step(source: managedObjectModel(), destination: nextVersion.managedObjectModel(), mappings: mappings)

    return [step] + nextVersion.migrationSteps(to: version)
  }

  /// **CoreDataPlus**
  ///
  /// Returns a `NSMappingModel` that specifies how to map a model to the next version model.
  public func mappingModelToNextModelVersion() -> NSMappingModel? {
    guard let nextVersion = successor else {
      return nil
    }

    guard let mappingModel = NSMappingModel(from: [modelBundle], forSourceModel: managedObjectModel(), destinationModel: nextVersion.managedObjectModel()) else {
      fatalError("No NSMappingModel found for \(self) to \(nextVersion).")
    }

    return mappingModel
  }

  /// **CoreDataPlus**
  ///
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
    guard let nextVersion = successor else {
      return nil
    }

    return try? NSMappingModel.inferredMappingModel(forSourceModel: managedObjectModel(), destinationModel: nextVersion.managedObjectModel())
  }

  /// **CoreDataPlus**
  ///
  /// - Returns: Returns a list of `NSMappingModel` given a list of mapping model names.
  /// - Note: The mapping models must be inside the NSBundle object containing the model file.
  public func mappingModels(for mappingModelNames: [String]) -> [NSMappingModel] {
    var results = [NSMappingModel]()

    guard mappingModelNames.count > 0 else {
      return results
    }

    guard
      let allMappingModelsURLs = modelBundle.urls(forResourcesWithExtension: ModelVersionFileExtension.cdm, subdirectory: nil),
      allMappingModelsURLs.count > 0 else {
        return results
    }

    mappingModelNames.forEach { name in
      let expectedFileName = "\(name).\(ModelVersionFileExtension.cdm)"
      if
        let url = allMappingModelsURLs.first(where: { $0.lastPathComponent == expectedFileName }),
        let mappingModel = NSMappingModel(contentsOf: url) {
        results.append(mappingModel)
      }
    }

    return results
  }
}
