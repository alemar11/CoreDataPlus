//
// CoreDataPlus
//
// Copyright © 2016-2018 Tinrobots.
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

public protocol NSManagedObjectContextNotification {
  var notification: Notification { get set}
  init(notification: Notification)
  var managedObjectContext: NSManagedObjectContext { get }
}

public extension NSManagedObjectContextNotification {
  /// **CoreDataPlus**
  ///
  /// Returns the notification's `NSManagedObjectContext`.
  public var managedObjectContext: NSManagedObjectContext {
    guard let context = notification.object as? NSManagedObjectContext else { fatalError("Invalid notification object.") }
    return context
  }

  fileprivate func objects(forKey key: String) -> Set<NSManagedObject> {
    return (notification.userInfo?[key] as? Set<NSManagedObject>) ?? Set()
  }
}

public protocol NSManagedObjectContextObserving_: NSManagedObjectContextNotification {
  /// **CoreDataPlus**
  ///
  /// A `Set` of objects that were refreshed but were not dirtied in the scope of this context.
  var refreshedObjects: Set<NSManagedObject> { get }

    /// **CoreDataPlus**
    ///
    /// A `Set` of objects that were invalidated.
  var invalidatedObjects: Set<NSManagedObject> { get }

  //  /// **CoreDataPlus**
  //  ///
  //  /// Returns `true` if all the objects in the context have been invalidated.
  var invalidatedAllObjects: Bool { get }
}

public protocol NSManagedObjectContextObserving: NSManagedObjectContextNotification {
  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were inserted into the context.
  var insertedObjects: Set<NSManagedObject> { get }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were updated.
  var updatedObjects: Set<NSManagedObject> { get }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set`of objects that were marked for deletion during the previous event.
  var deletedObjects: Set<NSManagedObject> { get }

  //  /// **CoreDataPlus**
  //  ///
  //  /// A `Set` of objects that were refreshed but were not dirtied in the scope of this context.
  //  public var refreshedObjects: Set<NSManagedObject> {
  //    return objects(forKey: NSRefreshedObjectsKey)
  //  }
  //
  //  /// **CoreDataPlus**
  //  ///
  //  /// A `Set` of objects that were invalidated
  //  var invalidatedObjects: Set<NSManagedObject> { get }
  //
  //  /// **CoreDataPlus**
  //  ///
  //  /// Returns `true` if all the objects in the context have been invalidated.
  //  var invalidatedAllObjects: Bool { get }
}

extension NSManagedObjectContextObserving {

  public var insertedObjects: Set<NSManagedObject> {
    return objects(forKey: NSInsertedObjectsKey)
  }

  public var updatedObjects: Set<NSManagedObject> {
    return objects(forKey: NSUpdatedObjectsKey)
  }

  public var deletedObjects: Set<NSManagedObject> {
    return objects(forKey: NSDeletedObjectsKey)
  }

}

// Note: Since we receive these notifications only when we change manually a NSManagedObject, we don’t trigger them if we execute NSBatchUpdateRequest/NSBatchDeleteRequest.

// MARK: - NSManagedObjectContextDidSave

public struct ContextDidSaveNotification {

  fileprivate let notification: Notification

  public init(notification: Notification) {
    guard notification.name == .NSManagedObjectContextDidSave else { fatalError("Invalid NSManagedObjectContextDidSave notification object.") }
    self.notification = notification
  }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were inserted into the context.
  public var insertedObjects: Set<NSManagedObject> {
    return objects(forKey: NSInsertedObjectsKey)
  }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were updated.
  public var updatedObjects: Set<NSManagedObject> {
    return objects(forKey: NSUpdatedObjectsKey)
  }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set`of objects that were marked for deletion during the previous event.
  public var deletedObjects: Set<NSManagedObject> {
    return objects(forKey: NSDeletedObjectsKey)
  }

  /// **CoreDataPlus**
  ///
  /// Returns the notification's `NSManagedObjectContext`.
  public var managedObjectContext: NSManagedObjectContext {
    guard let context = notification.object as? NSManagedObjectContext else { fatalError("Invalid notification object.") }
    return context
  }

  private func objects(forKey key: String) -> Set<NSManagedObject> {
    return (notification.userInfo?[key] as? Set<NSManagedObject>) ?? Set()
  }

  //  private func iterator(forKey key: String) -> AnyIterator<NSManagedObject> {
  //    guard let set = notification.userInfo?[key] as? NSSet else { return AnyIterator { nil } }
  //
  //    var innerIterator = set.makeIterator()
  //    return AnyIterator { return innerIterator.next() as? NSManagedObject }
  //  }

}

extension ContextDidSaveNotification: CustomDebugStringConvertible {

  public var debugDescription: String {
    var components = [notification.name.rawValue]
    components.append(managedObjectContext.description)

    for (name, set) in [("inserted", insertedObjects), ("updated", updatedObjects), ("deleted", deletedObjects)] {
      let all = set.map { $0.objectID.description }.joined(separator: ", ")
      components.append("\(name): {\(all)})")
    }

    return components.joined(separator: " ")
  }

}

// MARK: - NSManagedObjectContextWillSave

public struct ContextWillSaveNotification {

  fileprivate let notification: Notification

  public init(notification: Notification) {
    guard notification.name == .NSManagedObjectContextWillSave else { fatalError("Invalid NSManagedObjectContextWillSave notification object.") }
    self.notification = notification
  }

  /// **CoreDataPlus**
  ///
  /// Returns the notification's `NSManagedObjectContext`.
  public var managedObjectContext: NSManagedObjectContext {
    guard let context = notification.object as? NSManagedObjectContext else { fatalError("Invalid notification object.") }
    return context
  }

}

