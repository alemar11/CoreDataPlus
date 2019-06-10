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

open class SingleFetchedResultController<T: NSManagedObject> {
  public typealias OnChange = ((ChangeType) -> Void)

  public enum ChangeType {
    case insert(object: T)
    case update(object: T)
    case delete(object: T)
  }

  public let request: NSFetchRequest<T>
  public let managedObjectContext: NSManagedObjectContext
  public let handler: OnChange
  public fileprivate(set) var fetchedObject: T? = nil

  private lazy var observer: ManagedObjectContextChangesObserver = {
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(managedObjectContext),
                                                       event: .didSave) { [weak self] (changes, _, _) in
                                                        guard let self = self else { return }
                                                        self.handleChanges(changes)
    }
    return observer
  }()

  public init(request: NSFetchRequest<T>, managedObjectContext: NSManagedObjectContext, onChange: @escaping OnChange) {
    // TODO
//    if request.predicate == nil {
//      let exception = NSException(name: .invalidArgumentException, reason: "An instance of SingleFetchedResultController requires a fetch request with sort descriptors", userInfo: nil)
//      exception.raise()
//    }

    //assert(request.predicate != nil, "An instance of SingleFetchedResultController requires a fetch request with sort descriptors")

    self.request = request
    self.managedObjectContext = managedObjectContext
    self.handler = onChange
    _ = observer
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  open func performFetch() throws {
    let results = try managedObjectContext.fetch(request)

    if results.count > 1 {
      throw CoreDataPlusError.fetchExpectingOnlyOneObjectFailed()
    }

    if let result = results.first {
      fetchedObject = result
    }
  }

  private func handleChanges(_ changes: ManagedObjectContextChanges<NSManagedObject>) {
    func process(_ value: Set<NSManagedObject>) -> T? {
      if let predicate = request.predicate {
        guard let evaluated = value.filter(predicate.evaluate(with:)) as? Set<T> else { return nil }
        assert(evaluated.count < 2)
        return evaluated.first
      } else {
        // TODO
        assert(value.count < 2)
        return value.first as? T
      }
    }

    let predicate = request.predicate! // TODO

    // validate the current fetched object if any
    if let fetched = fetchedObject {
      let set = Set<T>([fetched]).filter(predicate.evaluate(with:))
      if set.isEmpty {
        fetchedObject = nil
        handler(.delete(object: fetched))
      }
    }

    if let inserted = process(changes.inserted) {
      fetchedObject = inserted
      handler(.insert(object: inserted))
      return
    }

    if let updated = process(changes.updated) {
      fetchedObject = updated
      handler(.update(object: updated))
      return
    }

    if let deleted = process(changes.deleted) {
      fetchedObject = nil
      handler(.delete(object: deleted))
      return
    }
  }
}
