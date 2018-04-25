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

fileprivate extension FetchedResultsSectionChange {

  init(section sectionInfo: NSFetchedResultsSectionInfo, index sectionIndex: Int, changeType type: NSFetchedResultsChangeType) {
    let info = FetchedResultsSectionInfo<T>(sectionInfo)

    switch type {
    case .insert:
      self = .insert(info: info, index: sectionIndex)
    case .delete:
      self = .delete(info: info, index: sectionIndex)
    case .move, .update:
      preconditionFailure("Invalid section change type reported by NSFetchedResultsController")
    }
  }

}

/// **CoreDataPlus**
///
/// Protocol for delegate callbacks of inserts, deletes, updates and moves of `NSManagedObjects` as well as inserts and deletes of `Sections`.
public protocol FetchedResultsControllerDelegate: class {

  // swiftlint:disable type_name
  associatedtype T: NSManagedObject

  /// **CoreDataPlus**
  ///
  /// Callback including all the processed changes to objects.
  /// - parameter controller: The `FetchedResultsController` posting the callback
  /// - parameter change: The type of change that occurred and all details see `FetchedResultsObjectChange`
  func fetchedResultsController(_ controller: FetchedResultsController<T>, didChangeObject change: FetchedResultsObjectChange<T>)

  /// **CoreDataPlus**
  ///
  /// Callback including all the processed changes to sections.
  /// - parameter controller: The `FetchedResultsController` posting the callback
  /// - parameter change: The type of change that occurred and all details see `FetchedResultsSectionChange`
  func fetchedResultsController(_ controller: FetchedResultsController<T>, didChangeSection change: FetchedResultsSectionChange<T>)

  /// **CoreDataPlus**
  ///
  /// Notifies the receiver that the fetched results controller is about to start processing of one or more changes due to an add, remove, move, or update.
  /// - parameter controller: The `FetchedResultsController` posting the callback
  func fetchedResultsControllerWillChangeContent(_ controller: FetchedResultsController<T>)

  /// **CoreDataPlus**
  ///
  /// Notifies the receiver that the fetched results controller has completed processing of one or more changes due to an add, remove, move, or update.
  /// - parameter controller: The `FetchedResultsController` posting the callback
  func fetchedResultsControllerDidChangeContent(_ controller: FetchedResultsController<T>)

  /// **CoreDataPlus**
  ///
  /// Callback immediately after the fetch request has been executed.
  /// - parameter controller: The `FetchedResultsController` posting the callback
  func fetchedResultsControllerDidPerformFetch(_ controller: FetchedResultsController<T>)
}

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
  fileprivate init(_ info: NSFetchedResultsSectionInfo) {
    objects = (info.objects as? [T]) ?? []
    name = info.name
    indexTitle = info.indexTitle
    numberOfObjects = info.numberOfObjects
  }

}

/// **CoreDataPlus**
///
/// A type safe wrapper around an `NSFetchedResultsController`.
public class FetchedResultsController<T: NSManagedObject> {

  // MARK: - Public Properties

  /// **CoreDataPlus**
  ///
  /// The `AnyFetchedResultsControllerDelegate` that will receive callback events.
  public var delegate: AnyFetchedResultsControllerDelegate<T>? {

    set {
      if let value = newValue {
        _delegate = WrapperFetchedResultsControllerDelegate<T>(owner: self, delegate: value)
        internalFetchedResultsController.delegate = _delegate
      } else {
        _delegate = nil
      }
    }

    get {
      return _delegate?.delegate
    }

  }

  /// **CoreDataPlus**
  ///
  /// The `NSFetchRequest` being used by the `FetchedResultsController`.
  public var fetchRequest: NSFetchRequest<T> { return internalFetchedResultsController.fetchRequest }

  /// **CoreDataPlus**
  ///
  /// The objects that match the fetch request.
  public var fetchedObjects: [T]? { return internalFetchedResultsController.fetchedObjects }

  /// **CoreDataPlus**
  ///
  /// The sections returned by the `FetchedResultsController` see `FetchedResultsSectionInfo`.
  public var sections: LazyMapCollection<[NSFetchedResultsSectionInfo], FetchedResultsSectionInfo<T>>? {
    guard let sections = internalFetchedResultsController.sections else { return nil }

    return sections.lazy.map(FetchedResultsSectionInfo<T>.init)
  }

