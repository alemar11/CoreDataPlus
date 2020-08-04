// CoreDataPlus

// Consider includesPendingChanges in 3.0.0

import CoreData

extension NSFetchRequestResult where Self: NSManagedObject {
  /// **CoreDataPlus**
  ///
  /// The entity name.
  public static var entityName: String {
    if let name = entity().name {
      return name
    }
    // Attention: sometimes entity() returns nil due to a CoreData bug occurring in the Unit Test targets or when Generics are used.
    // https://forums.developer.apple.com/message/203409#203409
    // https://stackoverflow.com/questions/37909392/exc-bad-access-when-calling-new-entity-method-in-ios-10-macos-sierra-core-da
    // https://stackoverflow.com/questions/43231873/nspersistentcontainer-unittests-with-ios10/43286175
    // https://www.jessesquires.com/blog/swift-coredata-and-testing/
    // https://github.com/jessesquires/rdar-19368054
    return String(describing: Self.self)
  }

  // MARK: - Fetch

  /// **CoreDataPlus**
  ///
  /// Creates a `new` NSFetchRequest for `self`.
  /// - Note: Use this method instead of fetchRequest() to avoid a bug in CoreData occurring in the Unit Test targets or when Generics are used.
  public static func newFetchRequest() -> NSFetchRequest<Self> {
    let fetchRequest = NSFetchRequest<Self>(entityName: entityName)
    return fetchRequest
  }

  /// **CoreDataPlus**
  ///
  /// Performs a configurable fetch request in a context.
  /// - Note: it always accesses the underlying persistent stores to retrieve the latest results.
  ///
  /// - Parameters:
  ///   - context: Searched context.
  ///   - configuration: Configuration closure applied **only** before fetching.
  /// - Throws: It throws an error in cases of failure.
  /// - Returns: An array of objects that meet the criteria specified by request fetched from *the receiver* and from *the persistent stores* associated with the receiver’s persistent store coordinator.
  public static func fetch(in context: NSManagedObjectContext, with configuration: (NSFetchRequest<Self>) -> Void = { _ in }) throws -> [Self] {
    // check the Discussion paragraph for the fetch(_:) documentation:
    // https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext/1506672-fetch
    let request = NSFetchRequest<Self>(entityName: entityName)
    configuration(request)

    do {
      return try context.fetch(request)
    } catch {
      throw NSError.fetchFailed(underlyingError: error)
    }
  }

  /// **CoreDataPlus**
  ///
  /// Fetches all the `NSManagedObjectID` for a given predicate.
  /// - Note: it always accesses the underlying persistent stores to retrieve the latest results.
  ///
  /// - Parameters:
  ///   - context: Searched context.
  ///   - includingSubentities: A Boolean value that indicates whether the fetch request includes subentities in the results.
  ///   - predicate: Matching predicate.
  /// - Returns: A list of `NSManagedObjectID`.
  /// - Throws: It throws an error in cases of failure.
  public static func fetchObjectIDs(in context: NSManagedObjectContext, includingSubentities: Bool = true, where predicate: NSPredicate) throws -> [NSManagedObjectID] {
    let request = NSFetchRequest<NSManagedObjectID>(entityName: entityName)
    request.includesPropertyValues = false
    request.returnsObjectsAsFaults = true
    request.resultType = .managedObjectIDResultType
    request.includesSubentities = includingSubentities
    request.predicate = predicate

    do {
      return try context.fetch(request)
    } catch {
      throw NSError.fetchFailed(underlyingError: error)
    }
  }

  // MARK: - First

  /// **CoreDataPlus**
  ///
  /// Attempts to find an object matching a predicate or creates a new one and configures it (if multiple objects are found, configures the **first** one).
  /// - Note: It searches for a matching object in the given context before accessing the underlying persistent stores.
  ///
  /// - Parameters:
  ///   - context: Searched context.
  ///   - predicate: Matching predicate.
  ///   - configuration: Configuration closure called **only** when creating a new object.
  /// - Returns: A matching object or a configured new one.
  /// - Throws: It throws an error in cases of failure.
  public static func findOneOrCreate(in context: NSManagedObjectContext, where predicate: NSPredicate, with configuration: (Self) -> Void) throws -> Self {
    guard let object = try findOneOrFetch(in: context, where: predicate) else {
      let newObject = Self(context: context)
      configuration(newObject)
      return newObject
    }

    return object
  }

