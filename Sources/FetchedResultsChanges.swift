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

// MARK: - Object

/// **CoreDataPlus**
///
/// An `enum` representing the four types of object changes a `FetchedResultsController` can notify.
public enum FetchedResultsObjectChange<T: NSManagedObject> {

  /// An object has been inserted.
  /// - parameter object: The inserted object of type `<T>`
  /// - parameter indexPath: The `NSIndexPath` of the new object
  case insert(object: T, indexPath: IndexPath)

  /// An object has been deleted.
  /// - parameter object: The deleted object of type `<T>`
  /// - parameter indexPath: The previous `NSIndexPath` of the deleted object
  case delete(object: T, indexPath: IndexPath)

  /// An object has been moved.
  /// - parameter object: The moved object of type `<T>`
  /// - parameter fromIndexPath: The `NSIndexPath` of the old location of the object
  /// - parameter toIndexPath: The `NSIndexPath` of the new location of the object
  case move(object: T, fromIndexPath: IndexPath, toIndexPath: IndexPath)

  /// An object has been updated.
  /// - parameter object: The updated object of type `<T>`
  /// - parameter indexPath `NSIndexPath`: The `NSIndexPath` of the updated object
  case update(object: T, indexPath: IndexPath)
}

extension FetchedResultsObjectChange {

  /// **CoreDataPlus**
  ///
  /// Creates a new `FetchedResultsObjectChange` element.
  ///
  /// - Parameters:
  ///   - object: The changed object
  ///   - indexPath: The old index patch for the object
  ///   - type: The type of the reported change
  ///   - newIndexPath: The new index path for the object
  public init?(object: Any, indexPath: IndexPath?, changeType type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    guard let object = object as? T else { return nil }

    switch (type, indexPath, newIndexPath) {
    case (.insert, _?, _):
      // Work around a bug in Xcode 7.0 and 7.1 on iOS 8: updated objects sometimes result in both an Update *and* and Insert call to didChangeObject.
      // Thankfully the bad Inserts have a non-nil "old" indexPath.
      // For more discussion, see https://forums.developer.apple.com/thread/12184
      return nil

    case let (.insert, nil, newIndexPath?):
      self = .insert(object: object, indexPath: newIndexPath)

    case let (.delete, indexPath?, nil):
      self = .delete(object: object, indexPath: indexPath)

    case let (.update, indexPath?, _):
      // before iOS 9, a newIndexPath value was also passed in.
      self = .update(object: object, indexPath: indexPath)

    case let (.move, fromIndexPath?, toIndexPath?):
      // There are at least two different .move-related bugs running on Xcode 7.3.1:
      // - iOS 8.4 sometimes reports both an .update and a .move (with identical index paths) for the same object.
      // - iOS 9.3 sometimes reports just a .move (with identical index paths) and no .update for an object.
      //
      // According to https://developer.apple.com/library/ios/releasenotes/iPhone/NSFetchedResultsChangeMoveReportedAsNSFetchedResultsChangeUpdate/
      // there shouldn't be moves with identical index paths.
      // Work around: identical indexPath are converted .moves into .updates (it fixes the wrong behavior on iOS 9.3; iOS 8.4 will get "double updates" sometimes, but hopefully that's ok).
      if fromIndexPath == toIndexPath {
        self = .update(object: object, indexPath: fromIndexPath)
      } else {
        self = .move(object: object, fromIndexPath: fromIndexPath, toIndexPath: toIndexPath)
      }

    default:
      preconditionFailure("Invalid change. Missing a required index path for corresponding change type.")
    }
  }
}

// MARK: - Section

/// **CoreDataPlus**
///
/// Section info used during the notification of a section being inserted or deleted.
public struct FetchedResultsSectionInfo<T: NSManagedObject> {

  /// **CoreDataPlus**
  ///
  /// The number of objects belonging to the section.
  public var numberOfObjects: Int

  /// **CoreDataPlus**
  ///
  /// Array of objects belonging to the section.
  public let objects: [T]

  /// **CoreDataPlus**
  ///
  /// The name of the section
  public let name: String

  /// **CoreDataPlus**
  ///
  /// The string used as an index title of the section.
  public let indexTitle: String?

  /// **CoreDataPlus**
  ///
  /// Create a new element of `FetchedResultsSectionInfo` for a given `NSFetchedResultsSectionInfo` object.
  public init(_ info: NSFetchedResultsSectionInfo) {
    objects = (info.objects as? [T]) ?? []
    name = info.name
    indexTitle = info.indexTitle
    numberOfObjects = info.numberOfObjects
  }

}

/// **CoreDataPlus**
///
/// An `enum` representing the two type of section changes a `FetchedResultsController` can notify.
public enum FetchedResultsSectionChange<T: NSManagedObject> {

  /// A section has been inserted.
  /// - parameter info: The inserted section's information
  /// - parameter index: The index where the section was inserted
  case insert(info: FetchedResultsSectionInfo<T>, index: Int)

  /// A section has been deleted.
  /// - parameter info: The deleted section's information
  /// - parameter index: The previous index where the section was before being deleted
  case delete(info: FetchedResultsSectionInfo<T>, index: Int)
}

extension FetchedResultsSectionChange {

  /// **CoreDataPlus**
  ///
  /// Creates a new FetchedResultsSectionChange element.
  ///
  /// - Parameters:
  ///   - sectionInfo: The `NSFetchedResultsSectionInfo` instance
  ///   - sectionIndex: The section index
  ///   - type: The type of the reported change
  public init?(section sectionInfo: NSFetchedResultsSectionInfo, index sectionIndex: Int, changeType type: NSFetchedResultsChangeType) {
    let info = FetchedResultsSectionInfo<T>(sectionInfo)

    switch type {
    case .insert:
      self = .insert(info: info, index: sectionIndex)
    case .delete:
      self = .delete(info: info, index: sectionIndex)
    case .move, .update:
      //preconditionFailure("Invalid section change type reported by NSFetchedResultsController.")
      return nil
    }
  }

}
