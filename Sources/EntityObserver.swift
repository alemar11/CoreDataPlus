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
  func entityObserver(_ observer: EntityObserver<ManagedObject>, inserted: Set<ManagedObject>)

  /// **CoreDataPlus**
  ///
  /// Called when objects matching the predicate have been deleted.
  ///
  /// - parameter observer: The `EntityObserver` posting the callback.
  /// - parameter entities: The set of deleted objects.
  func entityObserver(_ observer: EntityObserver<ManagedObject>, deleted: Set<ManagedObject>)

  /// **CoreDataPlus**
  ///
  /// Called when objects matching the predicate have been deleted.
  ///
  /// - parameter observer: The `EntityObserver` posting the callback.
  /// - parameter entities: The set of updated objects.
  func entityObserver(_ observer: EntityObserver<ManagedObject>, updated: Set<ManagedObject>)

  /// **CoreDataPlus**
  ///
  /// Called when objects matching the predicate have been refreshed.
  ///
  /// - parameter observer: The `EntityObserver` posting the callback.
  /// - parameter entities: The set of refreshed objects.
  func entityObserver(_ observer: EntityObserver<ManagedObject>, refreshed: Set<ManagedObject>)

  /// **CoreDataPlus**
  ///
  /// Called when objects matching the predicate have been invalidated.
  ///
  /// - parameter observer: The `EntityObserver` posting the callback.
  /// - parameter entities: The set of invalidated objects.
  func entityObserver(_ observer: EntityObserver<ManagedObject>, invalidated: Set<ManagedObject>)
}

/// **CoreDataPlus**
///
/// `OptionSet` for delegate callbacks of `NSManagedObject` entity change events.
public struct ObserverFrequency: OptionSet {
  public let rawValue: UInt

  public init(rawValue: UInt) {
    precondition(1...2 ~= rawValue, "\(rawValue) is not a defined option.")
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

  private let _deleted: (EntityObserver<T>, Set<T>) -> Void
  private let _inserted: (EntityObserver<T>, Set<T>) -> Void
  private let _updated: (EntityObserver<T>, Set<T>) -> Void
  private let _refreshed: (EntityObserver<T>, Set<T>) -> Void
  private let _invalidated: (EntityObserver<T>, Set<T>) -> Void

  public required init<D: EntityObserverDelegate>(_ delegate: D) where D.ManagedObject == T {
    _deleted = delegate.entityObserver(_:deleted:)
    _inserted = delegate.entityObserver(_:inserted:)
    _updated = delegate.entityObserver(_:updated:)
    _refreshed = delegate.entityObserver(_:refreshed:)
    _invalidated = delegate.entityObserver(_:invalidated:)
  }

  public func entityObserver(_ observer: EntityObserver<T>, inserted: Set<T>) {
    _deleted(observer, inserted)
  }

  public func entityObserver(_ observer: EntityObserver<T>, deleted: Set<T>) {
    _deleted(observer, deleted)
  }

  public func entityObserver(_ observer: EntityObserver<T>, updated: Set<T>) {
    _updated(observer, updated)
  }

  public func entityObserver(_ observer: EntityObserver<ManagedObject>, refreshed: Set<ManagedObject>) {
    _refreshed(observer, refreshed)
}

  public func entityObserver(_ observer: EntityObserver<ManagedObject>, invalidated: Set<ManagedObject>) {
    _invalidated(observer, invalidated)
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

  private(set) let context: NSManagedObjectContext

  private(set) let entity: NSEntityDescription

  private(set) let frequency: ObserverFrequency

  private(set) let filterPredicate: NSPredicate?

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

  public init(context: NSManagedObjectContext, entity: NSEntityDescription, frequency: ObserverFrequency, filterBy predicate: NSPredicate? = nil) {
    self.context = context
    self.entity = entity
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
        self.handleChanges(in: notification)
      }

      tokens.append(token)
    }

    if frequency.contains(.onSave) {
      let token = context.addContextDidSaveNotificationObserver(notificationCenter: notificationCenter) { [weak self] notification in
        guard let `self` = self else { return }
        self.handleChanges(in: notification)
      }

      tokens.append(token)
    }
  }

  private func handleChanges(in notification: NSManagedObjectContextObserving) {
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
        delegate.entityObserver(self, inserted: inserted)
      }

      if !deleted.isEmpty {
        delegate.entityObserver(self, deleted: deleted)
      }

      if !updated.isEmpty {
        delegate.entityObserver(self, updated: updated)
      }

      if !invalidated.isEmpty {
        delegate.entityObserver(self, updated: invalidated)
      }

      if invalidatedAll {

      }

    }
  }

}
