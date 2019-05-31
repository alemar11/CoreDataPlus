# Changelog

### 2.1.0

- Removed `ThredSafeAccessible` protocol.
- A new shiny `CoreDataPlusError`.
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
