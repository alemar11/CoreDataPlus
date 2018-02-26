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

///  Protocol for delegate callbacks of `NSManagedObject` entity change events.
public protocol EntityObserverDelegate: class {
  associatedtype ManagedObject: NSManagedObject

  // TODO: better description, remove the "matching the predicate"

  /// **CoreDataPlus**
  ///
  /// Called when objects matching the predicate have been inserted.
  ///
  /// - parameter observer: The `EntityObserver` posting the callback.
  /// - parameter entities: The set of inserted objects.
  /// - parameter event: The entity change event type.
  func entityObserver(_ observer: EntityObserver<ManagedObject>, inserted: Set<ManagedObject>, event: ObservedEvent)

  /// **CoreDataPlus**
  ///
  /// Called when objects matching the predicate have been deleted.
  ///
  /// - parameter observer: The `EntityObserver` posting the callback.
  /// - parameter entities: The set of deleted objects.
  /// - parameter event: The entity change event type.
  func entityObserver(_ observer: EntityObserver<ManagedObject>, deleted: Set<ManagedObject>, event: ObservedEvent)

  /// **CoreDataPlus**
  ///
  /// Called when objects matching the predicate have been deleted.
  ///
  /// - parameter observer: The `EntityObserver` posting the callback.
  /// - parameter entities: The set of updated objects.
  /// - parameter event: The entity change event type.
  func entityObserver(_ observer: EntityObserver<ManagedObject>, updated: Set<ManagedObject>, event: ObservedEvent)

  /// **CoreDataPlus**
  ///
  /// Called when objects matching the predicate have been refreshed.
  ///
  /// - parameter observer: The `EntityObserver` posting the callback.
  /// - parameter entities: The set of refreshed objects.
  /// - parameter event: The entity change event type.
  func entityObserver(_ observer: EntityObserver<ManagedObject>, refreshed: Set<ManagedObject>, event: ObservedEvent)

  /// **CoreDataPlus**
  ///
  /// Called when objects matching the predicate have been invalidated.
  ///
  /// - parameter observer: The `EntityObserver` posting the callback.
  /// - parameter entities: The set of invalidated objects.
  /// - parameter event: The entity change event type.
  func entityObserver(_ observer: EntityObserver<ManagedObject>, invalidated: Set<ManagedObject>, event: ObservedEvent)

  /// **CoreDataPlus**
  ///
  /// Called when *all* the objects in the observed context have been invalidated.
  ///
  /// - Parameters:
  ///   - observer: The `EntityObserver` posting the callback.
  ///   - allObjectsInvalidatedForEvent: The entity change event type.
  func entityObserver(_ observer: EntityObserver<ManagedObject>, allObjectsInvalidated: Set<NSManagedObjectID>, event: ObservedEvent) //TODO: update this method to returns a set of IDs
}

/// **CoreDataPlus**
///
/// `OptionSet` for delegate callbacks of `NSManagedObject` entity change events.
public struct ObservedEvent: OptionSet {
  public let rawValue: UInt

  public init(rawValue: UInt) {
    //precondition(1...3 ~= rawValue, "\(rawValue) is not a defined option.")
    self.rawValue = rawValue
  }

  /// Notifications will be sent upon `NSManagedObjectContext` being changed
  public static let onChange = ObservedEvent(rawValue: 1 << 0)

  /// Notifications will be sent upon `NSManagedObjectContext` being saved
  public static let onSave = ObservedEvent(rawValue: 1 << 1)

  /// Notifications will be sent upon `NSManagedObjectContext` being saved or changed.
  public static let all: ObservedEvent = [.onChange, .onSave]
}

public class AnyEntityObserverDelegate<T: NSManagedObject>: EntityObserverDelegate {
  fileprivate typealias EntitySet = Set<T>
  public typealias ManagedObject = T

  private let _deleted: (EntityObserver<T>, Set<T>, ObservedEvent) -> Void
  private let _inserted: (EntityObserver<T>, Set<T>, ObservedEvent) -> Void
  private let _updated: (EntityObserver<T>, Set<T>, ObservedEvent) -> Void
  private let _refreshed: (EntityObserver<T>, Set<T>, ObservedEvent) -> Void
  private let _invalidated: (EntityObserver<T>, Set<T>, ObservedEvent) -> Void
  private let _invalidatedAll: (EntityObserver<T>, Set<NSManagedObjectID>, ObservedEvent) -> Void

  public required init<D: EntityObserverDelegate>(_ delegate: D) where D.ManagedObject == T {
    _deleted = delegate.entityObserver(_:deleted:event:)
    _inserted = delegate.entityObserver(_:inserted:event:)
    _updated = delegate.entityObserver(_:updated:event:)
    _refreshed = delegate.entityObserver(_:refreshed:event:)
    _invalidated = delegate.entityObserver(_:invalidated:event:)
    _invalidatedAll = delegate.entityObserver(_:allObjectsInvalidated:event:)
  }

  public func entityObserver(_ observer: EntityObserver<T>, inserted: Set<T>, event: ObservedEvent) {
    _inserted(observer, inserted, event)
  }

  public func entityObserver(_ observer: EntityObserver<T>, deleted: Set<T>, event: ObservedEvent) {
    _deleted(observer, deleted, event)
  }

