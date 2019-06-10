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

public enum ChangeType {
  case firstFetch
  case insert
  case update
  case delete
}

open class SingleFetchedResultController<T: NSManagedObject> {

  public typealias OnChange = ((T, ChangeType) -> Void)

  public let predicate: NSPredicate
  public let managedObjectContext: NSManagedObjectContext
  public let onChange: OnChange
  public fileprivate(set) var fetchedObject: T? = nil

  public init(predicate: NSPredicate, managedObjectContext: NSManagedObjectContext, onChange: @escaping OnChange) {
    self.predicate = predicate
    self.managedObjectContext = managedObjectContext
    self.onChange = onChange

    NotificationCenter.default.addObserver(self, selector: #selector(objectsDidChange(_:)), name: .NSManagedObjectContextObjectsDidChange, object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  open func performFetch() throws {
    let fetchRequest = NSFetchRequest<T>(entityName: T.entityName)
    fetchRequest.predicate = predicate

    let results = try managedObjectContext.fetch(fetchRequest)
    
    assert(results.count < 2) // we shouldn't have any duplicates

    if let result = results.first {
      fetchedObject = result
      onChange(result, .firstFetch)
    }
  }

  @objc func objectsDidChange(_ notification: Notification) {
    updateCurrentObject(notification: notification, key: NSInsertedObjectsKey)
    updateCurrentObject(notification: notification, key: NSUpdatedObjectsKey)
    updateCurrentObject(notification: notification, key: NSDeletedObjectsKey)
  }

  fileprivate func updateCurrentObject(notification: Notification, key: String) {
    guard let allModifiedObjects = (notification as NSNotification).userInfo?[key] as? Set<NSManagedObject> else {
      return
    }

    let objectsWithCorrectType = Set(allModifiedObjects.filter { return $0 as? T != nil })
    let matchingObjects = NSSet(set: objectsWithCorrectType)
      .filtered(using: self.predicate) as? Set<NSManagedObject> ?? []

    assert(matchingObjects.count < 2)

    guard let matchingObject = matchingObjects.first as? T else {
      return
    }

    fetchedObject = matchingObject
    onChange(matchingObject, changeType(fromKey: key))
  }

  fileprivate func changeType(fromKey key: String) -> ChangeType {
    let map: [String : ChangeType] = [
      NSInsertedObjectsKey : .insert,
      NSUpdatedObjectsKey : .update,
      NSDeletedObjectsKey : .delete,
    ]
    return map[key]!
  }
}
