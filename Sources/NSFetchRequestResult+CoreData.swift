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

extension NSFetchRequestResult where Self: NSManagedObject {
  /// **CoreDataPlus**
  ///
  /// The entity name.
  @available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)
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
  @available(iOS 10, tvOS 10, watchOS 3, OSX 10.12, *)
  public static func newFetchRequest() -> NSFetchRequest<Self> {
    let fetchRequest = NSFetchRequest<Self>(entityName: entityName)
    return fetchRequest
  }

  /// **CoreDataPlus**
  ///
  /// Performs a configurable fetch request in a context.
  /// - Throws: It throws an error in cases of failure.
  @available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)
  public static func fetch(in context: NSManagedObjectContext, with configuration: (NSFetchRequest<Self>) -> Void = { _ in }) throws -> [Self] {
    let request = NSFetchRequest<Self>(entityName: entityName)
    configuration(request)

    do {
      return try context.fetch(request)
    } catch {
      throw CoreDataPlusError.fetchFailed(underlyingError: error)
    }
  }

  /// **CoreDataPlus**
  ///
  /// Fetches all the `NSManagedObjectID` for a given predicate.
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
      throw CoreDataPlusError.fetchFailed(underlyingError: error)
    }
  }

  // MARK: - First

  /// **CoreDataPlus**
  ///
  /// Attempts to find an object matching a predicate or creates a new one and configures it (if multiple objects are found, configures the **first** one).
  ///
  /// - Parameters:
  ///   - context: Searched context.
  ///   - predicate: Matching predicate.
  ///   - configuration: Configuration closure called only when creating a new object.
  /// - Returns: A matching object or a configured new one.
  /// - Throws: It throws an error in cases of failure.
  @available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)
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
  @available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)
  public static func findOneOrFetch(in context: NSManagedObjectContext, where predicate: NSPredicate) throws -> Self? {
    // first we should fetch an existing object in the context as a performance optimization
    guard let object = findOneMaterializedObject(in: context, where: predicate) else {
      // if it's not in memory, we should execute a fetch to see if it exists
      do {
        return try fetch(in: context) { request in
          request.predicate = predicate
          request.returnsObjectsAsFaults = false
          request.fetchLimit = 1
        }.first
      } catch {
        throw CoreDataPlusError.fetchFailed(underlyingError: error)
      }
    }

    return object
  }

  // MARK: - Unique

  /// **CoreDataPlus**
  ///
  /// Attempts to find an unique object matching a predicate or creates a new one and configures it.
  ///
  /// - Parameters:
  ///   - context: Searched context.
  ///   - predicate: Matching predicate.
  ///   - configuration: Configuration closure called only when creating a new object.
  /// - Returns: A matching object or a configured new one.
  /// - Throws: It throws an error in cases of failure or if multiple objects are found.
  @available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)
  public static func findUniqueOrCreate(in context: NSManagedObjectContext, where predicate: NSPredicate, with configuration: (Self) -> Void) throws -> Self {
    guard let object = try findUniqueOrFetch(in: context, where: predicate) else {
      let newObject = Self(context: context)
      configuration(newObject)

      return newObject
    }

    return object
  }

  /// **CoreDataPlus**
  ///
  /// Tries to find an unique existing object in the context (memory) matching a predicate.
  /// If it doesn’t find the object in the context, tries to load it using a fetch request (if multiple objects are found, returns the **first** one).
  ///
  /// - Parameters:
  ///   - context: Searched context.
  ///   - predicate: Matching predicate.
  /// - Returns: The first matching object (if any).
  /// - Throws: It throws an error in cases of failure or if multiple objects are found.
  @available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)
  public static func findUniqueOrFetch(in context: NSManagedObjectContext, where predicate: NSPredicate) throws -> Self? {
    guard let object = try findUniqueMaterializedObject(in: context, where: predicate) else {
      do {
        return try fetchUniqueObject(in: context) { request in
          request.predicate = predicate
        }
      } catch {
        throw CoreDataPlusError.fetchFailed(underlyingError: error)
      }
    }

    return object
  }

  /// **CoreDataPlus**
  ///
  /// Iterates over the context’s registeredObjects set (which contains all managed objects the context currently knows about) until it finds
  /// an unique object that is not a fault matching for a given predicate.
  /// Faulted objects are not considered to prevent Core Data to make a round trip to the persistent store.
  /// - Throws: It throws an error in cases of multiple results.
  public static func findUniqueMaterializedObject(in context: NSManagedObjectContext, where predicate: NSPredicate) throws -> Self? {
    let results = findMaterializedObjects(in: context, where: predicate)
    guard results.count <= 1 else {
      throw CoreDataPlusError.fetchCountNotFound()
    }
    return results.first
  }

  /// **CoreDataPlus**
  ///
  /// Executes a fetch request where only a single object is expected as result, otherwhise a an error is thrown.
  /// - Throws: It throws an error in cases of failure.
  @available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)
  public static func fetchUniqueObject(in context: NSManagedObjectContext, with configuration: @escaping (NSFetchRequest<Self>) -> Void) throws -> Self? {
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
      throw CoreDataPlusError.fetchExpectingOnlyOneObjectFailed()
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
  @available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)
  public static func deleteAll(in context: NSManagedObjectContext, includingSubentities: Bool = true, where predicate: NSPredicate = NSPredicate(value: true)) throws {
    do {
      try autoreleasepool {
        try fetch(in: context) { request in
          request.includesPropertyValues = false
          request.includesSubentities = includingSubentities
          request.predicate = predicate
        }.lazy.forEach(context.delete(_:))
      }
    } catch {
      throw CoreDataPlusError.fetchFailed(underlyingError: error)
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
  @available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)
  public static func deleteAll(in context: NSManagedObjectContext, except objects: [Self]) throws {
    let predicate = NSPredicate(format: "NOT (self IN %@)", objects)
    try deleteAll(in: context, includingSubentities: true, where: predicate )
  }

  // MARK: - Count

  /// **CoreDataPlus**
  ///
  /// Counts the results of a configurable fetch request in a context.
  /// - Throws: It throws an error in cases of failure.
  @available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)
  public static func count(in context: NSManagedObjectContext, for configuration: (NSFetchRequest<Self>) -> Void = { _ in }) throws -> Int {
    let request = newFetchRequest()
    configuration(request)

    let result = try context.count(for: request)
    guard result != NSNotFound else { throw CoreDataPlusError.fetchCountNotFound() }

    return result
  }

  // MARK: - Materialized Object

  /// **CoreDataPlus**
  ///
  /// Iterates over the context’s registeredObjects set (which contains all managed objects the context currently knows about) until it finds one that is not a fault matching for a given predicate.
  /// Faulted objects are not considered to prevent Core Data to make a round trip to the persistent store.
  public static func findOneMaterializedObject(in context: NSManagedObjectContext, where predicate: NSPredicate) -> Self? {
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
  public static func findMaterializedObjects(in context: NSManagedObjectContext, where predicate: NSPredicate) -> [Self] {
    let results = context.registeredObjects.filter { !$0.isFault && $0 is Self }.filter { predicate.evaluate(with: $0) }.compactMap { $0 as? Self }

    return results
  }
}

