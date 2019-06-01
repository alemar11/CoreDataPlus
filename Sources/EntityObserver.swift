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

/// **CoreDataPlus**
///
/// An object that observes all the changes happening in a `NSManagedObjectContext` for a specific entity.
public class EntityObserver<T: NSManagedObject> {
  fileprivate typealias EntitySet = Set<T>

  /// **CoreDataPlus**
  ///
  /// Contains all the changes taking place in a `NSManagedObjectContext` for each notification.
  public struct ManagedObjectContextChange<T: NSManagedObject> {
    /// **CoreDataPlus**
    ///
    /// Returns a `Set` of objects that were inserted into the context.
    public let inserted: Set<T>

    /// **CoreDataPlus**
    ///
    /// Returns a `Set` of objects that were updated into the context.
    public let updated: Set<T>

    /// **CoreDataPlus**
    ///
    /// Returns a `Set` of objects that were deleted into the context.
    public let deleted: Set<T>

    /// **CoreDataPlus**
    ///
    /// Returns a `Set` of objects that were refreshed into the context.
    public let refreshed: Set<T>

    /// **CoreDataPlus**
    ///
    /// Returns a `Set` of objects that were invalidated into the context.
    public let invalidated: Set<T>

    /// **CoreDataPlus**
    ///
    /// When all the object in the context have been invalidated, returns a `Set` containing all the invalidated objects' NSManagedObjectID.
    public let invalidatedAll: Set<NSManagedObjectID>

    /// **CoreDataPlus**
    ///
    /// Returns `true` if there aren't any kind of changes.
    public func isEmpty() -> Bool {
      return inserted.isEmpty && !updated.isEmpty && !deleted.isEmpty && !refreshed.isEmpty && !invalidated.isEmpty && !invalidatedAll.isEmpty
    }
  }

  /// **CoreDataPlus**
  ///
  /// The observed event.
  public let event: ObservedEvent

  /// **CoreDataPlus**
  ///
  /// If `true`, all the changes happening in the subentities will be observed.
  public let observeSubEntities: Bool

  /// **CoreDataPlus**
  ///
  /// The observed entity.
  public lazy var observedEntity: NSEntityDescription = {
    // Attention: sometimes entity() returns nil due to a CoreData bug occurring in the Unit Test targets or when Generics are used.
    // return T.entity()
    guard let entity = NSEntityDescription.entity(forEntityName: T.entityName, in: context) else {
      preconditionFailure("Missing NSEntityDescription for \(T.entityName)")
    }
    return entity
  }()

  // MARK: - Private properties

  private let context: NSManagedObjectContext
  private let notificationCenter: NotificationCenter
  private let handler: (ManagedObjectContextChange<T>, ObservedEvent) -> Void
  private var tokens = [NSObjectProtocol]()

  // MARK: - Initializers

  /// **CoreDataPlus**
  ///
  /// Initializes a new `EntityObserver` object.
  ///
  /// - Parameters:
  ///   - context: The NSManagedContext where the changes are observed.
  ///   - event: The kind of event observed.
  ///   - observeSubEntities: If `true`, all the changes happening in the subentities will be observed. (default: `false`)
  ///   - notificationCenter: The `NotificationCenter` listening the the `NSManagedObjectContext` notifications.
  ///   - changedHandler: The completion handler.
  init(context: NSManagedObjectContext, event: ObservedEvent,
       observeSubEntities: Bool = false,
       notificationCenter: NotificationCenter = .default,
       changedHandler: @escaping (ManagedObjectContextChange<T>, ObservedEvent) -> Void) {
    self.context = context
    self.event = event
    self.observeSubEntities = observeSubEntities
    self.notificationCenter = notificationCenter
    self.handler = changedHandler

    setupObservers()
  }

  deinit {
    removeObservers()
  }

  // MARK: - Private implementation

  /// Removes all the observers.
  private func removeObservers() {
    tokens.forEach { token in
      notificationCenter.removeObserver(token)
    }

    tokens.removeAll()
  }

  /// Add the observers for the event.
  private func setupObservers() {
    if event.contains(.change) {
      let token = context.addManagedObjectContextObjectsDidChangeNotificationObserver(notificationCenter: notificationCenter) { [weak self] notification in
        guard let self = self else { return }

        self.handleChanges(in: notification, for: .change)
      }

      tokens.append(token)
    }

    if event.contains(.save) {
      let token = context.addManagedObjectContextDidSaveNotificationObserver(notificationCenter: notificationCenter) { [weak self] notification in
        guard let self = self else { return }

        self.handleChanges(in: notification, for: .save)
      }

      tokens.append(token)
    }
  }

  /// Processes the incoming notification.
  private func handleChanges(in notification: ManagedObjectContextObservable, for event: ObservedEvent) {
    context.performAndWait {
      func process(_ value: Set<NSManagedObject>) -> EntitySet {
        if observeSubEntities {
          return value.filter { $0.entity.topMostEntity == observedEntity } as? EntitySet ?? []
        } else {
          return value.filter { $0.entity == observedEntity } as? EntitySet ?? []
        }
      }

      let deleted = process(notification.deletedObjects)
      let inserted = process(notification.insertedObjects)
      let updated = process(notification.updatedObjects)
      let refreshed = process(notification.refreshedObjects)
      let invalidated = process(notification.invalidatedObjects)
      let invalidatedAll = notification.invalidatedAllObjects.filter { $0.entity == observedEntity }
      let change = ManagedObjectContextChange(inserted: inserted,
                                              updated: updated,
                                              deleted: deleted,
                                              refreshed: refreshed,
                                              invalidated: invalidated,
                                              invalidatedAll: invalidatedAll)

      if !change.isEmpty() {
        handler(change, event)
      }
    }
  }
}
