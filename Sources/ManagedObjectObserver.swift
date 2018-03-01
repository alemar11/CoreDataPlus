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

final public class ManagedObjectObserver {
  public typealias ManagedObject = NSManagedObject

  enum ObservedChange {
    case delete
    case update
  }

  let observedObject: NSManagedObject

  private let handler: (ObservedChange, ObservedEvent) -> Void
  private let entityObserver: EntityObserver<ManagedObject>

  init?(object: ManagedObject, event: ObservedEvent, changeHandler: @escaping (ObservedChange, ObservedEvent) -> Void) {
    guard let context = object.managedObjectContext else { return nil }

    observedObject = object
    handler = changeHandler
    entityObserver = EntityObserver(context: context, event: event)
    entityObserver.delegate = AnyEntityObserverDelegate(self)
  }

  deinit {
    entityObserver.delegate = nil
  }

}

// MARK: - EntityObserverDelegate

extension ManagedObjectObserver: EntityObserverDelegate {

  public func entityObserver(_ observer: EntityObserver<NSManagedObject>, inserted: Set<NSManagedObject>, event: ObservedEvent) {
    preconditionFailure("It's impossible to observe an object that is not yet inserted in a context.")
  }

  public func entityObserver(_ observer: EntityObserver<NSManagedObject>, updated: Set<NSManagedObject>, event: ObservedEvent) {
    if updated.contains(where: { $0 === observedObject }) {
      handler(.update, event)
    }
  }

  public func entityObserver(_ observer: EntityObserver<NSManagedObject>, refreshed: Set<NSManagedObject>, event: ObservedEvent) {
    if refreshed.contains(where: { $0 === observedObject }) {
      handler(.update, event)
    }
  }

  public func entityObserver(_ observer: EntityObserver<NSManagedObject>, deleted: Set<NSManagedObject>, event: ObservedEvent) {
    if deleted.contains(where: { $0 === observedObject }) {
      handler(.delete, event)
    }
  }

  public func entityObserver(_ observer: EntityObserver<NSManagedObject>, invalidated: Set<NSManagedObject>, event: ObservedEvent) {
    if invalidated.contains(where: { $0 === observedObject }) {
      handler(.delete, event)
    }
  }

  public func entityObserver(_ observer: EntityObserver<NSManagedObject>, invalidatedAll: Set<NSManagedObjectID>, event: ObservedEvent) {
    if invalidatedAll.contains(where: {$0 == observedObject.objectID}) {
      handler(.delete, event)
    }
  }
}
