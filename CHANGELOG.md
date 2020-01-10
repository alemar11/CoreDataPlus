# Changelog

### 2.3.0

- Added utils for `NSSet`.

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
