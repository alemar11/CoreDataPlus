import CoreData
import XCTest
@testable import CoreDataPlus

private var cache = [String: NSManagedObjectModel]()

public enum SampleModelVersion: String, CaseIterable {
  case version1 = "SampleModel"
  case version2 = "SampleModel2"
  case version3 = "SampleModel3"
}

extension SampleModelVersion: CoreDataModelVersion {
  public static var allVersions: [SampleModelVersion] { return SampleModelVersion.allCases }
  public static var currentVersion: SampleModelVersion { return .version1 }
  public var modelName: String { return "SampleModel" }

  public var successor: SampleModelVersion? {
    switch self {
    case .version1: return .version2
    case .version2: return .version3
    default: return nil
    }
  }

  public var versionName: String { return rawValue }

  public var modelBundle: Bundle {
    class Object {} // used to get the current bundle 🤓
    return Bundle(for: Object.self)
  }

  public func managedObjectModel() -> NSManagedObjectModel {
    if let model = cache[self.versionName], #available(iOS 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, *) {
      return model
    }

    if isRunningSwiftPackageTests() {
      let sampleFolderURL = URL(fileURLWithPath: #file, isDirectory: false).deletingLastPathComponent()
      let momUrl = sampleFolderURL.appendingPathComponent("\(modelName).momd/\(versionName).mom")

      XCTAssertTrue(FileManager.default.fileExists(atPath: momUrl.path))

      guard let model = NSManagedObjectModel(contentsOf: momUrl) else {
        preconditionFailure("Error initializing Managed Object Model: cannot open model at \(momUrl).")
      }

      cache[self.versionName] = model
      return model
    }

    let model = _managedObjectModel()
    cache[self.versionName] = model
    return model
  }
}

extension SampleModelVersion {
  func mappingModel_swift_package_tests() -> [NSMappingModel] {
    switch self {
    case .version2:
      let sampleFolderURL = URL(fileURLWithPath: #file, isDirectory: false).deletingLastPathComponent()
      let cdmUrl = sampleFolderURL.appendingPathComponent("V2toV3.cdm")
      if let mapping = NSMappingModel(contentsOf: cdmUrl) {
        return [mapping]
      }
      return []
    default: return []
    }
  }

  public func mappingModelsToNextModelVersion() -> [NSMappingModel]? {
    switch self {
    case .version1:
      let mapping = SampleModelVersion.version1.inferredMappingModelToNextModelVersion()!
      // Renamed ExpensiveSportCar as LuxuryCar using a "renaming id" on entity ExpensiveSportCar
      // Added the index: byMakerAndNumberPlate on entity Car
      return [mapping]

    case .version2:
      let mappings: NSMappingModel
      if isRunningSwiftPackageTests() {
        mappings = mappingModel_swift_package_tests().first!
      } else {
        mappings = SampleModelVersion.version2.mappingModelToNextModelVersion()!
      }
      for e in mappings.entityMappings {
        if let em = e.entityMigrationPolicyClassName, em.contains("V2to3MakerPolicyPolicy") {
          /// Hack: we need to change the project module depending on the test target
          /// default value: CoreDataPlus_Tests_macOS.V2to3MakerPolicyPolicy
          #if os(iOS)
          e.entityMigrationPolicyClassName = "CoreDataPlus_Tests_iOS.V2to3MakerPolicyPolicy"
          #elseif os(tvOS)
          e.entityMigrationPolicyClassName = "CoreDataPlus_Tests_tvOS.V2to3MakerPolicyPolicy"
          #endif

          if isRunningSwiftPackageTests() {
            XCTFail("NSEntityMigrationPolicy doesn't work on Swift Package testing.")
          }

        }
      }

      return [mappings]
    default:
      return []
    }
  }
}