// MARK: - Cache

extension NSFetchRequestResult where Self: NSManagedObject {
  /// **CoreDataPlus**
  ///
  /// Tries to retrieve an object from the cache; if there’s nothing in the cache executes the fetch request and caches the result (if a single object is found).
  /// - Parameters:
  ///   - context: Searched context.
  ///   - cacheKey: Cache key.
  ///   - configuration: Configurable fetch request.
  /// - Returns: A cached object (if any).
  /// - Throws: It throws an error in cases of failure.
  @available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)
  public static func fetchCachedObject(in context: NSManagedObjectContext, forKey cacheKey: String, orCacheUsing configuration: @escaping (NSFetchRequest<Self>) -> Void) throws -> Self? {
    guard let cached = context.cachedManagedObject(forKey: cacheKey) as? Self else {
      let result = try fetchUniqueObject(in: context, with: configuration)
      context.setCachedManagedObject(result, forKey: cacheKey)

      return result
    }

    return cached
  }
}

// MARK: - Batch Delete

extension NSFetchRequestResult where Self: NSManagedObject {
  /// **CoreDataPlus**
  ///
  /// Executes a batch update on the context's persistent store coordinator.
  /// - Parameters:
  ///   - context: The context whose the persistent store coordinator will be used to execute the batch update.
  ///   - configuration: An handler to configure the NSBatchUpdateRequest.
  /// - Returns: a NSBatchUpdateRequest result.
  /// - Throws: It throws an error in cases of failure.
  /// - Note: A batch delete can only be done on a SQLite store.
  public static func batchUpdateObjects(with context: NSManagedObjectContext,
                                        configuration: ((NSBatchUpdateRequest) -> Void)? = nil) throws -> NSBatchUpdateResult {
    guard context.persistentStoreCoordinator != nil else { throw CoreDataPlusError.persistentStoreCoordinatorNotFound(context: context) }

    let batchRequest = NSBatchUpdateRequest(entityName: entityName)
    configuration?(batchRequest)
    /// propertiesToUpdate: Dictionary of NSPropertyDescription|property name string -> constantValue/NSExpression pairs describing the desired updates.
    /// The expressions can be any NSExpression that evaluates to a scalar value.
    /// Instead of nil use: NSExpression(forConstantValue: nil)

    do {
      // swiftlint:disable:next force_cast
      return try context.execute(batchRequest) as! NSBatchUpdateResult
    } catch {
      throw CoreDataPlusError.executionFailed(underlyingError: error)
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
  /// - Note: A batch delete can only be done on a SQLite store.
  @discardableResult
  public static func batchDeleteObjects(with context: NSManagedObjectContext,
                                        resultType: NSBatchDeleteRequestResultType = .resultTypeStatusOnly,
                                        configuration: ((NSFetchRequest<Self>) -> Void)? = nil) throws -> NSBatchDeleteResult {
    guard context.persistentStoreCoordinator != nil else { throw CoreDataPlusError.persistentStoreCoordinatorNotFound(context: context) }

    let request = NSFetchRequest<Self>(entityName: entityName)
    configuration?(request)

    // swiftlint:disable:next force_cast
    let batchRequest = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>)
    batchRequest.resultType = resultType

    do {
      // swiftlint:disable:next force_cast
      return try context.execute(batchRequest) as! NSBatchDeleteResult
    } catch {
      throw CoreDataPlusError.executionFailed(underlyingError: error)
    }
  }
}
