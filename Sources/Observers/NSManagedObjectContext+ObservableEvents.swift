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
