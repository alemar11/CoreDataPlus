# Changelog

### 5.0.0 ⭐

- Xcode 13.
- Improved methods to fetch persistent history transactions.
- Added CoreDataPlus multi-platform framework.
- Added support for `NSAttributeDescription.AttributeType`.
- Added support for `NSPersistentStore.StoreType`.
- Added `NSPredicate` utility methods.
- Added additional `NSManagedObject` utility methods.
- Some `NSEntityDescription` utility methods are now `public`.
- More tests.

### 4.0.0 ⭐

- Added a new `Migrator` class to handle migrations (lightweight and heavyweight).
- Added `NSDerivedAttributeDescription` utility methods.
- Added `NSAttributeDescription` utility methods.
- Added `NSEntityMapping` utility methods.
- Added `NSAttributeDescription` utility methods.
- Added `LightweightMigrationManger`, a `NSMigrationManager` subclass to do *lightweight* migrations with a fake progress reporting.
- Added `MigrationProgressReporter` to report migration progress via a `Progress` object.
- Added a `NSManagedObjectContext` helper method to create a child context.
- Added support for `NSPersistentStoreCoordinator` notifications payloads.
- Many custom fetch requests now support the *affectedStores* parameter.
- `DataTransformer` renamed as `CustomTransformer`.

### 3.0.0 ⭐

- Added a generic `NSSecureUnarchiveFromDataTransformer` subclass (*Transformer*) to easily implement CoreData *Transformable* attributes.
- Added a generic `ValueTransfomer` closure based subclass (*DataTransformer*) to implement CoreData *Transformable* attributes.
- APIs improvements.
- New CoreData notifications payloads.
- History: added new history transactions and changes fetch requests.
- History: removed unused APIs.
- Added a fetch method that returns *NSArray* to support batched requests.
- New batch inserts methods.
- Removed entity and contexts observers.
- More tests.

### 2.3.0

- Added `NSSet` utils.
- Added `obtainPermanentID()` method on `NSManagedObject`.
- `isMigrationPossible` renamed to `isMigrationNecessary`.
- `performAndWait` overload renamed to `performAndWaitResult`.
- Now a WAL checkpoint can be performed before starting a migration.
- Minor refinements.
- More tests.

### 2.2.0

- Added support for Persistent History Tracking.
- Added support for batch inserts.
- Added support for async fetch requests.
- Added `materialize()` method on `NSManagedObject`.
- `Collection.fetchFaultedObjects()` deprecated, use `Collection.materializeFaultedObjects()` instead.
- Added support for the new Xcode 11 SPM.
- More tests.

### 2.1.1

- Minor refinements.

### 2.1.0

- Added `ManagedObjectContextChangesObserver`.
- Removed `ThredSafeAccessible` protocol.
- Errors are now notified using `NSError`s.
- `Entity Observer` now can listen to changes happening on subentities. 

### 2.0.1

- Minor refinements.

### 2.0.0 ⭐

- CoreData is now completely migrated to **Swift 5**.
- Fixes.

### 1.2.2

- Added `fetchObjectIDs` method.

### 1.2.1

- Fixed access level for some utils.

### 1.2.0

- CoreData is now completely migrated to **Swift 4.2**.
- CoreData migration refinements.

### 1.1.0

- Added migration between model versions.
- Refinements.

### 1.0.0 ⭐

- Refinements.
- Added utils for batch updates and deletes.
- All the tests run with  `-com.apple.CoreData.ConcurrencyDebug 1`

### 0.9.1

- Added more public API.
- More tests.

### 0.9.0

- Added `FetchedResultsObjectChange` and  `FetchedResultsSectionInfo`.
- Fixes.

### 0.8.0

- `performSaveAndWait(after:)` and `performSave(after:)` now accepts throwing closures.
- Added a new `performAndWait(:)` overload.
- New tests.
- Fixes.

### 0.7.0

- Swift 4.1

### 0.6.0

- More NSManagedObject utils.
- SPM tests.

### 0.5.0

- Added `EntyObserver`.
- Added more utils to get info when some changes are taking place in a `NSManagedObjectContext`.

### 0.4.0

- Added a `CoreDataPlusError` type.
- Added `NSBatchDeleteResult` utils.
- Fixes.

### 0.3.0

- Added more utility methods.
- Methods renaming.
- Full support to 32 bit devices.

### 0.2.0

- Refinements.

### 0.1.0

- First release. ⭐
