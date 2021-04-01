// CoreDataPlus

import CoreData

/// Describes a Core Data model file exention type based on the
///
/// [Model File Format and Versions](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmModelFormat.html)
///
/// An `.xcdatamodeld` document is a file package that groups versions of the model, each represented by an individual `.xcdatamodel` file,
/// and an Info.plist file that contains the version information.
/// The model is compiled into a runtime format—a file package with a `.momd` extension that contains individually compiled model files with a `.mom` extension
/// documentation.
private enum ModelVersionFileExtension {
  /// Extension for a compiled version of a model file package (`.xcdatamodeld`).
  static let momd = "momd"
  /// Extension for a compiled version of a *versioned* model file (`.xcdatamodel`).
  static let mom  = "mom"
  /// Extension for an optimized version for the '.mom' file.
  static let omo  = "omo"
  /// Extension for a compiled version of a mapping model file (`.xcmappingmodel`).
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
  /// Initializes a `CoreDataModelVersion` from a `NSPersistentStore` URL; returns nil if a `CoreDataModelVersion` hasn't been correctly defined.
  /// - Throws: It throws an error if no store is found at `persistentStoreURL` or if there is a problem accessing its contents.
  public init?(persistentStoreURL: URL) throws {
    let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: persistentStoreURL, options: nil)
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

  /// `AnyIterator` to iterate all the successors steps after `self`.
  func successorsIterator() -> AnyIterator<Self> {
    var version: Self = self
    return AnyIterator {
      guard let next = version.successor else { return nil }

      version = next
      return version
    }
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
  let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType,
                                                                             at: storeURL,
                                                                             options: nil)
  let targetModel = version.managedObjectModel()
  // https://vimeo.com/164904652
  // - configurations define named subsets of a model that contain some but not all entities.
  // - configuration set to nil uses the Default configuration (all entities in the model)
  // - multiple stores with different configurations (loaded with a NSPersistentContainer or added with a
  // NSPersistentStoreCoordinator), have internally the full schema with all the entities; their configuration may define a subset of the entities but the underlying .sqlite file will have all the entities.
  // - if multiple configurations contain the same entities, objects are saved in the first-added store (whose configuration includes that entity) or they can be assigned to another store with the NSManagedObjectContext method assign(object:to:) (before saving).
  // - trying to assign an object to a store whose configuration doesn't include that particular entity will cause an error: 'Can't assign an object to a store that does not contain the object's entity.'
  // - if an entity gets changed, then all the stores need to be migrated one by one (probably because all the underlying .sqlite files have to be properly migrated even if the entities are not used); for that reason, passing a configuration name or nil to isConfiguration(withName:compatibleWithStoreMetadata:) will always result in a false value (migration needed).
  let isCompatible = targetModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)

  if isCompatible {
    return false // current and target versions are the same
  } else if let currentVersion = Version[metadata] {
    let iterator = currentVersion.successorsIterator()
    while let nextVersion = iterator.next() {
      if nextVersion == version { return true }
    }
    // can't migrate to a version not defined as a successor step
    // (target version is probably a prior version of the current one)
    return false
  } else {
    // fallback
    return false
  }
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
