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
public class ManagedObjectObserver<T: NSManagedObject> {
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

public extension ManagedObjectObserver {
  enum ManagedObjectChange {
    case deleted
    case inserted
    case invalidated
    case refreshed
    case updated
  }
}

public extension NSFetchRequestResult where Self: NSManagedObject {
  // https://cocoacasts.com/three-common-core-data-mistakes-to-avoid
  /**
   The first method, object(with:), returns a managed object that corresponds to the NSManagedObjectID instance. If the managed object context does not have a managed object for that object identifier, it asks the persistent store coordinator. This method always returns a managed object.

   Know that object(with:) throws an exception if no managed object can be found for that object identifier. For example, if the application deleted the record corresponding with the object identifier, Core Data is unable to hand your application the corresponding record. The result is an exception.

   The existingObject(with:) method behaves in a similar fashion. The main difference is that the method throws an error if it cannot fetch the managed object corresponding with the object identifier.

   The third method, registeredObject(for:), only returns a managed object if the record you are asking for is already registered with the managed object context. In other words, the return value is of type optional NSManagedObject?. The managed object context does not fetch the corresponding record from the persistent store if it cannot find it.

   The object identifier of a record is similar, but not identical, to the primary key of a database record. It uniquely identifies the record and enables your application to fetch a particular record regardless of what thread the operation is performed on.
  **/


  /// Accesses `self` in another context.
  func `in`(_ context: NSManagedObjectContext) -> Self {
    let _object = try! context.existingObject(with: objectID)
    guard let object = context.object(with: objectID) as? Self else {
      fatalError("Cannot find object '\(self)' in context '\(context)'.")
    }
    return object
  }
}
