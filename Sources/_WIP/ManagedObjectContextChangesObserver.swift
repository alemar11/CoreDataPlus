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
  enum Kind {
    case all(matching: (NSManagedObjectContext) -> Bool)
    case one(context: NSManagedObjectContext)
    
    /// The observed `NSManagedObjectContext`, nil if multiple context are observerd.
    fileprivate var observedManagedObjectContext: NSManagedObjectContext? {
      switch self {
      case .one(context: let context): return context
      default: return nil
      }
    }
  }
}

public final class ManagedObjectContextChangesObserver {
  public typealias Handler = (ManagedObjectContextChanges<NSManagedObject>, ObservedManagedObjectContextEvent, NSManagedObjectContext) -> Void
  
  let kind: Kind
  let event: ObservedManagedObjectContextEvent
  let queue: OperationQueue?
  let notificationCenter: NotificationCenter
  private let handler: Handler
  private var tokens = [NSObjectProtocol]()
  
  // MARK: - Initializers
  
  public init(kind: Kind, event: ObservedManagedObjectContextEvent, notificationCenter: NotificationCenter = .default, notificationQueue: OperationQueue? = nil, handler: @escaping Handler) {
    self.kind = kind
    self.event = event
    self.queue = notificationQueue
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
    if event.contains(.change) {
      let token = notificationCenter.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: kind.observedManagedObjectContext, queue: queue) { [weak self] notification in
        guard let self = self else { return }
        
        let changeNotification = ManagedObjectContextObjectsDidChangeNotification(notification: notification)
        if let changes = self.processChanges(in: changeNotification) {
          self.handler(changes, .change, changeNotification.managedObjectContext)
        }
      }
      tokens.append(token)
    }
    
    if event.contains(.save) {
      let token = notificationCenter.addObserver(forName: .NSManagedObjectContextDidSave, object: kind.observedManagedObjectContext, queue: queue) { [weak self] notification in
        guard let self = self else { return }
        
        let saveNotification = ManagedObjectContextDidSaveNotification(notification: notification)
        if let changes = self.processChanges(in: saveNotification) {
          self.handler(changes, .save, saveNotification.managedObjectContext)
        }
      }
      tokens.append(token)
    }
  }
  
  /// Processes incoming notifications.
  private func processChanges(in notification: ManagedObjectContextObservable) -> ManagedObjectContextChanges<NSManagedObject>? {
    func validateContext(_ context: NSManagedObjectContext) -> Bool {
      switch kind {
      case .one(context: let context): return context === notification.managedObjectContext
      case .all(matching: let filter): return filter(notification.managedObjectContext)
      }
    }
    
    guard validateContext(notification.managedObjectContext) else { return nil }
    
    let changes = notification.managedObjectContext.performAndWait { _ -> ManagedObjectContextChanges<NSManagedObject> in
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
      return changes
    }
    return changes.isEmpty() ? nil : changes
  }
}
