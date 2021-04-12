// CoreDataPlus

import XCTest
@testable import CoreDataPlus

@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
final class ModelBuilderTests: CoreDataPlusOnDiskWithProgrammaticallyModelTestCase {
  func test_1() throws {
    let context = container.viewContext
    //SampleModel2.fillWithSampleData(context: context)
    context.fillWithSampleData2()
    do {
      try context.save()
      context.reset()
//      let pages = try Page.fetch(in: context)
//      pages.forEach { (p) in
//        print(p.content)
//      }
      let books = try Book.fetch(in: context)
      books.forEach { (b) in
        print(b.pagesCount)
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
