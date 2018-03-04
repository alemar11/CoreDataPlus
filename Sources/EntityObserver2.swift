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

class EntityObserver2<T: NSManagedObject> {

  struct ObservedChange<T: NSManagedObject> {
    let inserted: Set<T>
    let updated: Set<T>
    let deleted: Set<T>
    let refreshed: Set<T>
    let invalidated: Set<T>
    let invalidatedAll: Set<NSManagedObjectID>

    func hasChanges() -> Bool {
      return !inserted.isEmpty || !updated.isEmpty || !deleted.isEmpty || !refreshed.isEmpty || !invalidated.isEmpty || !invalidatedAll.isEmpty
    }
  }

  let event: ObservedEvent
  private let context: NSManagedObjectContext
  private let notificationCenter: NotificationCenter
  private let handler: (ObservedChange<T>, ObservedEvent) -> Void

  private var tokens = [NSObjectProtocol]()

fileprivate typealias EntitySet = Set<T>

  lazy var observedEntity: NSEntityDescription = {
    // Attention: sometimes entity() returns nil due to a CoreData bug occurring in the Unit Test targets or when Generics are used.
    // return T.entity()
    guard let entity = NSEntityDescription.entity(forEntityName: T.entityName, in: context) else {
      preconditionFailure("Missing NSEntityDescription for \(T.entityName)")
    }
    return entity
  }()

  init(context: NSManagedObjectContext, event: ObservedEvent, notificationCenter: NotificationCenter = .default, changedHandler: @escaping (ObservedChange<T>, ObservedEvent) -> Void) {
    self.context = context
    self.event = event
    self.notificationCenter = notificationCenter
    self.handler = changedHandler

    setupObservers()
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
    context.performAndWait {
      
      func process(_ value: Set<NSManagedObject>) -> EntitySet {
        return value.filter { $0.entity == observedEntity } as? EntitySet ?? []
      }

      let deleted = process(notification.deletedObjects)
      let inserted = process(notification.insertedObjects)
      let updated = process(notification.updatedObjects)

      // FIXME: is it correct having 2 kind of notifications?
      //if let notification = notification as? NSManagedObjectContextReloadableObserving {
        let refreshed = process(notification.refreshedObjects)
        let invalidated = process(notification.invalidatedObjects)
        let invalidatedAll = notification.invalidatedAllObjects.filter { $0.entity == observedEntity } // TODO: add specific tests

        let change = ObservedChange(inserted: inserted, updated: updated, deleted: deleted, refreshed: refreshed, invalidated: invalidated, invalidatedAll: invalidatedAll)

        if change.hasChanges() {
        handler(change, event)
        }
      //}

    }
  }

}

