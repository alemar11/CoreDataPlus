// CoreDataPlus
//
// https://mjtsai.com/blog/2020/08/21/persistent-history-tracking-in-core-data/

import CoreData
import Foundation

// TODO: mergeHistory in range of dates/tokens
// TODO: Implement a service to sync tokens merges between different targets

@available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
extension NSManagedObjectContext {
  // MARK: - History

  /// **CoreDataPlus**
  ///
  /// Returns all the history transactions created after a given `date`.
  /// - Throws: It throws an error in cases of failure.
  @available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  public func historyTransaction(after date: Date) throws -> [NSPersistentHistoryTransaction] {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: date)
    return try historyTransaction(using: historyFetchRequest)
  }

  /// **CoreDataPlus**
  ///
  /// Returns all the history transactions created after a given `token`.
  /// Without passing a token, it returns all the history transactions changes.
  /// - Throws: It throws an error in cases of failure.
  @available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  public func historyTransaction(after token: NSPersistentHistoryToken?) throws -> [NSPersistentHistoryTransaction] {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
    return try historyTransaction(using: historyFetchRequest)
  }

  /// Returns all the history transactions using a `NSPersistentHistoryChangeRequest` instance.
  @available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  private func historyTransaction(using historyFetchRequest: NSPersistentHistoryChangeRequest) throws -> [NSPersistentHistoryTransaction] {
    historyFetchRequest.resultType = .transactionsAndChanges
    do {
      return try performAndWaitResult { context ->[NSPersistentHistoryTransaction] in
        // swiftlint:disable force_cast
        let history = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
        let transactions = history.result as! [NSPersistentHistoryTransaction]
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
  @available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
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
  @available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  public func processHistory(after token: NSPersistentHistoryToken?, transactionHandler: (NSPersistentHistoryTransaction) throws -> Void) throws {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
    try processHistory(using: historyFetchRequest, transactionHandler: transactionHandler)
  }

  /// Processes all the transactions in the history using a `NSPersistentHistoryChangeRequest` instance.
  @available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  private func processHistory(using historyFetchRequest: NSPersistentHistoryChangeRequest, transactionHandler: (NSPersistentHistoryTransaction) throws -> Void) throws {
    historyFetchRequest.resultType = .transactionsAndChanges
    try performAndWaitResult { context -> Void in
      // swiftlint:disable force_cast
      let history = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
      let transactions = history.result as! [NSPersistentHistoryTransaction]
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
  /// - Returns: The last merged transaction date.
  /// - Throws: It throws an error in cases of failure.
  /// - Note: To enable history tracking:
  ///
  ///   ```
  ///   let description: NSPersistentStoreDescription = ... // Your default configuration here
  ///   description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
  ///   ```
  @available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  public func mergeHistory(after date: Date) throws -> Date? {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: date)
    return try mergeHistory(using: historyFetchRequest).1
  }

  /// **CoreDataPlus**
  ///
  /// Merges all the history changes made after a given `token`.
  /// Without passing a token, it merges all the history changes.
  /// - Parameter token: The NSPersistentHistoryToken after which changes are merged.
  /// - Returns: The last merged transaction NSPersistentHistoryToken.
  /// - Throws: It throws an error in cases of failure.
  /// - Note:
  /// - To enable history tracking:
  ///
  ///   ```
  ///   let description: NSPersistentStoreDescription = ... // Your default configuration here
  ///   description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
  ///   ```
  ///  - After a saving operation, the associated history token using this instance method: `NSPersistentStoreCoordinator.currentPersistentHistoryToken(fromStores:)`
  ///
  @available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  public func mergeHistory(after token: NSPersistentHistoryToken?) throws -> NSPersistentHistoryToken? {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
    return try mergeHistory(using: historyFetchRequest).0
  }

  /// Merges all the history changes using a `NSPersistentHistoryChangeRequest` instance.
  @available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  private func mergeHistory(using historyFetchRequest: NSPersistentHistoryChangeRequest) throws -> (NSPersistentHistoryToken?, Date?) {
    historyFetchRequest.resultType = .transactionsAndChanges
    do {
      // Do your merging inside a context.performAndWait { … } as shown in WWDC 2017
      let result = try performAndWaitResult { context -> (NSPersistentHistoryToken?, Date?) in
        // swiftlint:disable force_cast
        let history = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
        let transactions = history.result as! [NSPersistentHistoryTransaction]
        // swiftlint:enable force_cast
        var token: NSPersistentHistoryToken?
        var date: Date?
        for transaction in transactions {
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
  @available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
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
  @available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
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
  @available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  @discardableResult
  public func deleteHistory(before token: NSPersistentHistoryToken?) throws -> Bool {
    let deleteHistoryRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: token)
    return try deleteHistory(using: deleteHistoryRequest)
  }

  /// Deletes all history given a delete `NSPersistentHistoryChangeRequest` instance.
  @available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
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
      throw NSError.fetchFailed(underlyingError: error) // TODO: this is not a fetch failed error
    }
  }
}
