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

// MARK: - NSManagedObjectContextDidSave

public struct ContextDidSaveNotification {

  fileprivate let notification: Notification

  public init(notification: Notification) {
    guard notification.name == .NSManagedObjectContextDidSave else { fatalError() }
    self.notification = notification
  }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were inserted into the context.
  public var insertedObjects: AnyIterator<NSManagedObject> {
    return iterator(forKey: NSInsertedObjectsKey)
  }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were updated.
  public var updatedObjects: AnyIterator<NSManagedObject> {
    return iterator(forKey: NSUpdatedObjectsKey)
  }

  /// **CoreDataPlus**
  ///
  /// Returns a `Set`of objects that were marked for deletion during the previous event.
  public var deletedObjects: AnyIterator<NSManagedObject> {
    return iterator(forKey: NSDeletedObjectsKey)
  }

  public var managedObjectContext: NSManagedObjectContext {
    guard let context = notification.object as? NSManagedObjectContext else { fatalError("Invalid notification object") }
    return context
  }

  private func iterator(forKey key: String) -> AnyIterator<NSManagedObject> {
    //TODO: check this method
    guard let set = notification.userInfo?[key] as? NSSet else { return AnyIterator { nil } }

    var innerIterator = set.makeIterator()
    return AnyIterator { return innerIterator.next() as? NSManagedObject }
  }

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
    assert(notification.name == .NSManagedObjectContextWillSave)
    self.notification = notification
  }

  public var managedObjectContext: NSManagedObjectContext {
    guard let context = notification.object as? NSManagedObjectContext else { fatalError("Invalid notification object") }
    return context
  }

}

// MARK: - NSManagedObjectContextObjectsDidChange

public struct ObjectsDidChangeNotification {

  private let notification: Notification

  init(notification: Notification) {
    // Notification when objects in a context changed:  the user info dictionary contains information about the objects that changed and what changed
    assert(notification.name == .NSManagedObjectContextObjectsDidChange)
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
    return (notification as Notification).userInfo?[NSInvalidatedAllObjectsKey] != nil
  }

  public var managedObjectContext: NSManagedObjectContext {
    guard let context = notification.object as? NSManagedObjectContext else { fatalError("Invalid notification object") }
    return context
  }

  private func objects(forKey key: String) -> Set<NSManagedObject> {
    return ((notification as Notification).userInfo?[key] as? Set<NSManagedObject>) ?? Set()
  }

}

extension NSManagedObjectContext {

  /// **CoreDataPlus**
  ///
  /// A notification that the context completed a save.
  /// Adds the given block to the default `NotificationCenter`'s dispatch table for the given context's did-save notifications.
  /// - returns: An opaque object to act as the observer. This must be sent to the default `NotificationCenter`'s `removeObserver()`.
  public func addContextDidSaveNotificationObserver(notificationCenter: NotificationCenter = .default, _ handler: @escaping (ContextDidSaveNotification) -> Void) -> NSObjectProtocol {

    return notificationCenter.addObserver(forName: .NSManagedObjectContextDidSave, object: self, queue: nil) { notfication in
      let didSaveNotification = ContextDidSaveNotification(notification: notfication)
      handler(didSaveNotification)
    }
  }

  /// **CoreDataPlus**
  ///
  /// A notification that the context is about to save.
  /// Adds the given block to the default `NotificationCenter`'s dispatch table for the given context's will-save notifications.
  /// - returns: An opaque object to act as the observer. This must be sent to the default `NotificationCenter`'s `removeObserver()`.
  public func addContextWillSaveNotificationObserver(notificationCenter: NotificationCenter = .default, _ handler: @escaping (ContextWillSaveNotification) -> Void) -> NSObjectProtocol {

    return notificationCenter.addObserver(forName: .NSManagedObjectContextWillSave, object: self, queue: nil) { notfication in
      let willSaveNotification = ContextWillSaveNotification(notification: notfication)
      handler(willSaveNotification)
    }
  }

  /// **CoreDataPlus**
  ///
  /// A notification of changes made to managed objects associated with this context.
  /// Adds the given block to the default `NotificationCenter`'s dispatch table for the given context's objects-did-change notifications.
  /// - returns: An opaque object to act as the observer. This must be sent to the default `NotificationCenter`'s `removeObserver()`.
  public func addObjectsDidChangeNotificationObserver(notificationCenter: NotificationCenter = .default, _ handler: @escaping (ObjectsDidChangeNotification) -> Void) -> NSObjectProtocol {

    return notificationCenter.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: self, queue: nil) { notfication in
      let didChangeNotification = ObjectsDidChangeNotification(notification: notfication)
      handler(didChangeNotification)
    }
  }

  public func performMergeChanges(from notification: ContextDidSaveNotification) {
    perform {
      self.mergeChanges(fromContextDidSave: notification.notification)
    }
  }

}
