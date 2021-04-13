// CoreDataPlus

import CoreData.CoreDataDefines

/// All the CoreData error keys and codes.

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

