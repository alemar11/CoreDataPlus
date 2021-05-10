// CoreDataPlus

import CoreData

extension NSPersistentStoreCoordinator {
  enum Notification {
    struct StoresWillChange {
      // NSPersistentStoreCoordinatorStoresWillChange
    }
    
    struct StoresDidChange {
      // user info dictionary contains information about the stores that were added or removed
      // NSPersistentStoreCoordinatorStoresDidChange
      
      // User info keys for NSPersistentStoreCoordinatorStoresDidChangeNotification:
      
      // The object values for NSAddedPersistentStoresKey and NSRemovedPersistentStoresKey will be arrays containing added/removed stores
      
      // The object value for NSUUIDChangedPersistentStoresKey will be an array where the object at index 0 will be the old store instance, and the object at index 1 the new
    }
    
    struct WillRemoveStore {
      // sent during the invocation of NSPersistentStore's willRemoveFromPersistentStoreCoordinator during store deallocation or removal
      // NSPersistentStoreCoordinatorWillRemoveStore
    }
  }
}

//extension NSNotification.Name {
//
//    
//    @available(macOS 10.9, *)
//    public static let NSPersistentStoreCoordinatorStoresWillChange: NSNotification.Name
//
//    
//    // user info dictionary contains information about the stores that were added or removed
//    @available(macOS 10.4, *)
//    public static let NSPersistentStoreCoordinatorStoresDidChange: NSNotification.Name
//
//    
//    // sent during the invocation of NSPersistentStore's willRemoveFromPersistentStoreCoordinator during store deallocation or removal
//    @available(macOS 10.5, *)
//    public static let NSPersistentStoreCoordinatorWillRemoveStore: NSNotification.Name
//
//    
//    // User info keys for NSPersistentStoreCoordinatorStoresDidChangeNotification:
//    
//    // The object values for NSAddedPersistentStoresKey and NSRemovedPersistentStoresKey will be arrays containing added/removed stores
//    
//    // The object value for NSUUIDChangedPersistentStoresKey will be an array where the object at index 0 will be the old store instance, and the object at index 1 the new
//    
//    // Persistent store option keys:
//    
//    // flag indicating whether a store is treated as read-only or not - default is NO
//    
//    // flag indicating whether an XML file should be validated with the DTD while opening - default is NO
//    
//    // Migration keys:
//    
//    /* Options key specifying the connection timeout for Core Data stores.  This value (an NSNumber) represents the duration, in seconds, Core Data will wait while attempting to create a connection to a persistent store.  If a connection is unable to be made within that timeframe, the operation is aborted and an error is returned.
//    */
//    
//    /* Options key for a dictionary of sqlite pragma settings with pragma values indexed by pragma names as keys.  All pragma values must be specified as strings.  The fullfsync and synchronous pragmas control the tradeoff between write performance (write to disk speed & cache utilization) and durability (data loss/corruption sensitivity to power interruption).  For more information on pragma settings visit <http://sqlite.org/pragma.html>
//    */
//    
//    /* Option key to run an analysis of the store data to optimize indices based on statistical information when the store is added to the coordinator.  This invokes SQLite's ANALYZE command.  Ignored by other stores.
//    */
//    
//    /* Option key to rebuild the store file, forcing a database wide defragmentation when the store is added to the coordinator.  This invokes SQLite's VACUUM command.  Ignored by other stores.
//     */
//    
//    /* Options key to ignore the built-in versioning provided by Core Data.  If the value for this key (an NSNumber) evaluates to YES (using boolValue), Core Data will not compare the version hashes between the managed object model in the coordinator and the metadata for the loaded store.  (It will, however, continue to update the version hash information in the metadata.)  This key is specified by default for all applications linked on or before Mac OS X 10.4.
//    */
//    
//    /* Options key to automatically attempt to migrate versioned stores.  If the value for this key (an NSNumber) evaluates to YES (using boolValue) Core Data will, if the version hash information for added store is determined to be incompatible with the model for the coordinator, attempt to locate the source and mapping models in the application bundles, and perform a migration.
//    */
//    
//    /* When combined with NSMigratePersistentStoresAutomaticallyOption, coordinator will attempt to infer a mapping model if none can be found */
//    
//    /* Key to represent the version hash information (dictionary) for the model used to create a persistent store.  This key is used in the metadata for a persistent store.
//    */
//    
//    /* Key to represent the version identifier for the model used to create the store. This key is used in the metadata for a persistent store.
//    */
//    
//    /* Key to represent the earliest version of MacOS X the persistent store should support.  Backward compatibility may preclude some features.  The numeric values are defined in AvailabilityMacros.h
//    */
//    
//    /* User info key specifying the maximum connection pool size that should be used on a store that supports concurrent request handling, the value should be an NSNumber. The connection pool size determines the number of requests a store can handle concurrently, and should be a function of how many contexts are attempting to access store data at any time. Generally, application developers should not set this, and should use the default value. The default connection pool size is implementation dependent and may vary by store type and/or platform.
//     */
//    
//    /* Spotlight indexing and external record support keys */
//    
//    /* Values to be passed with NSExternalRecordsFileFormatOption indicating the format used when writing external records.
//       The files are serialized dictionaries.
//    */
//    
//    /* option indicating the file format used when writing external records.The default is NSXMLExternalRecordType if this options isn't specified. */
//    
//    /* option indicating the directory URL where external records are stored. External records are files that can be used by
//       Spotlight to index the contents of the store. They can also contain a serialized dictionary representation of the instances.
//       The location specified with this option must be somewhere under the path ~/Library/Caches/Metadata/CoreData or ~/Library/CoreData
//       This option must be set together with NSExternalRecordExtensionOption
//    */
//    
//    /* option indicating the extension used in the external record files. This option must be set together with NSExternalRecordsDirectoryOption */
//    
//    /* Dictionary key for the entity name extracted from an external record file URL */
//    
//    /* Dictionary key for the store UUID extracted from an external record file URL */
//    
//    /* Dictionary key for the store URL extracted from an external record file URL */
//    
//    /* Dictionary key for the managed object model URL extracted from an external record file URL */
//    
//    /* Dictionary key for the object URI extracted from an external record file URL */
//    
//    /* store option for the destroy... and replace... to indicate that the store file should be destroyed even if the operation might be unsafe (overriding locks
//     */
//    
//    /* Key to represent the protection class for the persistent store.  Backward compatibility may preclude some features.  The acceptable values are those defined in Foundation for the NSFileProtectionKey.  The default value of NSPersistentStoreFileProtectionKey is NSFileProtectionCompleteUntilFirstUserAuthentication for all applications built on or after iOS5.  The default value for all older applications is NSFileProtectionNone. */
//    
//    /* Dictionary key for enabling persistent history - default is NO */
//    
//    /*
//     Allows developers to provide an additional set of classes (which must implement NSSecureCoding) that should be used while
//     decoding a binary store.
//     Using this option is preferable to using NSBinaryStoreInsecureDecodingCompatibilityOption.
//     */
//    
//    /*
//     Indicate that the binary store should be decoded insecurely. This may be necessary if a store has metadata or transformable
//     properties containing non-standard classes. If possible, developers should use the NSBinaryStoreSecureDecodingClasses option
//     to specify the contained classes, allowing the binary store to to be securely decoded.
//     Applications linked before the availability date will default to using this option.
//     */
//    
//    /* When NSPersistentStoreRemoteChangeNotificationPostOptionKey is set to YES, a NSPersistentStoreRemoteChangeNotification is posted for every
//     write to the store, this includes writes that are done by other processes
//     */
//    
//    /* NSPersistentStoreRemoteChangeNotification is posted for all cross process writes to the store
//     The payload is the store UUID (NSStoreUUIDKey), store URL (NSPersistentStoreURLKey), and NSPersistentHistoryToken for the transaction (if NSPersistentHistoryTrackingKey was also set)
//     */
//    @a//vailable(macOS 10.14, *)
//    //public static let NSPersistentStoreRemoteChange: NSNotification.Name
//
//    
//    /* Keys found in the UserInfo for a NSPersistentStoreRemoteChangeNotification */
//    
//    /* custom name for a coordinator.  Coordinators will set the label on their queue */
//    
//    /* Sets the URL for the specified store in the coordinator.  For atomic stores, this will alter the location to which the next save operation will persist the file;  for non-atomic stores, invoking this method will release the existing connection and create a new one at the specified URL.  (For non-atomic stores, a store must pre-exist at the destination URL; a new store will not be created.)
//     */
//    
//    /* Adds the store at the specified URL (of the specified type) to the coordinator with the model configuration and options.  The configuration can be nil -- then it's the complete model; storeURL is usually the file location of the database
//     */
//    
//    /* Sets the metadata stored in the persistent store during the next save operation executed on it; the store type and UUID (NSStoreTypeKey and NSStoreUUIDKey) are always added automatically (but NSStoreUUIDKey is only added if it is not set manually as part of the dictionary argument)
//     */
//    
//    /* Returns the metadata currently stored or to-be-stored in the persistent store
//     */
//    
//    /* Given a URI representation of an object ID, returns an object ID if a matching store is available or nil if a matching store cannot be found (the URI representation contains a UUID of the store the ID is coming from, and the coordinator can match it against the stores added to it)
//     */
//    
//    /* Sends a request to all of the stores associated with this coordinator.
//     Returns an array if successful,  nil if not.
//     The contents of the array will vary depending on the request type: NSFetchRequest results will be an array of managed objects, managed object IDs, or NSDictionaries;
//     NSSaveChangesRequests will an empty array. User defined requests will return arrays of arrays, where the nested array is the result returned form a single store.
//     */
//    
//    /* Returns a dictionary of the registered store types:  the keys are the store type strings and the values are the NSPersistentStore subclasses wrapped in NSValues.
//    */
//    
//    /* Registers the specified NSPersistentStore subclass for the specified store type string.  This method must be invoked before a custom subclass of NSPersistentStore can be loaded into a persistent store coordinator.  Passing nil for the store class argument will unregister the specified store type.
//    */
//    
//    /* Allows to access the metadata stored in a persistent store without warming up a CoreData stack; the guaranteed keys in this dictionary are NSStoreTypeKey and NSStoreUUIDKey. If storeType is nil, Core Data will guess which store class should be used to get/set the store file's metadata.
//     */
//    
//    /* Takes a URL to an external record file file and returns a dictionary with the derived elements
//      The keys in the dictionary are
//            NSEntityNameInPathKey - the name of the entity for the managed object instance
//            NSStoreUUIDInPathKey - UUID of the store containing the instance
//            NSStorePathKey - path to the store file (this is resolved to the store-file path contained in the support directory)
//            NSModelPathKey - path to the model file (this is resolved to the model.mom path contained in the support directory)
//            NSObjectURIKey - URI of the object instance.
//    */
//    
//    /* Creates and populates a store with the external records found at externalRecordsURL. The store is written to destinationURL using
//        options and with type storeType. If storeIdentifier is nil, the records for a single store at externalRecordsURL at imported.
//        externalRecordsURL must not exist as the store will be created from scratch (no appending to an existing store is allowed).
//    */
//    
//    /* Used for save as - performance may vary depending on the type of old and new store; the old store is usually removed from the coordinator by the migration operation, and therefore is no longer a useful reference after invoking this method
//    */
//    
//    /* delete or truncate the target persistent store in accordance with the store class's requirements.  It is important to pass similar options as addPersistentStoreWithType: ... SQLite stores will honor file locks, journal files, journaling modes, and other intricacies.  It is not possible to unlink a database file safely out from underneath another thread or process, so this API performs a truncation.  Other stores will default to using NSFileManager.
//     */
//    
//    /* copy or overwrite the target persistent store in accordance with the store class's requirements.  It is important to pass similar options as addPersistentStoreWithType: ... SQLite stores will honor file locks, journal files, journaling modes, and other intricacies.  Other stores will default to using NSFileManager.
//     */
//    
//    /* asynchronously performs the block on the coordinator's queue.  Encapsulates an autorelease pool. */
//    
//    /* synchronously performs the block on the coordinator's queue.  May safely be called reentrantly. Encapsulates an autorelease pool. */
//    
//    /* Constructs a combined NSPersistentHistoryToken given an array of persistent stores. If stores is nil or an empty array, the NSPersistentHistoryToken will be constructed with all of the persistent stores in the coordinator. */
//    
//
//
//}
