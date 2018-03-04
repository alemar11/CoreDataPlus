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

final public class ManagedObjectStatusObserver {

  enum ObservedStatusChange: Int {
    case inserted = 1
    case deleted
    case updated
    case refreshed
    case invalidated
  }

  let observedObject: NSManagedObject
  let event: ObservedEvent

  private var tokens = [NSObjectProtocol]()
  private let notificationCenter: NotificationCenter


  private let handler: (ObservedStatusChange, ObservedEvent) -> Void

  init?(object: NSManagedObject, event: ObservedEvent, notificationCenter: NotificationCenter = .default, changeHandler: @escaping (ObservedStatusChange, ObservedEvent) -> Void) {
    guard let _ = object.managedObjectContext else { return nil }

    self.event = event
    self.notificationCenter = notificationCenter
    self.observedObject = object
    self.handler = changeHandler

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
    guard let context = observedObject.managedObjectContext else { return }
    
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
    guard let context = observedObject.managedObjectContext else { return }

    context.performAndWait {

      let deleted = notification.deletedObjects.filter {$0 === observedObject}
      let inserted = notification.insertedObjects.filter {$0 === observedObject}
      let updated = notification.updatedObjects.filter {$0 === observedObject}

      if !inserted.isEmpty { //TODO: count == 1
        handler(.inserted, event)
      }

      if !deleted.isEmpty {
        handler(.deleted, event)
      }

      if !updated.isEmpty {
        handler(.updated, event)
      }

      // FIXME: is it correct having 2 kind of notifications?
      //if let notification = notification as? NSManagedObjectContextReloadableObserving {
        let refreshed = notification.refreshedObjects.filter {$0 === observedObject}
        let invalidated = notification.invalidatedObjects.filter {$0 === observedObject}
        let invalidatedAll = notification.invalidatedAllObjects.filter { $0.entity == observedObject.entity }

        if !refreshed.isEmpty {
          if !updated.isEmpty {
            handler(.refreshed, event)
          }
        }

        if !invalidated.isEmpty {
            handler(.invalidated, event)
        }

        if !invalidatedAll.isEmpty {
          handler(.invalidated, event)
        }

      //}
    }

  }
}