  /// **CoreDataPlus**
  ///
  /// The name of the file used to cache section information.
  public var cacheName: String? { return internalFetchedResultsController.cacheName }

  /// **CoreDataPlus**
  ///
  /// Subscript access to the sections.
  public subscript(indexPath: IndexPath) -> T { return internalFetchedResultsController.object(at: indexPath) }

  /// **CoreDataPlus**
  ///
  /// The `NSIndexPath` for a specific object in the fetchedObjects.
  public func indexPathForObject(_ object: T) -> IndexPath? { return internalFetchedResultsController.indexPath(forObject: object) }

  // MARK: - Private Properties
  private let internalFetchedResultsController: NSFetchedResultsController<T>

  /// Used only for internal unit tests.
  // swiftlint:disable:next identifier_name
  internal var __wrappedDelegate: WrapperFetchedResultsControllerDelegate<T>? { return _delegate }

  // swiftlint:disable:next weak_delegate
  private var _delegate: WrapperFetchedResultsControllerDelegate<T>?

  // MARK: - Lifecycle

  /// **CoreDataPlus**
  ///
  /// Create a new instance of `FetchedResultsController`.
  ///
  /// - parameter fetchRequest: The `NSFetchRequest` used to filter the objects displayed: the entityName must match the specialized type <T> of this class.
  /// - parameter context: The `NSManagedObjectContext` being observed for changes.
  /// - parameter sectionNameKeyPath: An optional key path used for grouping results.
  /// - parameter cacheName: An optional unique name used for caching results see `NSFetchedResultsController` for details.
  public init(fetchRequest: NSFetchRequest<T>, managedObjectContext context: NSManagedObjectContext, sectionNameKeyPath: String? = nil, cacheName: String? = nil) {
    internalFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
  }

  deinit {
    // Core Data does not yet use weak references for delegates; the delegate must be set to nil for thread safety reasons.
    _delegate = nil
    internalFetchedResultsController.delegate = nil
  }

  // MARK: - Public Functions

  /// **CoreDataPlus**
  ///
  /// Executes the fetch request tied to the `FetchedResultsController`.
  /// - throws: Any errors produced by the `NSFetchResultsController`s `performFetch()` function.
  public func performFetch() throws {
    defer {
      _delegate?.fetchedResultsControllerDidPerformFetch()
    }
    do {
      try internalFetchedResultsController.performFetch()
    } catch {
      throw CoreDataPlusError.fetchFailed(error: error)
    }
  }

}

private extension FetchedResultsObjectChange {

