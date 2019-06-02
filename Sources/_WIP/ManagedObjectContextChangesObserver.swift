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

public final class ManagedObjectContextChangesObserver {
  public typealias Handler = (EntityObserver<NSManagedObject>.ManagedObjectContextChange<NSManagedObject>, ObservedEvent, NSManagedObjectContext) -> Void
  public enum Kind {
    case allContexts
    case specific(context: NSManagedObjectContext)

    var context: NSManagedObjectContext? {
      switch self {
      case .allContexts: return nil
      case .specific(context: let context): return context
      }
    }
  }

  let kind: Kind
  let event: ObservedEvent
  let queue: OperationQueue?
  let notificationCenter: NotificationCenter
  private let handler: (EntityObserver<NSManagedObject>.ManagedObjectContextChange<NSManagedObject>, ObservedEvent, NSManagedObjectContext) -> Void
  private var tokens = [NSObjectProtocol]()

  public init(kind: Kind, event: ObservedEvent, queue: OperationQueue? = nil, notificationCenter: NotificationCenter = .default, handler: @escaping Handler) {
    self.kind = kind
    self.event = event
    self.queue = queue
    self.notificationCenter = notificationCenter
    self.handler = handler
    setup()
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
  private func setup() {
    if event.contains(.change) {
      let token = notificationCenter.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: kind.context, queue: queue) { [weak self] notification in
        let changeNotification = ManagedObjectContextObjectsDidChangeNotification(notification: notification)
        // this should fix: Exception was caught during Core Data change processing.  This is usually a bug within an observer of NSManagedObjectContextObjectsDidChangeNotification.
        changeNotification.managedObjectContext.performAndWait {
          self?.processChanges(in: changeNotification, for: .change)
        }
      }
      tokens.append(token)
    }

    if event.contains(.save) {
      let token = notificationCenter.addObserver(forName: .NSManagedObjectContextDidSave, object: kind.context, queue: queue) { [weak self] notification in
        let saveNotification = ManagedObjectContextDidSaveNotification(notification: notification)
        //self?.processChanges(in: saveNotification, for: .save)
        saveNotification.managedObjectContext.performAndWait {
          self?.processChanges(in: saveNotification, for: .save)
        }
      }
      tokens.append(token)
    }
  }

  /// Processes the incoming notification.
  private func processChanges(in notification: ManagedObjectContextObservable, for event: ObservedEvent) {
    let deleted = notification.deletedObjects
    let inserted = notification.insertedObjects
    let updated = notification.updatedObjects
    let refreshed = notification.refreshedObjects
    let invalidated = notification.invalidatedObjects
    let invalidatedAll = notification.invalidatedAllObjects
    let change = EntityObserver.ManagedObjectContextChange(inserted: inserted,
                                                           updated: updated,
                                                           deleted: deleted,
                                                           refreshed: refreshed,
                                                           invalidated: invalidated,
                                                           invalidatedAll: invalidatedAll)
    if !change.isEmpty() {
      handler(change, event, notification.managedObjectContext)
    }
  }
}
