import CoreData

public extension NSManagedObjectContext {
  /// **CoreDataPlus**
  ///
  /// `OptionSet` with all the observable NSMAnagedObjectContext events.
  struct ObservableEvents: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
      self.rawValue = rawValue
    }

    /// **CoreDataPlus**
    ///
    /// Notifications will be sent upon `NSManagedObjectContext` being changed.
    /// - Note: The change notification is sent in NSManagedObjectContext’s processPendingChanges method.
    ///
    /// If the context is not on the main thread, you should call *processPendingChanges* yourself at appropriate junctures unless you call a method that uses `processPendingChanges` internally.
    ///
    /// - Important: Some `NSManagedObjectContext`'s methods call `processPendingChanges` internally such as `save()`, `reset()`, `refreshAllObjects()` and `perform(_:)`
    /// (`performAndWait(_:)` **does not**).
    public static let didChange = NSManagedObjectContext.ObservableEvents(rawValue: 1 << 0)

    /// **CoreDataPlus**
    ///
    /// Notifications will be sent before `NSManagedObjectContext` being saved.
    /// - Note: There is no extra info associated with this event; it just notifies that a `NSManagedObjectContext` is about to being saved.
    public static let willSave = NSManagedObjectContext.ObservableEvents(rawValue: 1 << 1)

    /// **CoreDataPlus**
    ///
    /// Notifications will be sent upon `NSManagedObjectContext` being saved.
    public static let didSave = NSManagedObjectContext.ObservableEvents(rawValue: 1 << 2)

    /// **CoreDataPlus**
    ///
    /// Notifications will be sent upon `NSManagedObjectContext` being saved or changed.
    public static let all: NSManagedObjectContext.ObservableEvents = [.didChange, .willSave, .didSave]
  }
}
