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
// TODO: mergeHistory in range of dates
// TODO: remove fatalErrors

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
  public func mergeHistory(after date: Date) throws -> Date? {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: date)
    historyFetchRequest.resultType = .transactionsAndChanges

    // Do your merging inside a context.performAndWait { … } as shown in WWDC 2017
    let lastDate = try performAndWait { context -> Date? in
      guard
        let historyResult = try context.execute(historyFetchRequest) as? NSPersistentHistoryResult,
        let history = historyResult.result as? [NSPersistentHistoryTransaction]
        else { fatalError("Cannot convert persistent history fetch result to transactions.") }

      var date: Date?
      for transaction in history {
        print("--->", transaction.contextName, transaction.author)
        transaction.changes?.forEach({ (change) in
          switch change.changeType {
          case .delete:
            print("delete")
          case .insert:
            print("insert")
          case .update:
            print("update")
          }
        })

        context.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
        date = transaction.timestamp
      }
      return date
    }
    return lastDate
  }

  /// **CoreDataPlus**
  ///
  /// Merges all the history changes made after a given `token`.
  /// With no token, merges all the history changes.
  /// - Parameter token: The NSPersistentHistoryToken after which changes are merged.
  /// - Throws: It throws an error in cases of failure.
  /// - Note: To enable history tracking:
  ///
  ///   ```
  ///   let description: NSPersistentStoreDescription = ... // Your default configuration here
  ///   description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
  ///   ```
  public func mergeHistory(after token: NSPersistentHistoryToken?) throws -> NSPersistentHistoryToken? {
    let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
    historyFetchRequest.resultType = .transactionsAndChanges

    // Do your merging inside a context.performAndWait { … } as shown in WWDC 2017
    let lastToken = try performAndWait { context -> NSPersistentHistoryToken? in
      guard
        let historyResult = try context.execute(historyFetchRequest) as? NSPersistentHistoryResult,
        let history = historyResult.result as? [NSPersistentHistoryTransaction]
        else {
          fatalError("Cannot convert persistent history fetch result to transactions.")
      }

      var token: NSPersistentHistoryToken?
      for transaction in history {
        mergeChanges(fromContextDidSave: transaction.objectIDNotification())
        token = transaction.token
      }
      return token
    }
    return lastToken
  }

  // MARK: - Delete

  @discardableResult
  public func deleteHistory(before date: Date) throws -> Bool {
    let deleteHistoryRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: date)
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
}
