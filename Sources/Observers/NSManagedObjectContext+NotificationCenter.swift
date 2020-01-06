//
// CoreDataPlus
//
// Copyright © 2016-2020 Tinrobots.
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

extension NSManagedObjectContext {
  /// **CoreDataPlus**
  ///
  /// Adds the given block to a `NotificationCenter`'s dispatch table for the did-save notifications.
  ///
  /// - Parameters:
  ///   - queue: The operation queue to which block should be added. If you pass nil, the block is run synchronously on the posting thread.
  ///   - handler: The block to be executed when the notification triggers.
  /// - Returns: An opaque object to act as the observer. This must be sent to the `NotificationCenter`'s `removeObserver()`.
  public func addManagedObjectContextDidSaveNotificationObserver(queue: OperationQueue? = nil,
                                                                 _ handler: @escaping (ManagedObjectContextDidSaveNotification) -> Void) -> NSObjectProtocol {
    return NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: self, queue: nil) { notification in
      let didSaveNotification = ManagedObjectContextDidSaveNotification(notification: notification)
      handler(didSaveNotification)
    }
  }

  /// **CoreDataPlus**
  ///
  /// Adds the given block to a `NotificationCenter`'s dispatch table for the will-save notifications.
  ///
  /// - Parameters:
  ///   - queue: The operation queue to which block should be added. If you pass nil, the block is run synchronously on the posting thread.
  ///   - handler: The block to be executed when the notification triggers.
  /// - Returns: An opaque object to act as the observer. This must be sent to the `NotificationCenter`'s `removeObserver()`.
  public func addManagedObjectContextWillSaveNotificationObserver(queue: OperationQueue? = nil,
                                                                  _ handler: @escaping (ManagedObjectContextWillSaveNotification) -> Void) -> NSObjectProtocol {
    return NotificationCenter.default.addObserver(forName: .NSManagedObjectContextWillSave, object: self, queue: queue) { notification in
      let willSaveNotification = ManagedObjectContextWillSaveNotification(notification: notification)
      handler(willSaveNotification)
    }
  }

  /// **CoreDataPlus**
  ///
  /// Adds the given block to a `NotificationCenter`'s dispatch table for the did-change notifications.
  ///
  /// - Parameters:
  ///   - queue: The operation queue to which block should be added. If you pass nil, the block is run synchronously on the posting thread.
  ///   - handler: The block to be executed when the notification triggers.
  /// - Returns: An opaque object to act as the observer. This must be sent to the `NotificationCenter`'s `removeObserver()`.
  public func addManagedObjectContextObjectsDidChangeNotificationObserver(queue: OperationQueue? = nil,
                                                                          _ handler: @escaping (ManagedObjectContextObjectsDidChangeNotification) -> Void) -> NSObjectProtocol {
    return NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: self, queue: queue) { notification in
      let didChangeNotification = ManagedObjectContextObjectsDidChangeNotification(notification: notification)
      handler(didChangeNotification)
    }
  }

  /// **CoreDataPlus**
  ///
  /// Asynchronously merges the changes specified in a given notification.
  /// This method refreshes any objects which have been updated in the other context,
  /// faults in any newly-inserted objects, and invokes delete(_:): on those which have been deleted.
  ///
  /// - Parameters:
  ///   - notification: An instance of an `NSManagedObjectContextDidSave` notification posted by another context.
  ///   - completion: The block to be executed after the merge completes.
  public func performMergeChanges(from notification: ManagedObjectContextDidSaveNotification, completion: @escaping () -> Void = {}) {
    perform {
      self.mergeChanges(fromContextDidSave: notification.notification)
      completion()
    }
  }

  /// **CoreDataPlus**
  ///
  /// Synchronously merges the changes specified in a given notification.
  /// This method refreshes any objects which have been updated in the other context,
  /// faults in any newly-inserted objects, and invokes delete(_:): on those which have been deleted.
  ///
  /// - Parameters:
  ///   - notification: An instance of an `NSManagedObjectContextDidSave` notification posted by another context.
  ///   - completion: The block to be executed after the merge completes.
  public func performAndWaitMergeChanges(from notification: ManagedObjectContextDidSaveNotification) {
    performAndWait {
      self.mergeChanges(fromContextDidSave: notification.notification)
    }
  }
}
