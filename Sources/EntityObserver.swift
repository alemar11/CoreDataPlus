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

  /// **CoreDataPlus**
  ///
  /// Called when objects matching the predicate have been inserted.
  ///
  /// - parameter observer: The `EntityObserver` posting the callback.
  /// - parameter entities: The set of inserted objects.
  /// - parameter event: The entity change event type.
  func entityObserver(_ observer: EntityObserver<ManagedObject>, inserted: Set<ManagedObject>, event: ObserverFrequency)

  /// **CoreDataPlus**
  ///
  /// Called when objects matching the predicate have been deleted.
  ///
  /// - parameter observer: The `EntityObserver` posting the callback.
  /// - parameter entities: The set of deleted objects.
  /// - parameter event: The entity change event type.
  func entityObserver(_ observer: EntityObserver<ManagedObject>, deleted: Set<ManagedObject>, event: ObserverFrequency)

  /// **CoreDataPlus**
  ///
  /// Called when objects matching the predicate have been deleted.
  ///
  /// - parameter observer: The `EntityObserver` posting the callback.
  /// - parameter entities: The set of updated objects.
  /// - parameter event: The entity change event type.
  func entityObserver(_ observer: EntityObserver<ManagedObject>, updated: Set<ManagedObject>, event: ObserverFrequency)

  /// **CoreDataPlus**
  ///
  /// Called when objects matching the predicate have been refreshed.
  ///
  /// - parameter observer: The `EntityObserver` posting the callback.
  /// - parameter entities: The set of refreshed objects.
  /// - parameter event: The entity change event type.
  func entityObserver(_ observer: EntityObserver<ManagedObject>, refreshed: Set<ManagedObject>, event: ObserverFrequency)

  /// **CoreDataPlus**
  ///
  /// Called when objects matching the predicate have been invalidated.
  ///
  /// - parameter observer: The `EntityObserver` posting the callback.
  /// - parameter entities: The set of invalidated objects.
  /// - parameter event: The entity change event type.
  func entityObserver(_ observer: EntityObserver<ManagedObject>, invalidated: Set<ManagedObject>, event: ObserverFrequency)
}

/// **CoreDataPlus**
///
/// `OptionSet` for delegate callbacks of `NSManagedObject` entity change events.
public struct ObserverFrequency: OptionSet {
  public let rawValue: UInt

  public init(rawValue: UInt) {
    //precondition(1...3 ~= rawValue, "\(rawValue) is not a defined option.")
    self.rawValue = rawValue
  }

  /// Notifications will be sent upon `NSManagedObjectContext` being changed
  public static let onChange = ObserverFrequency(rawValue: 1 << 0)

  /// Notifications will be sent upon `NSManagedObjectContext` being saved
  public static let onSave = ObserverFrequency(rawValue: 1 << 1)

  /// Notifications will be sent upon `NSManagedObjectContext` being saved or changed.
  public static let all: ObserverFrequency = [.onChange, .onSave]
}

public class AnyEntityObserverDelegate<T: NSManagedObject>: EntityObserverDelegate {
  fileprivate typealias EntitySet = Set<T>
  public typealias ManagedObject = T

  private let _deleted: (EntityObserver<T>, Set<T>, ObserverFrequency) -> Void
  private let _inserted: (EntityObserver<T>, Set<T>, ObserverFrequency) -> Void
  private let _updated: (EntityObserver<T>, Set<T>, ObserverFrequency) -> Void
  private let _refreshed: (EntityObserver<T>, Set<T>, ObserverFrequency) -> Void
  private let _invalidated: (EntityObserver<T>, Set<T>, ObserverFrequency) -> Void

  public required init<D: EntityObserverDelegate>(_ delegate: D) where D.ManagedObject == T {
    _deleted = delegate.entityObserver(_:deleted:event:)
    _inserted = delegate.entityObserver(_:inserted:event:)
    _updated = delegate.entityObserver(_:updated:event:)
    _refreshed = delegate.entityObserver(_:refreshed:event:)
    _invalidated = delegate.entityObserver(_:invalidated:event:)
  }

