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

import Foundation
import CoreData

// TODO: work in progress
public class ObservedManagedObject<T: NSManagedObject> {
  public let observedObject: T
  private let observedEvent: ObservedEvent
  private let handler: (ManagedObjectChange, ObservedEvent) -> Void

  private lazy var entityObserver: EntityObserver<T> = {
    guard let context = observedObject.managedObjectContext else {
      fatalError("\(observedObject) doesn't have a managedObjectContext.")
    }

    let observer = EntityObserver<T>(context: context, event: observedEvent) { [weak self] (changes, event) in
      guard let self = self else { return }
      guard !changes.isEmpty() else { return }

      let isDeleted = changes.deleted.contains(self.observedObject)
      let isInserted = changes.inserted.contains(self.observedObject)
      let isInvalidated = changes.invalidated.contains(self.observedObject) || changes.invalidatedAll.contains(self.observedObject.objectID)
      let isRefreshed = changes.refreshed.contains(self.observedObject)
      let isUpdated = changes.updated.contains(self.observedObject)

      if isDeleted {
        self.handler(.deleted, event)
      }
      if isInserted {
         self.handler(.inserted, event)
      }
      if isInvalidated {
        self.handler(.invalidated, event)
      }
      if isRefreshed {
        self.handler(.refreshed, event)
      }
      if isUpdated {
        self.handler(.updated, event)
      }
    }
    return observer
  }()

  init(object: T, event: ObservedEvent = .all, changedHandler: @escaping (ManagedObjectChange, ObservedEvent) -> Void) {
    self.observedObject = object
    self.observedEvent = event
    self.handler = changedHandler
    _ = entityObserver
  }
}

public extension ObservedManagedObject {
  enum ManagedObjectChange {
    case deleted
    case inserted
    case invalidated
    case refreshed
    case updated
  }
}
