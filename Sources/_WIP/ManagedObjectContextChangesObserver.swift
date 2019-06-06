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

public extension ManagedObjectContextChangesObserver {
  enum ObservedManagedObjectContext {
    case all(matching: (NSManagedObjectContext) -> Bool)
    case one(NSManagedObjectContext)

    /// The observed `NSManagedObjectContext`, nil if multiple context are observerd.
    fileprivate var managedObjectContext: NSManagedObjectContext? {
      switch self {
      case .one(context: let context): return context
      default: return nil
      }
    }
  }
}

/// **CoreDataPlus**
///
/// Observes all the changes happening on one or multiple NSManagedObjectContexts.
public final class ManagedObjectContextChangesObserver {
  public typealias Handler = (ManagedObjectContextChanges<NSManagedObject>, ManagedObjectContextObservedEvent, NSManagedObjectContext) -> Void

   // MARK: - Private properties

  private let observedManagedObjectContext: ObservedManagedObjectContext
  private let event: ManagedObjectContextObservedEvent
  private let queue: OperationQueue?
  private let notificationCenter: NotificationCenter
  private let handler: Handler
  private var tokens = [NSObjectProtocol]()

  // MARK: - Initializers

  public init(observedManagedObjectContext: ObservedManagedObjectContext,
              event: ManagedObjectContextObservedEvent,
              notificationCenter: NotificationCenter = .default,
              queue: OperationQueue? = nil,
              handler: @escaping Handler) {
    self.observedManagedObjectContext = observedManagedObjectContext
    self.event = event
    self.queue = queue
    self.notificationCenter = notificationCenter
    self.handler = handler
    setup()
  }

  deinit {
    removeObservers()
  }

  // MARK: - Private Implementation

  /// Removes all the observers.
  private func removeObservers() {
    tokens.forEach { token in
      notificationCenter.removeObserver(token)
    }
    tokens.removeAll()
  }

  /// Add the observers for the event.
  private func setup() {
    if event.contains(.didChange) {
      let token = notificationCenter.addObserver(forName: .NSManagedObjectContextObjectsDidChange,
                                                 object: observedManagedObjectContext.managedObjectContext,
                                                 queue: queue) { [weak self] notification in
        guard let self = self else { return }

        let didChangeNotification = ManagedObjectContextObjectsDidChangeNotification(notification: notification)
        if let changes = self.processChanges(in: didChangeNotification) {
          self.handler(changes, .didChange, didChangeNotification.managedObjectContext)
        }
      }
      tokens.append(token)
    }

    if event.contains(.willSave) {
      let token = notificationCenter.addObserver(forName: .NSManagedObjectContextWillSave,
                                                 object: observedManagedObjectContext.managedObjectContext,
                                                 queue: queue) { [weak self] notification in
        guard let self = self else { return }

        let willSaveNotification = ManagedObjectContextWillSaveNotification(notification: notification)
        if let changes = self.processChanges(in: willSaveNotification) {
          self.handler(changes, .willSave, willSaveNotification.managedObjectContext)
        }
      }
      tokens.append(token)
    }

    if event.contains(.didSave) {
      let token = notificationCenter.addObserver(forName: .NSManagedObjectContextDidSave, object: observedManagedObjectContext.managedObjectContext, queue: queue) { [weak self] notification in
        guard let self = self else { return }

        let didSaveNotification = ManagedObjectContextDidSaveNotification(notification: notification)
        if let changes = self.processChanges(in: didSaveNotification) {
          self.handler(changes, .didSave, didSaveNotification.managedObjectContext)
        }
      }
      tokens.append(token)
    }
  }

  /// Processes incoming notifications.
  private func processChanges(in notification: ManagedObjectContextObservable) -> ManagedObjectContextChanges<NSManagedObject>? {
    func validateContext(_ context: NSManagedObjectContext) -> Bool {
      switch observedManagedObjectContext {
      case .one(context: let context): return context === notification.managedObjectContext
      case .all(matching: let filter): return filter(notification.managedObjectContext)
      }
    }

    guard validateContext(notification.managedObjectContext) else { return nil }

    let deleted = notification.deletedObjects
    let inserted = notification.insertedObjects
    let updated = notification.updatedObjects
    let refreshed = notification.refreshedObjects
    let invalidated = notification.invalidatedObjects
    let invalidatedAll = notification.invalidatedAllObjects
    let changes = ManagedObjectContextChanges(inserted: inserted,
                                              updated: updated,
                                              deleted: deleted,
                                              refreshed: refreshed,
                                              invalidated: invalidated,
                                              invalidatedAll: invalidatedAll)
    return changes.isEmpty() ? nil : changes
  }
}
