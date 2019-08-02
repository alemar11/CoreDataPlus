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
import Foundation

// TODO: tombstone
// TODO: mergeHistory in range of dates/tokens
// TODO: Implement a service to sync tokens merges between different targets

@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
extension NSManagedObjectContext {
  // MARK: - Merge

  /// **CoreDataPlus**
  ///
  /// Merges all the history changes made after a given `date`.
  /// - Parameter date: The date after which changes are merged.
  /// - Throws: It throws an error in cases of failure.
  /// - Note: To enable history tracking:
  ///
  ///   ```
  ///   let description: NSPersistentStoreDescription = ... // Your default configuration here
  ///   description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
  ///   ```
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  public func mergeHistory(after date: Date) throws -> Date? {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: date)
    historyFetchRequest.resultType = .transactionsAndChanges

    do {
      // Do your merging inside a context.performAndWait { … } as shown in WWDC 2017
      let lastDate = try performAndWait { context -> Date? in
        // swiftlint:disable force_cast
        let historyResult = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
        let history = historyResult.result as! [NSPersistentHistoryTransaction]
        // swiftlint:enable force_cast

        var date: Date?
        for transaction in history {
          context.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
          date = transaction.timestamp
        }
        return date
      }
      return lastDate
    } catch {
      throw NSError.fetchFailed(underlyingError: error)
    }
  }

  // TODO add guide to add tombstone
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  public func processHistory(after date: Date, transactionHandler: (NSPersistentHistoryTransaction) throws -> Void) throws {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: date)
    historyFetchRequest.resultType = .transactionsAndChanges

    try performAndWait { context -> Void in
      // swiftlint:disable force_cast
      let historyResult = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
      let history = historyResult.result as! [NSPersistentHistoryTransaction]
      // swiftlint:enable force_cast

      for transaction in history {
        try transactionHandler(transaction)
      }
    }
  }

  /// **CoreDataPlus**
  ///
  /// Merges all the history changes made after a given `token`.
  /// With no token, merges all the history changes.
  /// - Parameter token: The NSPersistentHistoryToken after which changes are merged.
  /// - Throws: It throws an error in cases of failure.
  /// - Note:
  /// - To enable history tracking:
  ///
  ///   ```
  ///   let description: NSPersistentStoreDescription = ... // Your default configuration here
  ///   description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
  ///   ```
  ///  - After a save you can know the associated history token using this *NSPersistentStoreCoordinator * instance method:
  ///
  ///   ```
  ///  currentPersistentHistoryToken(fromStores stores: [Any]?) -> NSPersistentHistoryToken?
  ///   ```
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  public func mergeHistory(after token: NSPersistentHistoryToken?) throws -> NSPersistentHistoryToken? {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
    historyFetchRequest.resultType = .transactionsAndChanges

    do {
      // Do your merging inside a context.performAndWait { … } as shown in WWDC 2017
      let lastToken = try performAndWait { context -> NSPersistentHistoryToken? in

        // swiftlint:disable force_cast
        let historyResult = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
        let history = historyResult.result as! [NSPersistentHistoryTransaction]
        // swiftlint:enable force_cast

        var token: NSPersistentHistoryToken?
        for transaction in history {
          mergeChanges(fromContextDidSave: transaction.objectIDNotification())
          token = transaction.token
        }
        return token
      }
      return lastToken
    } catch {
      throw NSError.fetchFailed(underlyingError: error)
    }
  }

  // MARK: - Delete

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  @discardableResult
  public func deleteAllHistory() throws -> Bool {
    return try deleteHistory(before: .distantFuture)
  }

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  @discardableResult
  public func deleteHistory(before date: Date) throws -> Bool {
    let deleteHistoryRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: date)
    deleteHistoryRequest.resultType = .statusOnly

    do {
      let result = try performAndWait { context -> Bool in
        // swiftlint:disable force_cast
        let historyResult = try context.execute(deleteHistoryRequest) as! NSPersistentHistoryResult
        let status = historyResult.result as! Bool
        // swiftlint:enable force_cast
        return status
      }
      return result
    } catch {
      throw NSError.fetchFailed(underlyingError: error)
    }
  }

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  @discardableResult
  public func deleteHistory(before token: NSPersistentHistoryToken?) throws -> Bool {
    let deleteHistoryRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: token)
    deleteHistoryRequest.resultType = .statusOnly

    let result = try performAndWait { context -> Bool in
      // swiftlint:disable force_cast
      let historyResult = try context.execute(deleteHistoryRequest) as! NSPersistentHistoryResult
      let status = historyResult.result as! Bool
      // swiftlint:enable force_cast
      return status
    }
    return result
  }

  // TODO add guide to add tombstone
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
  public func processHistory(after token: NSPersistentHistoryToken?, transactionHandler: (NSPersistentHistoryTransaction) throws -> Void) throws {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
    historyFetchRequest.resultType = .transactionsAndChanges

    try performAndWait { context -> Void in
      // swiftlint:disable force_cast
      let historyResult = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
      let history = historyResult.result as! [NSPersistentHistoryTransaction]
      // swiftlint:enable force_cast

      for transaction in history {
        try transactionHandler(transaction)
      }
    }
  }
}