  public func entityObserver(_ observer: EntityObserver<T>, inserted: Set<T>, event: ObserverFrequency) {
    _inserted(observer, inserted, event)
  }

  public func entityObserver(_ observer: EntityObserver<T>, deleted: Set<T>, event: ObserverFrequency) {
    _deleted(observer, deleted, event)
  }

  public func entityObserver(_ observer: EntityObserver<T>, updated: Set<T>, event: ObserverFrequency) {
    _updated(observer, updated, event)
  }

  public func entityObserver(_ observer: EntityObserver<ManagedObject>, refreshed: Set<ManagedObject>, event: ObserverFrequency) {
    _refreshed(observer, refreshed, event)
}

  public func entityObserver(_ observer: EntityObserver<ManagedObject>, invalidated: Set<ManagedObject>, event: ObserverFrequency) {
    _invalidated(observer, invalidated, event)
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

  let entity = T.entity()

  let frequency: ObserverFrequency

  let filterPredicate: NSPredicate?

  // MARK: - Private Properties

  private let notificationCenter = NotificationCenter.default

  private var tokens = [NSObjectProtocol]()

  private lazy var entityPredicate: NSPredicate = { return NSPredicate(format: "entity == %@", entity) }()

  private lazy var combinedPredicate: NSPredicate = {
    if let filterPredicate = self.filterPredicate {
      return NSCompoundPredicate(andPredicateWithSubpredicates: [self.entityPredicate, filterPredicate])
    } else {
      return self.entityPredicate
    }
  }()

  // MARK: - Initializers

  public init(context: NSManagedObjectContext, frequency: ObserverFrequency, filterBy predicate: NSPredicate? = nil) {
    self.context = context
    self.frequency = frequency
    self.filterPredicate = predicate

    guard let entityClass = NSClassFromString(entity.managedObjectClassName) else {
      preconditionFailure("The entity Description is missing a class name or does not represent a class")
    }
    precondition(entityClass == T.self, "The Class generic type must match the entity descripton type.")
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

    if frequency.contains(.onChange) {
      let token = context.addObjectsDidChangeNotificationObserver(notificationCenter: notificationCenter) { [weak self] notification in
        guard let `self` = self else { return }
        self.handleChanges(in: notification, for: .onChange)
      }

      tokens.append(token)
    }

    if frequency.contains(.onSave) {
      let token = context.addContextDidSaveNotificationObserver(notificationCenter: notificationCenter) { [weak self] notification in
        guard let `self` = self else { return }
        self.handleChanges(in: notification, for: .onSave)
      }

      tokens.append(token)
    }
  }

  private func handleChanges(in notification: NSManagedObjectContextObserving, for event: ObserverFrequency) {
    guard let delegate = delegate else { return }

    context.performAndWait {
      func process(_ value: Set<NSManagedObject>) -> EntitySet {
        return (value as NSSet).filtered(using: combinedPredicate) as? EntitySet ?? []
      }

      let deleted = process(notification.deletedObjects)
      let inserted = process(notification.insertedObjects)
      let updated = process(notification.updatedObjects)
      let invalidated = process(notification.invalidatedObjects)
      let invalidatedAll = notification.invalidatedAllObjects

      if !inserted.isEmpty {
        delegate.entityObserver(self, inserted: inserted, event: event)
      }

      if !deleted.isEmpty {
        delegate.entityObserver(self, deleted: deleted, event: event)
      }

      if !updated.isEmpty {
        delegate.entityObserver(self, updated: updated, event: event)
      }

      if !invalidated.isEmpty {
        delegate.entityObserver(self, updated: invalidated, event: event)
      }

      if invalidatedAll {

      }

    }
  }

}
