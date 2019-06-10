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
import Foundation

// TODO: work in progress
public final class ManagedObjectObserver<T: NSManagedObject> {
  private let objectId: NSManagedObjectID
  private let context: NSManagedObjectContext
  private let queue: OperationQueue?
  private let event: ManagedObjectContextObservedEvent
  private let handler: (ManagedObjectChange, ManagedObjectContextObservedEvent) -> Void

  private lazy var observer: ManagedObjectContextChangesObserver = {
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(context),
                                                       event: event,
                                                       queue: queue,
                                                       handler: { [weak self] (changes, event, context) in
                                                        guard let self = self else { return }

                                                        dump(changes)
                                                        print(changes.isEmpty)
                                                        // the object cannot be identified if the changed are empty
                                                        guard !changes.isEmpty else {

//                                                          let o = context.performAndWait {
//                                                            return $0.object(with: self.objectId)
//                                                            
//                                                          }
//                                                          print(o)
                                                          return
                                                        }
                                                        
                                                        let isDeleted = changes.deleted.map { $0.objectID }.contains(self.objectId)
                                                        let isInserted = changes.inserted.map { $0.objectID }.contains(self.objectId)
                                                        let isInvalidated = changes.invalidated.map { $0.objectID }.contains(self.objectId) || changes.invalidatedAll.contains(self.objectId)
                                                        let isRefreshed = changes.refreshed.map { $0.objectID }.contains(self.objectId)
                                                        let isUpdated = changes.updated.map { $0.objectID }.contains(self.objectId)

                                                        // TODO: use if else to avoid handling multiple times for the same notification?
                                                         dump(changes)
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
    })
    return observer
  }()

  init(object: T,
       event: ManagedObjectContextObservedEvent,
       queue: OperationQueue? = nil,
       changedHandler: @escaping (ManagedObjectChange, ManagedObjectContextObservedEvent) -> Void) throws {
    /// If the receiver has not yet been saved, the object ID is a temporary value that will change when the object is saved.
    self.queue = queue

    // a willSave notificaiton doesn't contain any info about what is going to be saved so we can't identify the observed object
    if event.contains(.willSave) {
      throw CoreDataPlusError.fetchCountFailed() // TODO random error just to make this work while prototyping
    }

    guard let context = object.managedObjectContext else {
      throw CoreDataPlusError.fetchCountFailed() // TODO random error just to make this work while prototyping
    }

    // TODO: test it with a context without a PSC
    if object.objectID.isTemporaryID {
      do {
        try context.obtainPermanentIDs(for: [object])
        print("📍", object.objectID)
      } catch {
        throw error // TODO wrap this error
      }
    }
    self.objectId = object.objectID
    self.context = context
    self.event = event
    self.handler = changedHandler
    _ = self.observer
  }
}

public extension ManagedObjectObserver {
  /**
   static let NSManagedObjectContextObjectsDidChange: NSNotification.Name
   A notification of changes made to managed objects associated with this context.
   static let NSManagedObjectContextDidSave: NSNotification.Name
   A notification that the context completed a save.
   static let NSManagedObjectContextWillSave: NSNotification.Name
   A notification that the context is about to save.
   let NSInsertedObjectsKey: String
   A key for the set of objects that were inserted into the context.
   let NSUpdatedObjectsKey: String
   A key for the set of objects that were updated.
   let NSDeletedObjectsKey: String
   A key for the set of objects that were marked for deletion during the previous event.
   let NSRefreshedObjectsKey: String
   A key for the set of objects that were refreshed but were not dirtied in the scope of this context.
   let NSInvalidatedObjectsKey: String
   A key for the set of objects that were invalidated.
   let NSInvalidatedAllObjectsKey: String
   A key that specifies that all objects in the context have been invalidated.
   **/
  enum ManagedObjectChange {
    case deleted
    case inserted // TODO this is useless because the object should be aleready in a context
    case invalidated
    case refreshed
    case updated
  }
}

public extension NSFetchRequestResult where Self: NSManagedObject {
  // https://cocoacasts.com/three-common-core-data-mistakes-to-avoid
  /**
   The first method, object(with:), returns a managed object that corresponds to the NSManagedObjectID instance.
   If the managed object context does not have a managed object for that object identifier, it asks the persistent store coordinator. This method always returns a managed object.

   Know that object(with:) throws an exception if no managed object can be found for that object identifier.
   For example, if the application deleted the record corresponding with the object identifier, Core Data is unable to hand your application the corresponding record. The result is an exception.

   The existingObject(with:) method behaves in a similar fashion. The main difference is that the method throws an error if it cannot fetch the managed object corresponding with the object identifier.

   The third method, registeredObject(for:), only returns a managed object if the record you are asking for is already registered with the managed object context.
   In other words, the return value is of type optional NSManagedObject?. The managed object context does not fetch the corresponding record from the persistent store if it cannot find it.

   The object identifier of a record is similar, but not identical, to the primary key of a database record.
   It uniquely identifies the record and enables your application to fetch a particular record regardless of what thread the operation is performed on.
   **/

  /// Accesses `self` from another context.
  func `in`(_ context: NSManagedObjectContext) -> Self {
    // TODO
    // let _object = try! context.existingObject(with: objectID)
    guard let object = context.object(with: objectID) as? Self else {
      fatalError("Cannot find object '\(self)' in context '\(context)'.")
    }
    return object
  }
}
