// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

class CoreDataPlusOnDiskWithProgrammaticallyModelTestCase: XCTestCase {
  var container: NSPersistentContainer!
  
  override func setUp() {
    super.setUp()
    container = OnDiskWithProgrammaticallyModelPersistentContainer.makeNew()
  }
  
  override func tearDown() {
    do {
      if let onDiskContainer = container as? OnDiskWithProgrammaticallyModelPersistentContainer {
        try onDiskContainer.destroy()
      }
    } catch {
      XCTFail("The persistent container couldn't be destroyed.")
    }
    container = nil
    super.tearDown()
  }
}

// MARK: - On Disk NSPersistentContainer with Programmatically Model

final class OnDiskWithProgrammaticallyModelPersistentContainer: NSPersistentContainer {
  static func makeNew() -> OnDiskWithProgrammaticallyModelPersistentContainer {
    Self.makeNew(id: UUID())
  }
  
  static func makeNew(id: UUID) -> OnDiskWithProgrammaticallyModelPersistentContainer {
    let url = URL.newDatabaseURL(withID: id)
    print(url)
    let container = OnDiskWithProgrammaticallyModelPersistentContainer(name: "SampleModel2",
                                                                       managedObjectModel: SampleModel2.makeManagedObjectModel())
    let description = NSPersistentStoreDescription()
    description.url = url
    description.shouldMigrateStoreAutomatically = false
    description.shouldInferMappingModelAutomatically = false
    
    // Enable history tracking and remote notifications
    description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    if #available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
      description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    }
    container.persistentStoreDescriptions = [description]
    
    container.loadPersistentStores { (description, error) in
      XCTAssertNil(error)
    }
    return container
  }
  
  /// Destroys the database and reset all the registered contexts.
  func destroy() throws {
    guard let url = persistentStoreDescriptions[0].url else { return }
    guard !url.absoluteString.starts(with: "/dev/null") else { return }
    
    // unload each store from the used context to avoid the sqlite3 bug warning.
    do {
      if let store = persistentStoreCoordinator.persistentStores.first {
        try persistentStoreCoordinator.remove(store)
      }
      try NSPersistentStoreCoordinator.destroyStore(at: url)
    } catch {
      fatalError("\(error) while destroying the store.")
    }
  }
}

final class ModelBuilderTests: CoreDataPlusOnDiskWithProgrammaticallyModelTestCase {
  func test_1() throws {
    let context = container.viewContext
    //SampleModel2.fillWithSampleData(context: context)
    context.fillWithSampleData2()
    do {
      try context.save()
      context.reset()
      let pages = try Page.fetch(in: context)
      pages.forEach { (p) in
        print(p.content)
      }
    } catch {
      print(error)
      //      let e = error as NSError
      //      //print(e.userInfo)
      //      //print(e.debugDescription)
      //      print(e.localizedDescription)
      //      //XCTFail("yo")
    }
  }
}

import CoreData.CoreDataDefines

let errorKeys = [
  NSDetailedErrorsKey,
  NSValidationObjectErrorKey,
  NSValidationKeyErrorKey,
  NSValidationPredicateErrorKey,
  NSValidationValueErrorKey,
  NSAffectedStoresErrorKey,
  NSAffectedObjectsErrorKey,
  NSPersistentStoreSaveConflictsErrorKey,
  NSSQLiteErrorDomain
]

let errors = [
  NSManagedObjectValidationError,
  NSManagedObjectConstraintValidationError,
  NSValidationMultipleErrorsError,
  NSValidationMissingMandatoryPropertyError,
  NSValidationRelationshipLacksMinimumCountError,
  NSValidationRelationshipExceedsMaximumCountError,
  NSValidationRelationshipDeniedDeleteError,
  NSValidationNumberTooLargeError,
  NSValidationNumberTooSmallError,
  NSValidationDateTooLateError,
  NSValidationDateTooSoonError,
  NSValidationInvalidDateError,
  NSValidationStringTooLongError,
  NSValidationStringTooShortError,
  NSValidationStringPatternMatchingError,
  NSValidationInvalidURIError,
  NSManagedObjectContextLockingError,
  NSPersistentStoreCoordinatorLockingError,
  NSManagedObjectReferentialIntegrityError,
  NSManagedObjectExternalRelationshipError,
  NSManagedObjectMergeError,
  NSManagedObjectConstraintMergeError,
  NSPersistentStoreInvalidTypeError,
  NSPersistentStoreTypeMismatchError,
  NSPersistentStoreIncompatibleSchemaError,
  NSPersistentStoreSaveError,
  NSPersistentStoreIncompleteSaveError,
  NSPersistentStoreSaveConflictsError,
  NSCoreDataError,
  NSPersistentStoreOperationError,
  NSPersistentStoreOpenError,
  NSPersistentStoreTimeoutError,
  NSPersistentStoreUnsupportedRequestTypeError,
  NSPersistentStoreIncompatibleVersionHashError,
  NSMigrationError,
  NSMigrationConstraintViolationError,
  NSMigrationCancelledError,
  NSMigrationMissingSourceModelError,
  NSMigrationMissingMappingModelError,
  NSMigrationManagerSourceStoreError,
  NSMigrationManagerDestinationStoreError,
  NSEntityMigrationPolicyError,
  NSSQLiteError,
  NSInferredMappingModelError,
  NSExternalRecordImportError,
  NSPersistentHistoryTokenExpiredError,
]
