// CoreDataPlus
//
// https://mjtsai.com/blog/2020/08/21/persistent-history-tracking-in-core-data/
// https://developer.apple.com/documentation/coredata/consuming_relevant_store_changes
// https://developer.apple.com/documentation/coredata/synchronizing_a_local_store_to_the_cloud

import CoreData
import Foundation

// TODO: Implement a service to sync tokens merges between different targets

extension NSManagedObjectContext {
  // MARK: - History
  
  /// **CoreDataPlus**
  ///
  /// Returns all the history transactions created after a given `date`.
  /// - Throws: It throws an error in cases of failure.
  public func historyTransactions(after date: Date) throws -> [NSPersistentHistoryTransaction] {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: date)
    return try historyTransactions(using: historyFetchRequest)
  }
  
  /// **CoreDataPlus**
  ///
  /// Returns all the history transactions created after a given `token`.
  /// Without passing a token, it returns all the history transactions changes.
  /// - Throws: It throws an error in cases of failure.
  public func historyTransactions(after token: NSPersistentHistoryToken?) throws -> [NSPersistentHistoryTransaction] {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
    return try historyTransactions(using: historyFetchRequest)
  }
  
  /// **CoreDataPlus**
  ///
  /// Returns all the history transactions filtered by  a given `predicate`.
  ///
  /// The predicate conditions must be applied to these fields (of the "Transaction" entity):
  ///
  /// - `author` (`NSString`)
  /// - `bundleID` (`NSString`)
  /// - `contextName` (`NSString`)
  /// - `processID` (`NSString`)
  /// - `timestamp` (`NSDate`)
  /// - `token` (`NSNumber` - `NSInteger64`)
  /// - `transactionNumber` (`NSNumber` - `NSInteger64`)
  ///
  /// - Throws: It throws an error in cases of failure.
  /// - Parameters:
  ///   - predicate: Predicate used to filter the available transactions.
  ///   - context: Hint to be used in case the Transaction entity cannot be found automatically by the CoreData framework.
  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public func historyTransactions(where predicate: NSPredicate, with context: NSManagedObjectContext? = nil) throws -> [NSPersistentHistoryTransaction] {
    // https://developer.apple.com/videos/play/wwdc2019/230
    let historyFetchRequest = try NSPersistentHistoryChangeRequest.fetchRequest(where: predicate, with: context)
    return try historyTransactions(using: historyFetchRequest)
  }
  
  /// Returns all the history transactions using a `NSPersistentHistoryChangeRequest` instance.
  private func historyTransactions(using historyFetchRequest: NSPersistentHistoryChangeRequest) throws -> [NSPersistentHistoryTransaction] {
    historyFetchRequest.resultType = .transactionsAndChanges
    do {
      return try performAndWaitResult { context ->[NSPersistentHistoryTransaction] in
        // swiftlint:disable force_cast
        let history = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
        let transactions = history.result as! [NSPersistentHistoryTransaction] // ordered from the oldest to the most recent
        // swiftlint:enable force_cast
        return transactions
      }
    } catch {
      throw NSError.fetchFailed(underlyingError: error)
    }
  }
  
  // MARK: - Process Transactions
  
  /// **CoreDataPlus**
  ///
  /// Processes all the transactions in the history after a given `date`.
  /// - Parameter date: The date after which transactions are processed.
  /// - Throws: It throws an error in cases of failure.
  public func processHistory(after date: Date, transactionHandler: (NSPersistentHistoryTransaction) throws -> Void) throws {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: date)
    try processHistory(using: historyFetchRequest, transactionHandler: transactionHandler)
  }
  
  /// **CoreDataPlus**
  ///
  /// Processes all the transactions in the history after a given `token`.
  /// - Parameter token: The token after which transactions are processed.
  /// - Throws: It throws an error in cases of failure.
  /// - Note: Deletions can have tombstones if enabled on single attribues of an entity ( Data Model Inspector > "Preserve After Deletion").
  public func processHistory(after token: NSPersistentHistoryToken?, transactionHandler: (NSPersistentHistoryTransaction) throws -> Void) throws {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
    try processHistory(using: historyFetchRequest, transactionHandler: transactionHandler)
  }
  
  /// **CoreDataPlus**
  ///
  /// Processes all the transactions in the history filtered by a given predicate.
  ///
  /// The predicate conditions must be applied to these fields (of the "Transaction" entity):
  ///
  /// - `author` (`NSString`)
  /// - `bundleID` (`NSString`)
  /// - `contextName` (`NSString`)
  /// - `processID` (`NSString`)
  /// - `timestamp` (`NSDate`)
  /// - `token` (`NSNumber` - `NSInteger64`)
  /// - `transactionNumber` (`NSNumber` - `NSInteger64`)
  ///
  /// - Parameters:
  ///   - predicate: Predicate used to filter the available transactions.
  /// - Throws: It throws an error in cases of failure.
  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public func processHistory(where predicate: NSPredicate, transactionHandler: (NSPersistentHistoryTransaction) throws -> Void) throws {
    let historyFetchRequest = try NSPersistentHistoryChangeRequest.fetchRequest(where: predicate, with: self)
    try processHistory(using: historyFetchRequest, transactionHandler: transactionHandler)
  }
  
  /// Processes all the transactions in the history using a `NSPersistentHistoryChangeRequest` instance.
  private func processHistory(using historyFetchRequest: NSPersistentHistoryChangeRequest, transactionHandler: (NSPersistentHistoryTransaction) throws -> Void) throws {
    historyFetchRequest.resultType = .transactionsAndChanges
    try performAndWaitResult { context -> Void in
      // swiftlint:disable force_cast
      let history = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
      let transactions = history.result as! [NSPersistentHistoryTransaction] // ordered from the oldest to the most recent
      // swiftlint:enable force_cast
      for transaction in transactions {
        try transactionHandler(transaction)
      }
    }
  }
  
  // MARK: - Merge
  
  /// **CoreDataPlus**
  ///
  /// Merges all the history changes made after a given `date`.
  /// - Parameter date: The date after which changes are merged.
  /// - Returns: The last merged transaction date (*nil* means no merges).
  /// - Throws: It throws an error in cases of failure.
  /// - Note: To enable history tracking:
  ///
  ///   ```
  ///   let description: NSPersistentStoreDescription = ... // Your default configuration here
  ///   description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
  ///   ```
  ///
  ///  - After a saving operation, the associated history token can be obtained using this instance method: `NSPersistentStoreCoordinator.currentPersistentHistoryToken(fromStores:)`
  ///
  public func mergeHistory(after date: Date) throws -> Date? {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: date)
    return try mergeHistory(using: historyFetchRequest).1
  }
  
  /// **CoreDataPlus**
  ///
  /// Merges all the history changes made after a given `token`.
  /// Without passing a token, it merges all the history changes.
  /// - Parameter token: The NSPersistentHistoryToken after which changes are merged.
  /// - Returns: The last merged transaction `NSPersistentHistoryToken` (*nil* means no merges)..
  /// - Throws: It throws an error in cases of failure.
  /// - Note:
  /// - To enable history tracking:
  ///
  ///   ```
  ///   let description: NSPersistentStoreDescription = ... // Your default configuration here
  ///   description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
  ///   ```
  ///
  ///  - After a saving operation, the associated history token can be obtained using this instance method: `NSPersistentStoreCoordinator.currentPersistentHistoryToken(fromStores:)`
  ///
  public func mergeHistory(after token: NSPersistentHistoryToken?) throws -> NSPersistentHistoryToken? {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
    return try mergeHistory(using: historyFetchRequest).0
  }
  
  /// **CoreDataPlus**
  ///
  /// Merges all the history changes inside transations matching the given predicate.
  ///
  /// The predicate conditions must be applied to these fields (of the "Transaction" entity):
  ///
  /// - `author` (`NSString`)
  /// - `bundleID` (`NSString`)
  /// - `contextName` (`NSString`)
  /// - `processID` (`NSString`)
  /// - `timestamp` (`NSDate`)
  /// - `token` (`NSNumber` - `NSInteger64`)
  /// - `transactionNumber` (`NSNumber` - `NSInteger64`)
  ///
  /// - Parameter predicate: Predicate used to filter the available transactions.
  /// - Returns: true if some transaction changes matching the predicate have been merged.
  /// - Throws: It throws an error in cases of failure.
  /// - Note:
  /// - To enable history tracking:
  ///
  ///   ```
  ///   let description: NSPersistentStoreDescription = ... // Your default configuration here
  ///   description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
  ///   ```
  ///
  ///  - After a saving operation, the associated history token can be obtained using this instance method: `NSPersistentStoreCoordinator.currentPersistentHistoryToken(fromStores:)`
  ///
  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public func mergeHistory(where predicate: NSPredicate) throws -> Bool {
    let historyFetchRequest = try NSPersistentHistoryChangeRequest.fetchRequest(where: predicate, with: self)
    return try mergeHistory(using: historyFetchRequest).0 != nil
  }
  
  /// Merges all the history changes using a `NSPersistentHistoryChangeRequest` instance.
  private func mergeHistory(using historyFetchRequest: NSPersistentHistoryChangeRequest) throws -> (NSPersistentHistoryToken?, Date?) {
    historyFetchRequest.resultType = .transactionsAndChanges
    do {
      // Do your merging inside a context.performAndWait { … } as shown in WWDC 2017
      let result = try performAndWaitResult { context -> (NSPersistentHistoryToken?, Date?) in
        // swiftlint:disable force_cast
        let history = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
        let transactions = history.result as! [NSPersistentHistoryTransaction] // ordered from the oldest to the most recent
        // swiftlint:enable force_cast
        var token: NSPersistentHistoryToken?
        var date: Date?
        for transaction in transactions {
          guard transaction.changes != nil else { continue }
          
          mergeChanges(fromContextDidSave: transaction.objectIDNotification())
          token = transaction.token
          date = transaction.timestamp
        }
        return (token, date)
      }
      return result
    } catch {
      throw NSError.fetchFailed(underlyingError: error)
    }
  }
  
  // MARK: - Delete
  
  /// **CoreDataPlus**
  ///
  /// Deletes all history.
  @discardableResult
  public func deleteHistory() throws -> Bool {
    return try deleteHistory(before: .distantFuture)
  }
  
  /// **CoreDataPlus**
  ///
  /// Deletes all history before a given `date`.
  ///
  /// - Parameter date: The date before which the history will be deleted.
  /// - Returns: `true` if the operation succeeds.
  /// - Throws: It throws an error in cases of failure.
  /// - Note: Deletions can have tombstones if enabled on single attribues of an entity ( Data Model Inspector > "Preserve After Deletion").
  @discardableResult
  public func deleteHistory(before date: Date) throws -> Bool {
    let deleteHistoryRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: date)
    return try deleteHistory(using: deleteHistoryRequest)
  }
  
  /// **CoreDataPlus**
  ///
  /// Deletes all history before a given `token`.
  ///
  /// - Parameter token: The token before which the history will be deleted.
  /// - Returns: `true` if the operation succeeds.
  /// - Throws: It throws an error in cases of failure.
  @discardableResult
  public func deleteHistory(before token: NSPersistentHistoryToken?) throws -> Bool {
    let deleteHistoryRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: token)
    return try deleteHistory(using: deleteHistoryRequest)
  }
  
  /// Deletes all history given a delete `NSPersistentHistoryChangeRequest` instance.
  private func deleteHistory(using deleteHistoryRequest: NSPersistentHistoryChangeRequest) throws -> Bool {
    deleteHistoryRequest.resultType = .statusOnly
    do {
      let result = try performAndWaitResult { context -> Bool in
        // swiftlint:disable force_cast
        let history = try context.execute(deleteHistoryRequest) as! NSPersistentHistoryResult
        let status = history.result as! Bool
        // swiftlint:enable force_cast
        return status
      }
      return result
    } catch {
      throw NSError.historyChangesDeletionFailed(underlyingError: error)
    }
  }
}

extension NSPersistentHistoryChangeRequest {
  /// Creates an history change request for a given predicate; the context is used as hint to discover the Transaction entity.
  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  final class func fetchRequest(where predicate: NSPredicate, with context: NSManagedObjectContext? = nil) throws -> NSPersistentHistoryChangeRequest {
    guard let request = NSFetchRequest<NSFetchRequestResult>.historyTransationFetchRequest(with: context) else {
      throw NSError.invalidFetchRequest()
    }
    
    request.predicate = predicate
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(withFetch: request)
    return historyFetchRequest
  }
}

extension NSFetchRequest where ResultType == NSFetchRequestResult {
  /// Creates a NSFetchRequest to be used to query history transactionss
  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  final class func historyTransationFetchRequest(with context: NSManagedObjectContext? = nil) -> NSFetchRequest<NSFetchRequestResult>? {
    if let context = context, let entity = NSPersistentHistoryTransaction.entityDescription(with: context) {
      let request = NSFetchRequest<NSFetchRequestResult>()
      request.entity = entity
      return request
      // or request = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name!)
    } else {
      return NSPersistentHistoryTransaction.fetchRequest
    }
  }
}