  public func entityObserver(_ observer: EntityObserver<T>, updated: Set<T>, event: ObservedEvent) {
    _updated(observer, updated, event)
  }

  public func entityObserver(_ observer: EntityObserver<ManagedObject>, refreshed: Set<ManagedObject>, event: ObservedEvent) {
    _refreshed(observer, refreshed, event)
  }

  public func entityObserver(_ observer: EntityObserver<ManagedObject>, invalidated: Set<ManagedObject>, event: ObservedEvent) {
    _invalidated(observer, invalidated, event)
  }

  public func entityObserver(_ observer: EntityObserver<T>, allObjectsInvalidated: Set<NSManagedObjectID>, event: ObservedEvent) {
    _invalidatedAll(observer, allObjectsInvalidated, event)
  }

}

public class EntityObserver<T: NSManagedObject> {

  fileprivate typealias EntitySet = Set<T>

  // MARK: - Public Properties

  public weak var delegate: AnyEntityObserverDelegate<T>? {
    willSet {
      removeObservers()
    }
    didSet {
      setupObservers()
    }
  }

  // MARK: - Public Read-Only Properties

  let context: NSManagedObjectContext

  //let entity = T.entity()

  let event: ObservedEvent

  //let filterPredicate: NSPredicate?

  // MARK: - Private Properties

  private let notificationCenter = NotificationCenter.default

  private var tokens = [NSObjectProtocol]()

  private lazy var observedEntity: NSEntityDescription = {
    // Attention: sometimes entity() returns nil due to a CoreData bug occurring in the Unit Test targets or when Generics are used.
    // return T.entity()
    guard let entity = NSEntityDescription.entity(forEntityName: T.entityName, in: context) else {
      preconditionFailure("Missing NSEntityDescription for \(T.entityName)")
    }
    return entity
  }()

  private lazy var entityPredicate: NSPredicate = {
    // Attention: sometimes entity() returns nil due to a CoreData bug occurring in the Unit Test targets or when Generics are used.
    //return NSPredicate(format: "entity == %@", entity)
    guard let entityDescription = NSEntityDescription.entity(forEntityName: T.entityName, in: context) else {
      preconditionFailure("Missing NSEntityDescription for \(T.entityName)")
    }
    return NSPredicate(format: "entity == %@", entityDescription)
  }()

//  private lazy var combinedPredicate: NSPredicate = {
//    if let filterPredicate = self.filterPredicate {
//      return NSCompoundPredicate(andPredicateWithSubpredicates: [self.entityPredicate, filterPredicate])
//    } else {
//      return self.entityPredicate
//    }
//  }()

  // MARK: - Initializers

  public init(context: NSManagedObjectContext, event: ObservedEvent) {
    self.context = context
    self.event = event
    //self.filterPredicate = predicate
  }

  deinit {
    removeObservers()
  }

  // MARK: - Private implementation

  private func removeObservers() {
    tokens.forEach { token in
      notificationCenter.removeObserver(token)
    }

    tokens.removeAll()
  }

  private func setupObservers() {

    if event.contains(.onChange) {
      let token = context.addObjectsDidChangeNotificationObserver(notificationCenter: notificationCenter) { [weak self] notification in
        guard let `self` = self else { return }
        self.handleChanges(in: notification, for: .onChange)
      }

      tokens.append(token)
    }

    if event.contains(.onSave) {
      let token = context.addContextDidSaveNotificationObserver(notificationCenter: notificationCenter) { [weak self] notification in
        guard let `self` = self else { return }
        self.handleChanges(in: notification, for: .onSave)
      }

      tokens.append(token)
    }
  }

  private func handleChanges(in notification: NSManagedObjectContextObserving, for event: ObservedEvent) {
    guard let delegate = delegate else { return }

    context.performAndWait {
      func process(_ value: Set<NSManagedObject>) -> EntitySet {
        return value.filter { $0.entity == observedEntity } as? EntitySet ?? []
      }

      let deleted = process(notification.deletedObjects)
      let inserted = process(notification.insertedObjects)
      let updated = process(notification.updatedObjects)

      if !inserted.isEmpty {
        delegate.entityObserver(self, inserted: inserted, event: event)
      }

      if !deleted.isEmpty {
        delegate.entityObserver(self, deleted: deleted, event: event)
      }

      if !updated.isEmpty {
        delegate.entityObserver(self, updated: updated, event: event)
      }

      // FIXME: is it correct having 2 kind of notifications?
      if let newNotification = notification as? NSManagedObjectContextReloadableObserving {
        let refreshed = process(newNotification.refreshedObjects)
        let invalidated = process(newNotification.invalidatedObjects)
        let invalidatedAll = newNotification.invalidatedAllObjects.filter { $0.entity == observedEntity } // TODO: add specific tests

        if !refreshed.isEmpty {
          delegate.entityObserver(self, refreshed: refreshed, event: event)
        }

        if !invalidated.isEmpty {
          delegate.entityObserver(self, updated: invalidated, event: event)
        }

        if !invalidatedAll.isEmpty {
          delegate.entityObserver(self, allObjectsInvalidated: invalidatedAll, event: event)
        }

      }

    }
  }

}