  /// **CoreDataPlus**
  ///
  /// Tries to find the first existing object in the context (memory) matching a predicate.
  /// If it doesn’t find the object in the context, tries to load it using a fetch request (if multiple objects are found, returns the **first** one).
  ///
  /// - Parameters:
  ///   - context: Searched context.
  ///   - predicate: Matching predicate.
  /// - Returns: The first matching object (if any).
  /// - Throws: It throws an error in cases of failure.
  public static func findOneOrFetch(in context: NSManagedObjectContext, where predicate: NSPredicate) throws -> Self? { // TODO: change func name
    // first we should fetch an existing object in the context as a performance optimization
    guard let object = findOne(in: context, where: predicate) else {
      // if it's not in memory, we should execute a fetch to see if it exists
      // NSFetchRequest always accesses the underlying persistent stores to retrieve the latest results.
      do {
        return try fetch(in: context) { request in
          request.predicate = predicate
          request.returnsObjectsAsFaults = false
          request.fetchLimit = 1
        }.first
      } catch {
        throw NSError.fetchFailed(underlyingError: error)
      }
    }

    return object
  }

  // MARK: - Unique

  /// **CoreDataPlus**
  ///
  /// Attempts to find an unique object matching a predicate or creates a new one and configures it.
  /// - Note: it always accesses the underlying persistent stores to retrieve the latest results.
  ///
  /// - Parameters:
  ///   - context: Searched context.
  ///   - predicate: Matching predicate.
  ///   - configuration: Configuration closure called **only** when creating a new object.
  /// - Returns: A matching object or a configured new one.
  /// - Throws: It throws an error in cases of failure or if multiple objects are found.
  public static func findUniqueOrCreate(in context: NSManagedObjectContext, where predicate: NSPredicate, with configuration: (Self) -> Void) throws -> Self {
    let uniqueObject = try fetchUnique(in: context) { $0.predicate = predicate }
    guard let object = uniqueObject else {
      let newObject = Self(context: context)
      configuration(newObject)
      return newObject
    }

    return object
  }

  /// **CoreDataPlus**
  ///
  /// Executes a fetch request where **only** a single unique object is expected as result, otherwhise a an error is thrown.
  /// - Note: it always accesses the underlying persistent stores to retrieve the latest results.
  ///
  /// - Parameters:
  ///   - context: Searched context
  ///   - configuration: Configuration closure applied before fetching.
  /// - Throws: It throws an error if multiple objects are fetched.
  /// - Returns: Unique object (if any).
  public static func fetchUnique(in context: NSManagedObjectContext, with configuration: @escaping (NSFetchRequest<Self>) -> Void) throws -> Self? {
    let result = try fetch(in: context) { request in
      configuration(request)
      request.fetchLimit = 2
    }

    switch result.count {
    case 0:
      return nil
    case 1:
      return result[0]
    default:
      throw NSError.fetchExpectingOnlyOneObjectFailed()
    }
  }

  // MARK: - Delete

  /// **CoreDataPlus**
  ///
  /// Specifies the objects (matching a given predicate) that should be removed from its persistent store when changes are committed.
  /// If objects have not yet been saved to a persistent store, they are simply removed from the context.
  /// If `includingSubentities` is set to `false`, sub-entities will be ignored.
  /// - Note: `NSBatchDeleteRequest` would be more efficient but requires a context with an `NSPersistentStoreCoordinator` directly connected (no child context).
  /// - Throws: It throws an error in cases of failure.
  public static func delete(in context: NSManagedObjectContext, includingSubentities: Bool = true, where predicate: NSPredicate = NSPredicate(value: true)) throws {
    do {
      try autoreleasepool {
        try fetch(in: context) { request in
          request.includesPropertyValues = false
          request.includesSubentities = includingSubentities
          request.predicate = predicate
        }.lazy.forEach(context.delete(_:))
      }
    } catch {
      throw NSError.fetchFailed(underlyingError: error)
    }
  }