// MARK: - NSManagedObjectContextObjectsDidChange

public struct ObjectsDidChangeNotification {

  private let notification: Notification

  init(notification: Notification) {
    // Notification when objects in a context changed:  the user info dictionary contains information about the objects that changed and what changed
    guard notification.name == .NSManagedObjectContextObjectsDidChange else { fatalError("Invalid NSManagedObjectContextObjectsDidChange notification object.") }
    self.notification = notification
  }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were inserted into the context.
  public var insertedObjects: Set<NSManagedObject> {
    return objects(forKey: NSInsertedObjectsKey)
  }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were updated.
  public var updatedObjects: Set<NSManagedObject> {
    return objects(forKey: NSUpdatedObjectsKey)
  }

  /// **CoreDataPlus**
  ///
  ///
  /// Returns a `Set`of objects that were marked for deletion during the previous event.
  public var deletedObjects: Set<NSManagedObject> {
    return objects(forKey: NSDeletedObjectsKey)
  }

  /// **CoreDataPlus**
  ///
  /// A `Set` of objects that were refreshed but were not dirtied in the scope of this context.
  public var refreshedObjects: Set<NSManagedObject> {
    return objects(forKey: NSRefreshedObjectsKey)
  }

  /// **CoreDataPlus**
  ///
  /// A `Set` of objects that were invalidated
  public var invalidatedObjects: Set<NSManagedObject> {
    return objects(forKey: NSInvalidatedObjectsKey)
  }

  /// **CoreDataPlus**
  ///
  /// Returns `true` if all the objects in the context have been invalidated.
  public var invalidatedAllObjects: Bool {
    return notification.userInfo?[NSInvalidatedAllObjectsKey] != nil //TODO: returns a set?
  }

  /// **CoreDataPlus**
  ///
  /// Returns the notification's `NSManagedObjectContext`.
  public var managedObjectContext: NSManagedObjectContext {
    guard let context = notification.object as? NSManagedObjectContext else { fatalError("Invalid notification object.") }
    return context
  }

  private func objects(forKey key: String) -> Set<NSManagedObject> {
    return (notification.userInfo?[key] as? Set<NSManagedObject>) ?? Set()
  }

}

// MARK: - NSManagedObjectContext

extension NSManagedObjectContext {

  /// **CoreDataPlus**
  ///
  /// Adds the given block to a `NotificationCenter`'s dispatch table for the did-save notifications.
  ///
  /// - Parameters:
  ///   - notificationCenter: The `NotificationCenter`
  ///   - handler: The block to be executed when the notification triggers.
  /// - Returns: An opaque object to act as the observer. This must be sent to the `NotificationCenter`'s `removeObserver()`.
  public func addContextDidSaveNotificationObserver(notificationCenter: NotificationCenter = .default, _ handler: @escaping (ContextDidSaveNotification) -> Void) -> NSObjectProtocol {

    return notificationCenter.addObserver(forName: .NSManagedObjectContextDidSave, object: self, queue: nil) { notification in
      let didSaveNotification = ContextDidSaveNotification(notification: notification)
      handler(didSaveNotification)
    }
  }

  /// **CoreDataPlus**
  ///
  /// Adds the given block to a `NotificationCenter`'s dispatch table for the will-save notifications.
  ///
  /// - Parameters:
  ///   - notificationCenter: The `NotificationCenter`
  ///   - handler: The block to be executed when the notification triggers.
  /// - Returns: An opaque object to act as the observer. This must be sent to the `NotificationCenter`'s `removeObserver()`.
  public func addContextWillSaveNotificationObserver(notificationCenter: NotificationCenter = .default, _ handler: @escaping (ContextWillSaveNotification) -> Void) -> NSObjectProtocol {

    return notificationCenter.addObserver(forName: .NSManagedObjectContextWillSave, object: self, queue: nil) { notification in
      let willSaveNotification = ContextWillSaveNotification(notification: notification)
      handler(willSaveNotification)
    }
  }

  /// **CoreDataPlus**
  ///
  /// Adds the given block to a `NotificationCenter`'s dispatch table for the did-change notifications.
  ///
  /// - Parameters:
  ///   - notificationCenter: The `NotificationCenter`
  ///   - handler: The block to be executed when the notification triggers.
  /// - Returns: An opaque object to act as the observer. This must be sent to the `NotificationCenter`'s `removeObserver()`.
  public func addObjectsDidChangeNotificationObserver(notificationCenter: NotificationCenter = .default, _ handler: @escaping (ObjectsDidChangeNotification) -> Void) -> NSObjectProtocol {

    return notificationCenter.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: self, queue: nil) { notification in
      let didChangeNotification = ObjectsDidChangeNotification(notification: notification)
      handler(didChangeNotification)
    }
  }

  /// **CoreDataPlus**
  ///
  /// Asynchronously merges the changes specified in a given notification.
  ///
  /// - Parameters:
  ///   - notification: An instance of an `NSManagedObjectContextDidSave` notification posted by another context.
  ///   - completion: The block to be executed after the merge completes.
  public func performMergeChanges(from notification: ContextDidSaveNotification, completion: @escaping () -> Void = {}) {
    perform {
      self.mergeChanges(fromContextDidSave: notification.notification)
      completion()
    }
  }

  /// **CoreDataPlus**
  ///
  /// Synchronously merges the changes specified in a given notification.
  ///
  /// - Parameters:
  ///   - notification: An instance of an `NSManagedObjectContextDidSave` notification posted by another context.
  ///   - completion: The block to be executed after the merge completes.
  public func performAndWaitMergeChanges(from notification: ContextDidSaveNotification) {
    performAndWait {
      self.mergeChanges(fromContextDidSave: notification.notification)
    }
  }

}