  init?(object: AnyObject, indexPath: IndexPath?, changeType type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    guard let object = object as? T else { return nil }
    switch (type, indexPath, newIndexPath) {
    case (.insert, _?, _):
      // Work around a bug in Xcode 7.0 and 7.1 when running on iOS 8 - updated objects sometimes result in both an Update *and* and Insert call to didChangeObject, which makes no sense.
      //Thankfully the bad Inserts have a non-nil "old" indexPath (which also makes no sense) - we check for that here and ignore those erroneous messages.
      // For more discussion, see https://forums.developer.apple.com/thread/12184
      return nil

    case let (.insert, nil, newIndexPath?):
      self = .insert(object: object, indexPath: newIndexPath)

    case let (.delete, indexPath?, nil):
      self = .delete(object: object, indexPath: indexPath)

    case let (.update, indexPath?, _):
      // in pre iOS 9 runtimes a newIndexPath value is also passed in
      self = .update(object: object, indexPath: indexPath)

    case let (.move, fromIndexPath?, toIndexPath?):
      // There are at least two different .move-related bugs running on Xcode 7.3.1:
      //
      // * iOS 8.4 sometimes reports both an .update and a .move (with identical index paths) for the same object.
      // * iOS 9.3 sometimes reports _just_ a .move (with identical index paths) and no .update for an object.
      //
      // According to https://developer.apple.com/library/ios/releasenotes/iPhone/NSFetchedResultsChangeMoveReportedAsNSFetchedResultsChangeUpdate/
      // we shouldn't get moves with identical index paths, but we have to work around this somehow.
      // For now, we'll convert identical-indexPath-.Moves into .Updates (just like that document claims NSFetchedResultsController does).
      // This means we'll get correct behavior on iOS 9.3. iOS 8.4 will get "double updates" sometimes, but _hopefully_ that's ok.
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

/// **CoreDataPlus**
///
/// A type-erased wrapper over any `FetchedResultsControllerDelegate`.
public class AnyFetchedResultsControllerDelegate<T: NSManagedObject>: FetchedResultsControllerDelegate {

  public func fetchedResultsController(_ controller: FetchedResultsController<T>, didChangeObject change: FetchedResultsObjectChange<T>) {
    _fetchedResultsControllerDidChangeObject(controller, change)
  }

  public func fetchedResultsController(_ controller: FetchedResultsController<T>, didChangeSection change: FetchedResultsSectionChange<T>) {
    _fetchedResultsControllerDidChangeSection(controller, change)
  }

  public func fetchedResultsControllerWillChangeContent(_ controller: FetchedResultsController<T>) {
    _fetchedResultsControllerWillChangeContent(controller)
  }

  public func fetchedResultsControllerDidChangeContent(_ controller: FetchedResultsController<T>) {
    _fetchedResultsControllerDidChangeContent(controller)
  }

  public func fetchedResultsControllerDidPerformFetch(_ controller: FetchedResultsController<T>) {
    _fetchedResultsControllerDidPerformFetch(controller)
  }

  public required init<U: FetchedResultsControllerDelegate>(_ delegate: U) where U.T == T {
    fetchedResultsControllerWillChangeContent = delegate.fetchedResultsControllerWillChangeContent(_:)
    fetchedResultsControllerDidChangeContent = delegate.fetchedResultsControllerDidChangeContent(_:)
    fetchedResultsControllerDidChangeObject = delegate.fetchedResultsController(_:didChangeObject:)
    fetchedResultsControllerDidChangeSection = delegate.fetchedResultsController(_:didChangeSection:)
    fetchedResultsControllerDidPerformFetch = delegate.fetchedResultsControllerDidPerformFetch(_:)
  }

  // swiftlint:disable identifier_name
  private var fetchedResultsControllerDidChangeObject: (FetchedResultsController<T>, FetchedResultsObjectChange<T>) -> Void
  private var fetchedResultsControllerDidChangeSection: (FetchedResultsController<T>, FetchedResultsSectionChange<T>) -> Void
  private var fetchedResultsControllerWillChangeContent: (FetchedResultsController<T>) -> Void
  private var fetchedResultsControllerDidChangeContent: (FetchedResultsController<T>) -> Void
  private var fetchedResultsControllerDidPerformFetch: (FetchedResultsController<T>) -> Void
  // swiftlint:enable identifier_name

}

internal class WrapperFetchedResultsControllerDelegate<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {

  internal unowned var owner: FetchedResultsController<T>
  internal weak var delegate: AnyFetchedResultsControllerDelegate<T>?

  fileprivate init(owner: FetchedResultsController<T>, delegate: AnyFetchedResultsControllerDelegate<T>) {
    self.owner = owner
    self.delegate = delegate
  }

  internal func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    delegate?.fetchedResultsControllerWillChangeContent(owner)
  }

  internal func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    delegate?.fetchedResultsControllerDidChangeContent(owner)
  }

  internal func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                           didChange anObject: Any, at indexPath: IndexPath?,
                           for type: NSFetchedResultsChangeType,
                           newIndexPath: IndexPath?) {
    guard let object = anObject as? T else { return }
    guard let change = FetchedResultsObjectChange<T>(object: object, indexPath: indexPath, changeType: type, newIndexPath: newIndexPath) else { return }

    delegate?.fetchedResultsController(owner, didChangeObject: change)
  }

  internal func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                           didChange sectionInfo: NSFetchedResultsSectionInfo,
                           atSectionIndex sectionIndex: Int,
                           for type: NSFetchedResultsChangeType) {
    let change = FetchedResultsSectionChange<T>(section: sectionInfo, index: sectionIndex, changeType: type)
    delegate?.fetchedResultsController(owner, didChangeSection: change)
  }

  internal func fetchedResultsControllerDidPerformFetch() {
    delegate?.fetchedResultsControllerDidPerformFetch(owner)
  }

}