  /// **CoreDataPlus**
  ///
  /// Removes all entities from within the specified `NSManagedObjectContext` excluding a given list of entities.
  ///
  /// - Parameters:
  ///   - context: The `NSManagedObjectContext` to remove the Entities from.
  ///   - objects: An Array of `NSManagedObjects` belonging to the `NSManagedObjectContext` to exclude from deletion.
  /// - Throws: It throws an error in cases of failure.
  /// - Note: `NSBatchDeleteRequest` would be more efficient but requires a context with an `NSPersistentStoreCoordinator` directly connected (no child context).
  public static func delete(in context: NSManagedObjectContext, except objects: [Self]) throws {
    let predicate = NSPredicate(format: "NOT (self IN %@)", objects)
    try delete(in: context, includingSubentities: true, where: predicate )
  }

  // MARK: - Count

  /// **CoreDataPlus**
  ///
  /// Counts the results of a configurable fetch request in a context.
  /// - Throws: It throws an error in cases of failure.
  public static func count(in context: NSManagedObjectContext, for configuration: (NSFetchRequest<Self>) -> Void = { _ in }) throws -> Int {
    let request = newFetchRequest()
    configuration(request)

    let result = try context.count(for: request)
    guard result != NSNotFound else { throw NSError.fetchCountFailed() }

    return result
  }

  // MARK: - Materialized Object

  /// **CoreDataPlus**
  ///
  /// Iterates over the context’s registeredObjects set (which contains all managed objects the context currently knows about) until it finds one that is not a fault matching for a given predicate.
  /// Faulted objects are not considered to prevent Core Data to make a round trip to the persistent store.
  public static func findOne(in context: NSManagedObjectContext, where predicate: NSPredicate) -> Self? {
    for object in context.registeredObjects where !object.isFault {
      guard let result = object as? Self, predicate.evaluate(with: result) else { continue }

      return result
    }

    return nil
  }

  /// **CoreDataPlus**
  ///
  /// Iterates over the context’s registeredObjects set (which contains all managed objects the context currently knows about) until it finds
  /// all the objects that aren't a fault matching for a given predicate.
  /// Faulted objects are not considered to prevent Core Data to make a round trip to the persistent store.
  public static func find(in context: NSManagedObjectContext, where predicate: NSPredicate) -> [Self] {
    let results = context.registeredObjects.filter { !$0.isFault && $0 is Self }.filter { predicate.evaluate(with: $0) }.compactMap { $0 as? Self }

    return results
  }
}

// MARK: - Batch Operations

extension NSFetchRequestResult where Self: NSManagedObject {
  /// **CoreDataPlus**
  ///
  /// Executes a batch update on the context's persistent store coordinator.
  /// - Parameters:
  ///   - context: The context whose the persistent store coordinator will be used to execute the batch update.
  ///   - configuration: An handler to configure the NSBatchUpdateRequest.
  /// - Returns: a NSBatchUpdateRequest result.
  /// - Throws: It throws an error in cases of failure.
  /// - Note: A batch delete can **only** be done on a SQLite store.
  public static func batchUpdateObjects(using context: NSManagedObjectContext,
                                        resultType: NSBatchUpdateRequestResultType = .statusOnlyResultType,
                                        propertiesToUpdate: [AnyHashable: Any],
                                        includesSubentities: Bool = true,
                                        predicate: NSPredicate? = nil) throws -> NSBatchUpdateResult {
    guard context.persistentStoreCoordinator != nil else { throw NSError.persistentStoreCoordinatorNotFound(context: context) }

    let batchRequest = NSBatchUpdateRequest(entityName: entityName)
    batchRequest.resultType = resultType
    batchRequest.propertiesToUpdate = propertiesToUpdate
    batchRequest.includesSubentities = includesSubentities
    batchRequest.predicate = predicate

    do {
      // swiftlint:disable:next force_cast
      return try context.execute(batchRequest) as! NSBatchUpdateResult
    } catch {
      throw NSError.batchUpdateFailed(underlyingError: error)
    }
  }

