// CoreDataPlus

import CoreData

/// Describes a Core Data model file exention type
///
/// [Model File Format and Versions](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmModelFormat.html)
///
/// An `.xcdatamodeld` document is a file package that groups versions of the model, each represented by an individual `.xcdatamodel` file,
/// and an Info.plist file that contains the version information.
/// The model is compiled into a runtime format—a file package with a `.momd` extension that contains individually compiled model files with a `.mom` extension
/// documentation.
internal enum ModelVersionFileExtension {
  /// Extension for a compiled version of a model file package (`.xcdatamodeld`).
  static let momd = "momd"
  /// Extension for a compiled version of a *versioned* model file (`.xcdatamodel`).
  static let mom = "mom"
  /// Extension for an optimized version for the '.mom' file.
  static let omo = "omo"
  /// Extension for a compiled version of a mapping model file (`.xcmappingmodel`).
  static let cdm = "cdm"
}

/// Types adopting the `ModelVersion` protocol can be used to describe a Core Data Model and its versioning.
public protocol ModelVersion: Equatable, RawRepresentable, CustomDebugStringConvertible {
  /// Protocol `ModelVersion`.
  ///
  /// List with all versions until now.
  static var allVersions: [Self] { get }

  /// Protocol `ModelVersion`.
  ///
  /// Current model version.
  static var currentVersion: Self { get }

  /// Protocol `ModelVersion`.
  ///
  /// Version name.
  var versionName: String { get }

  /// Protocol `ModelVersion`.
  ///
  /// The next `ModelVersion` in the progressive migration.
  var next: Self? { get }

  /// Protocol `ModelVersion`.
  ///
  /// `NSBundle` object containing the model file.
  var modelBundle: Bundle { get }

  /// Protocol `ModelVersion`.
  ///
  /// Model name.
  var modelName: String { get }

  /// Protocol `ModelVersion`.
  ///
  /// Return the NSManagedObjectModel for this `ModelVersion`.
  func managedObjectModel() -> NSManagedObjectModel
}

extension ModelVersion {
  /// Protocol `ModelVersion`.
  ///
  /// Model file name.
  var momd: String { "\(modelName).\(ModelVersionFileExtension.momd)" }
}

extension ModelVersion {
  public var debugDescription: String {
    "\(modelName)‣\(versionName)"
  }
}

extension ModelVersion {
  /// Searches for the first ModelVersion whose model is compatible with the persistent store metedata
  public static subscript(_ metadata: [String: Any]) -> Self? {
    let version = Self.allVersions.first {
      $0.managedObjectModel().isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
    }
    return version
  }

  /// Initializes a `ModelVersion` from a `NSPersistentStore` URL; returns nil if a `ModelVersion` hasn't been correctly defined.
  /// - Throws: It throws an error if no store is found at `persistentStoreURL` or if there is a problem accessing its contents.
  public init?(persistentStoreURL: URL) throws {
    let metadata: [String: Any]
    metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
      type: .sqlite,
      at: persistentStoreURL,
      options: nil)
    let version = Self[metadata]

    guard let modelVersion = version else {
      return nil
    }

    self = modelVersion
  }

  /// Protocol `ModelVersion`.
  ///
  /// Returns the NSManagedObjectModel for this `ModelVersion`.
  public func managedObjectModel() -> NSManagedObjectModel {
    _managedObjectModel()
  }

  // swiftlint:disable:next identifier_name
  internal func _managedObjectModel() -> NSManagedObjectModel {
    let momURL = modelBundle.url(
      forResource: versionName,
      withExtension: "\(ModelVersionFileExtension.mom)",
      subdirectory: momd)

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

  /// `AnyIterator` to iterate all the nexts steps after `self`.
  func makeIterator() -> AnyIterator<Self> {
    var version: Self = self
    return AnyIterator {
      guard let next = version.next else { return nil }

      version = next
      return version
    }
  }
}

extension ModelVersion {
  /// Returns`true` if a lightweight migration to the next model version is possible
  ///
  /// - Note:
  /// Lightweight migrations are possible only if all changes are simple enough to be automaticaly inferred such as:
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
  public func isLightWeightMigrationPossibleToNextModelVersion() -> Bool {
    guard let nextVersion = next else {
      return false
    }

    let mappingModel = try? NSMappingModel.inferredMappingModel(
      forSourceModel: managedObjectModel(),
      destinationModel: nextVersion.managedObjectModel())

    return mappingModel != nil
  }
}

// MARK: - Migration

/// Returns `true` if a migration to a given `ModelVersion` is necessary for the persistent store at a given `URL`.
///
/// - Parameters:
///   - storeURL: the current store URL.
///   - version: the ModelVersion to which the store is compared.
/// - Throws: It throws an error in cases of failure.
public func isMigrationNecessary<Version: ModelVersion>(for storeURL: URL, to version: Version) throws -> Bool {
  // Before you initiate a migration process, you should first determine whether it is necessary.
  // If the target model configuration is compatible with the persistent store metadata, there is no need to migrate
  // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmCustomizing.html#//apple_ref/doc/uid/TP40004399-CH8-SW2
  let metadata: [String: Any] = try NSPersistentStoreCoordinator.metadataForPersistentStore(
    type: .sqlite,
    at: storeURL,
    options: nil)

  let targetModel = version.managedObjectModel()
  // https://vimeo.com/164904652
  // - configurations define named subsets of a model that contain some but not all entities.
  // - configuration set to nil uses the Default configuration (all entities in the model)
  // - multiple stores with different configurations (loaded with a NSPersistentContainer or added with a
  // NSPersistentStoreCoordinator), have internally the full schema with all the entities;
  // their configuration may define a subset of the entities but the underlying .sqlite file will have all the entities.
  // - if multiple configurations contain the same entities, objects are saved in the first-added store
  // (whose configuration includes that entity) or they can be assigned to another store with the NSManagedObjectContext method assign(object:to:) (before saving).
  // - trying to assign an object to a store whose configuration doesn't include that particular entity will cause an error:
  // 'Can't assign an object to a store that does not contain the object's entity.'
  // - if an entity gets changed, then all the stores need to be migrated one by one
  // (probably because all the underlying .sqlite files have to be properly migrated even if the entities are not used); for that reason,
  // passing a configuration name or nil to isConfiguration(withName:compatibleWithStoreMetadata:) will always result in a false value (migration needed).
  let isCompatible = targetModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)

  if isCompatible {
    return false  // current and target versions are the same
  } else if let currentVersion = Version[metadata] {
    let iterator = currentVersion.makeIterator()
    while let nextVersion = iterator.next() {
      if nextVersion == version { return true }
    }
    // can't migrate to a version not defined as a next step
    // (target version is probably a prior version of the current one)
    return false
  } else {
    // fallback
    return false
  }
}
