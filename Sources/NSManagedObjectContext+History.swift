// CoreDataPlus
//
// https://mjtsai.com/blog/2020/08/21/persistent-history-tracking-in-core-data/
// https://developer.apple.com/documentation/coredata/consuming_relevant_store_changes
// https://developer.apple.com/documentation/coredata/synchronizing_a_local_store_to_the_cloud
// WWDC 2020: History requests can be tailored like standard fetch requests (see testInvestigationHistoryFetches)

import CoreData
import Foundation

extension NSManagedObjectContext {
  // MARK: - Transactions
  
  /// Returns all the history transactions (anche their associated changes) given a `NSPersistentHistoryChangeRequest` request.
  public func historyTransactions(using historyFetchRequest: NSPersistentHistoryChangeRequest) throws -> [NSPersistentHistoryTransaction] {
    historyFetchRequest.resultType = .transactionsAndChanges
    return try performAndWaitResult { context ->[NSPersistentHistoryTransaction] in
      // swiftlint:disable force_cast
      let history = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
      let transactions = history.result as! [NSPersistentHistoryTransaction] // ordered from the oldest to the most recent
      // swiftlint:enable force_cast
      return transactions
    }
  }
  
  // MARK: - Changes
  
  /// Returns all the history changes given a `NSPersistentHistoryChangeRequest` request.
  public func historyChanges(using historyFetchRequest: NSPersistentHistoryChangeRequest) throws -> [NSPersistentHistoryChange] {
    historyFetchRequest.resultType = .changesOnly
    return try performAndWaitResult { context ->[NSPersistentHistoryChange] in
      // swiftlint:disable force_cast
      let history = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
      let changes = history.result as! [NSPersistentHistoryChange] // ordered from the oldest to the most recent
      // swiftlint:enable force_cast
      return changes
    }
  }
  
  /// Merges all the changes contained in the given list of `NSPersistentHistoryTransaction`.
  /// Returns the last merged transaction's token and timestamp.
  public func mergeTransactions(_ transactions: [NSPersistentHistoryTransaction]) throws -> (NSPersistentHistoryToken, Date)? {
    // Do your merging inside a context.performAndWait { … } as shown in WWDC 2017
    let result = performAndWaitResult { _ -> (NSPersistentHistoryToken, Date)? in
      var result: (NSPersistentHistoryToken, Date)?
      for transaction in transactions {
        result = (transaction.token, transaction.timestamp)
        guard transaction.changes != nil else { continue }
        
        mergeChanges(fromContextDidSave: transaction.objectIDNotification())
      }
      return result
    }
    return result
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
  
  @discardableResult
  public func deleteHistory(before transaction: NSPersistentHistoryTransaction) throws -> Bool {
    let deleteHistoryRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: transaction)
    return try deleteHistory(using: deleteHistoryRequest)
  }
  
  /// Deletes all history given a delete `NSPersistentHistoryChangeRequest` instance.
  private func deleteHistory(using deleteHistoryRequest: NSPersistentHistoryChangeRequest) throws -> Bool {
    deleteHistoryRequest.resultType = .statusOnly
    let result = try performAndWaitResult { context -> Bool in
      // swiftlint:disable force_cast
      let history = try context.execute(deleteHistoryRequest) as! NSPersistentHistoryResult
      let status = history.result as! Bool
      // swiftlint:enable force_cast
      return status
    }
    return result
  }
}

extension NSPersistentHistoryChangeRequest {
  /// **CoreDataPlus**
  ///
  /// Creates a NSPersistentHistoryChangeRequest to query the Transaction entity.
  /// - Note: context is used as hint to discover the Transaction entity.
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
  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public final class func historyTransactionFetchRequest(with context: NSManagedObjectContext, where predicate: NSPredicate) -> NSPersistentHistoryChangeRequest? {
    guard let entity = NSPersistentHistoryTransaction.entityDescription(with: context) else { return nil }
    
    let transactionFetchRequest = NSFetchRequest<NSFetchRequestResult>()
    transactionFetchRequest.entity = entity
    // same as (but for some reasons it's nil during tests):
    // https://developer.apple.com/videos/play/wwdc2019/230
    // let transactionFetchRequest = NSPersistentHistoryTransaction.fetchRequest
    
    transactionFetchRequest.predicate = predicate
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(withFetch: transactionFetchRequest)
    return historyFetchRequest
  }
  
  /// **CoreDataPlus**
  ///
  /// Creates a NSPersistentHistoryChangeRequest to query the Change entity.
  /// - Note: context is used as hint to discover the Change entity.
  ///
  /// The predicate conditions must be applied to these fields (of the "Change" entity):
  ///
  /// - `changedID` (`NSNumber` - `NSInteger64`)
  /// - `changedEntity` (`NSNumber` - `NSInteger64`)
  /// - `changeType` (`NSNumber` - `NSInteger64`)
  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public final class func historyChangeFetchRequest(with context: NSManagedObjectContext, where predicate: NSPredicate) -> NSPersistentHistoryChangeRequest? {
    guard let entity = NSPersistentHistoryChange.entityDescription(with: context) else { return nil }
    
    let changeFetchRequest = NSFetchRequest<NSFetchRequestResult>()
    changeFetchRequest.entity = entity
    // same as (but for some reasons it's nil during tests):
    // https://developer.apple.com/videos/play/wwdc2019/230
    // let changeFetchRequest = NSPersistentHistoryChange.fetchRequest
    
    changeFetchRequest.predicate = predicate
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(withFetch: changeFetchRequest)
    return historyFetchRequest
  }
}
