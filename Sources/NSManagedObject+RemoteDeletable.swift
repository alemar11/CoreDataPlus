// 
// CoreDataPlus
//
// Copyright © 2016-2017 Tinrobots.
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

private let markedForRemoteDeletionKey = "isMarkedForRemoteDeletion"

/// **CoreDataPlus**
///
/// Objects adopting the `RemoteDeletable` support remote deletion.
public protocol RemoteDeletable: class {
  
  /// **CoreDataPlus**
  ///
  /// Protocol `RemoteDeletable`.
  ///
  /// Checks whether or not the managed object’s `markedForRemoteDeletion` property has unsaved changes.
  var hasChangedForRemoteDeletion: Bool { get }
  
  /// **CoreDataPlus**
  ///
  /// Protocol `RemoteDeletable`.
  ///
  /// Returns `true` if the object is marked to be deleted remotely.
  var isMarkedForRemoteDeletion: Bool { get set }
  
  /// **CoreDataPlus**
  ///
  /// Protocol `RemoteDeletable`.
  ///
  /// Marks an object to be deleted remotely, on the backend (i.e. Cloud Kit).
  func markForRemoteDeletion()
  
}

// MARK: - RemoteDeletable Extension

extension RemoteDeletable {
  
  /// **CoreDataPlus**
  ///
  /// Protocol `RemoteDeletable`.
  ///
  /// Predicate to filter for objects that aren’t marked for remote deletion.
  public static var notMarkedForRemoteDeletionPredicate: NSPredicate {
    return NSPredicate(format: "%K == false", markedForRemoteDeletionKey)
  }
  
  /// **CoreDataPlus**
  ///
  /// Protocol `RemoteDeletable`.
  ///
  /// Predicate to filter for objects that are marked for remote deletion.
  public static var markedForRemoteDeletionPredicate: NSPredicate {
    return NSCompoundPredicate(notPredicateWithSubpredicate: notMarkedForRemoteDeletionPredicate)
  }
  
  /// **CoreDataPlus**
  ///
  /// Protocol `RemoteDeletable`.
  ///
  /// Marks an object to be deleted remotely.
  public func markForRemoteDeletion() {
    isMarkedForRemoteDeletion = true
  }
  
}

extension RemoteDeletable where Self: NSManagedObject {
  
  /// **CoreDataPlus**
  ///
  /// Protocol `RemoteDeletable`.
  ///
  /// Returns true if `self` has been marked for remote deletion.
  public var hasChangedForRemoteDeletion: Bool {
    return changedValue(forKey: markedForRemoteDeletionKey) as? Bool == true
  }
  
}

extension RemoteDeletable where Self: DelayedDeletable {
  
  /// **CoreDataPlus**
  ///
  /// Protocol `RemoteDeletable`.
  ///
  /// Predicate to filter for objects that are marked for remote deletion.
  public static var notMarkedForDeletionPredicate: NSPredicate {
    return NSCompoundPredicate(andPredicateWithSubpredicates: [notMarkedForLocalDeletionPredicate, notMarkedForRemoteDeletionPredicate])
  }
  
}