  /// **CoreDataPlus**
  ///
  /// Executes a batch delete on the context's persistent store coordinator.
  /// - Parameters:
  ///   - context: The context whose the persistent store coordinator will be used to execute the batch delete.
  ///   - resultType: The type of the batch delete result (default: `NSBatchDeleteRequestResultType.resultTypeStatusOnly`).
  ///   - configuration: An handler to configure the NSFetchRequest.
  /// - Returns: a NSBatchDeleteResult result.
  /// - Throws: It throws an error in cases of failure.
  /// - Note: A batch delete can **only** be done on a SQLite store.
  @discardableResult
  public static func batchDeleteObjects(using context: NSManagedObjectContext,
                                        resultType: NSBatchDeleteRequestResultType = .resultTypeStatusOnly,
                                        configuration: ((NSFetchRequest<Self>) -> Void)? = nil) throws -> NSBatchDeleteResult {
    guard context.persistentStoreCoordinator != nil else { throw NSError.persistentStoreCoordinatorNotFound(context: context) }

    let request = NSFetchRequest<Self>(entityName: entityName)
    configuration?(request)

    // swiftlint:disable:next force_cast
    let batchRequest = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>)
    batchRequest.resultType = resultType

    do {
      // swiftlint:disable:next force_cast
      return try context.execute(batchRequest) as! NSBatchDeleteResult
    } catch {
      throw NSError.batchDeleteFailed(underlyingError: error)
    }
  }

  /// **CoreDataPlus**
  ///
  /// Executes a batch insert on the context's persistent store coordinator.
  /// - Parameters:
  ///   - context: The context whose the persistent store coordinator will be used to execute the batch insert.
  ///   - resultType: The type of the batch insert result (default: `NSBatchInsertRequestResultType.statusOnly`).
  ///   - objects: A dictionary of objects to insert.
  /// - Returns: a NSBatchInsertResult result.
  /// - Throws: It throws an error in cases of failure.
  /// - Note: A batch insert can **only** be done on a SQLite store.
  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public static func batchInsertObjects(using context: NSManagedObjectContext,
                                        resultType: NSBatchInsertRequestResultType = .statusOnly,
                                        objects: [[String: Any]]) throws -> NSBatchInsertResult {
    guard context.persistentStoreCoordinator != nil else { throw NSError.persistentStoreCoordinatorNotFound(context: context) }

    let batchRequest = NSBatchInsertRequest(entityName: entityName, objects: objects)
    batchRequest.resultType = resultType

    do {
      // swiftlint:disable:next force_cast
      return try context.execute(batchRequest) as! NSBatchInsertResult
    } catch {
      throw NSError.batchInsertFailed(underlyingError: error)
    }
  }
}

// MARK: - Async Fetch

extension NSFetchRequestResult where Self: NSManagedObject {
  /// **CoreDataPlus**
  ///
  /// Performs a configurable asynchronous fetch request in a context.
  ///
  /// - Parameter context: Searched context.
  /// - Parameter configuration: Configuration closure called when preparing the `NSFetchRequest`.
  /// - Parameter completion: A completion block with a `Result` element with either the fetched objects or an error.
  /// - Returns: A `NSAsynchronousFetchResult` *future* instance that can be used to report the fetch progress.
  /// - Throws: It throws an error in cases of failure.
  ///
  /// - Note: This kind of fetch operation supports progress reporting:
  ///   ```
  ///   let progress = Progress(totalUnitCount: 1)
  ///   progress.becomeCurrent(withPendingUnitCount: 1)
  ///   let fetchResultToken = try ENTITY.fetchAsync(in:with:completion:)
  ///   let token = fetchResultToken.progress?.observe(\.completedUnitCount, options: [.old, .new]) { (progress, change) }
  ///   progress.resignCurrent()
  ///
  ///   ```
  /// - Warning: If the ConcurrencyDebug is enabled, the fetch request will cause a thread violation error.
  /// ([more details here](https://stackoverflow.com/questions/31728425/coredata-asynchronous-fetch-causes-concurrency-debugger-error)).
  @discardableResult
  public static func fetchAsync(in context: NSManagedObjectContext,
                                with configuration: (NSFetchRequest<Self>) -> Void = { _ in },
                                completion: @escaping (Result<[Self], NSError>) -> Void) throws -> NSAsynchronousFetchResult<Self> {
    let request = Self.newFetchRequest()
    configuration(request)

    let asynchronousRequest = NSAsynchronousFetchRequest(fetchRequest: request) { result in
      if let error = result.operationError {
        completion(.failure(NSError.fetchFailed(underlyingError: error)))
      } else if let fetchedObjects = result.finalResult {
        completion(.success(fetchedObjects))
      } else {
        completion(.failure(NSError.asyncFetchFailed()))
      }
    }

    // swiftlint:disable:next force_cast
    return try context.execute(asynchronousRequest) as! NSAsynchronousFetchResult<Self>
  }
}
