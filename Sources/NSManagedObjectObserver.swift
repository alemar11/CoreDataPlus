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

final class ManagedObjectObserver {
  enum ChangeType {
    case delete
    case update
    //case insert
  }

  init?(object: NSManagedObject, changeHandler: @escaping (ChangeType) -> ()) {
    guard let context = object.managedObjectContext else { return nil }

    token = context.addObjectsDidChangeNotificationObserver { [weak self] notification in
      guard let changeType = self?.changeType(of: object, in: notification) else { return }
      changeHandler(changeType)
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(token)
  }

  // MARK: Private

  fileprivate var token: NSObjectProtocol!

  fileprivate func changeType(of object: NSManagedObject, in notification: ObjectsDidChangeNotification) -> ChangeType? {
    let deleted = notification.deletedObjects.union(notification.invalidatedObjects)

    if notification.invalidatedAllObjects || deleted.containsObjectIdentical(to: object) {
      return .delete
    }

    let updated = notification.updatedObjects.union(notification.refreshedObjects)

    if updated.containsObjectIdentical(to: object) {
      return .update
    }

    return nil
  }
}

extension Sequence where Iterator.Element: AnyObject {
  func containsObjectIdentical(to object: AnyObject) -> Bool {
    return contains { $0 === object }
  }
}
