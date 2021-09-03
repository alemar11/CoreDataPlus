// CoreDataPlus
//
// https://mjtsai.com/blog/2019/08/21/persistent-history-tracking-in-core-data/
// https://developer.apple.com/documentation/coredata/consuming_relevant_store_changes
// https://developer.apple.com/documentation/coredata/synchronizing_a_local_store_to_the_cloud

// WWDC 2017, Introduction: https://developer.apple.com/videos/play/wwdc2017/210/
// WWDC 2018, Bulk operations and history changes: https://developer.apple.com/videos/play/wwdc2018/224/
// WWDC 2019, Fetches and Remote Change Notifications: https://developer.apple.com/videos/play/wwdc2019/230
// WWDC 2020, History requests can be tailored like standard fetch requests (see testInvestigationHistoryFetches), Remote Change Notifications fired when the app goes in foreground if an app extension has done some Core Data transactions: https://developer.apple.com/videos/play/wwdc2020/10017/

import CoreData
import Foundation

extension NSManagedObjectContext {
  // MARK: - Transactions

  /// Returns all the history transactions  for given a `NSPersistentHistoryChangeRequest` request.
  ///
  /// - Parameters:
  ///   - historyFetchRequest: A request to fetch persistent history transactions.
  ///   - withAssociatedChanges: if `true` (default) each transaction will contain all its changes.
  public func historyTransactions(using historyFetchRequest: NSPersistentHistoryChangeRequest, andAssociatedChanges enableChanges: Bool = true) throws -> [NSPersistentHistoryTransaction] {
    historyFetchRequest.resultType = enableChanges ? .transactionsAndChanges : .transactionsOnly
    return try performAndWaitResult { context ->[NSPersistentHistoryTransaction] in
      // swiftlint:disable force_cast
      let history = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
      let transactions = history.result as! [NSPersistentHistoryTransaction] // ordered from the oldest to the most recent
      // swiftlint:enable force_cast
      return transactions
    }
  }

  // MARK: - Changes

  /// Returns all the history changes for given a `NSPersistentHistoryChangeRequest` request.
  ///
  /// - Parameter historyFetchRequest: A request to fetch persistent history changes.
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

  /// Deletes all history.
  @discardableResult
  public func deleteHistory() throws -> Bool {
    return try deleteHistory(before: .distantFuture)
  }

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

  /// Deletes all history before a given `transaction`.
  ///
  /// - Parameter transaction: The transaction before which the history will be deleted.
  /// - Returns: `true` if the operation succeeds.
  /// - Throws: It throws an error in cases of failure.
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
