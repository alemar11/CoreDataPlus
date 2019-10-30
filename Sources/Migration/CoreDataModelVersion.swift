//
// CoreDataPlus
//
// Copyright © 2016-2019 Tinrobots.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
  /// Initializes a `CoreDataModelVersion` from a `NSPersistentStore` URL.
  public init?(persistentStoreURL: URL) {
    guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: persistentStoreURL, options: nil) else {
      return nil
    }

    let version = Self.allVersions.first {
      $0.managedObjectModel().isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
    }

    guard let modelVersion = version else {
      return nil
    }

    self = modelVersion
  }

  /// **CoreDataPlus**
  ///
  /// Protocol `CoreDataModelVersion`.
  ///
  /// Return the NSManagedObjectModel for this `CoreDataModelVersion`.
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

extension CoreDataModelVersion {
  /// **CoreDataPlus**
  ///
  /// Returns `true` if a migration is possible for the current store to a given `CoreDataModelVersion`.
  ///
  /// - Parameters:
  ///   - storeURL: the current store URL.
  ///   - version: the ModelVersion to which the store is compared.
  /// - Throws: It throws an error in cases of failure.
  public func isMigrationPossible<Version: CoreDataModelVersion>(for storeURL: URL, to version: Version) throws -> Bool {
    let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil)
    let targetModel = version.managedObjectModel()
    return !targetModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
  }

  /// **CoreDataPlus**
  ///
  /// Returns a list of `MigrationStep` needed to mirate to the next `version` of the store.
  public func migrationSteps(to version: Self) -> [CoreDataMigrationStep] {
    guard self != version else {
      return []
    }

    guard let mappings = mappingModelsToNextModelVersion(), let nextVersion = successor else {
      fatalError("Couldn't find any mapping models.")
    }

    let step = CoreDataMigrationStep(source: managedObjectModel(), destination: nextVersion.managedObjectModel(), mappings: mappings)

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
