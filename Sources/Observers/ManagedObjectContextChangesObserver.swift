//
// CoreDataPlus
//
// Copyright © 2016-2020 Tinrobots.
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
//
//
// Several system frameworks use Core Data internally.
// If you register to receive these notifications from all contexts (by passing nil as the object parameter to a method such as addObserver(_:selector:name:object:)),
// then you may receive unexpected notifications that are difficult to handle.

import CoreData

public extension ManagedObjectContextChangesObserver {
  /// **CoreDataPlus**
  ///
  /// Identifies which `NSManagedObjectContext` should be observed.
  ///
  /// - all->Bool: A list of `NSManagedObjectContext` satisfying the filter.
  /// - one: A single `NSManagedObjectContext`
  enum ObservedManagedObjectContext {
    case all(matching: (NSManagedObjectContext) -> Bool)
    case one(NSManagedObjectContext)

    /// The observed `NSManagedObjectContext`, nil if multiple context are observerd.
    fileprivate var managedObjectContext: NSManagedObjectContext? {
      switch self {
      case .one(context: let context): return context
      default: return nil
      }
    }
  }
}

/// **CoreDataPlus**
///
/// Observes all the changes happening on one or multiple NSManagedObjectContexts.
public final class ManagedObjectContextChangesObserver {
  public typealias Handler = (AnyManagedObjectContextChange<NSManagedObject>, NSManagedObjectContext.ObservableEvents, NSManagedObjectContext) -> Void

  // MARK: - Private properties

  private let observedManagedObjectContext: ObservedManagedObjectContext
  private let event: NSManagedObjectContext.ObservableEvents
  private let queue: OperationQueue?
  private let notificationCenter = NotificationCenter.default
  private let handler: Handler
  private var tokens = [NSObjectProtocol]()

  // MARK: - Initializers

  /// **CoreDataPlus**
  ///
  /// Initializes a new `ManagedObjectContextChangesObserver` object.
  ///
  /// - Parameters:
  ///   - observedManagedObjectContext: The observer `NSManagedObjectContext`.
  ///   - event: The observed event.
  ///   - queue: The operation queue to which block should be added. If you pass nil, the block is run synchronously on the posting thread
  ///   - handler: Callback called everytime a change happens.
  public init(observedManagedObjectContext: ObservedManagedObjectContext,
              event: NSManagedObjectContext.ObservableEvents,
              queue: OperationQueue? = nil,
              handler: @escaping Handler) {
    self.observedManagedObjectContext = observedManagedObjectContext
    self.event = event
    self.queue = queue
    self.handler = handler
    setup()
  }

  deinit {
    removeObservers()
  }

  // MARK: - Private Implementation

  /// Removes all the observers.
  private func removeObservers() {
    tokens.forEach { token in
      notificationCenter.removeObserver(token)
    }
    tokens.removeAll()
  }

  /// Adds the observers for the event.
  private func setup() {
    if event.contains(.didChange) {
      let token = notificationCenter.addObserver(forName: .NSManagedObjectContextObjectsDidChange,
                                                 object: observedManagedObjectContext.managedObjectContext,
                                                 queue: queue) { [weak self] notification in
                                                  guard let self = self else { return }

                                                  let didChangeNotification = ManagedObjectContextObjectsDidChangeNotification(notification: notification)
                                                  if let changes = self.processChanges(in: didChangeNotification) {
                                                    self.handler(changes, .didChange, didChangeNotification.managedObjectContext)
                                                  }
      }
      tokens.append(token)
    }

    if event.contains(.willSave) {
      let token = notificationCenter.addObserver(forName: .NSManagedObjectContextWillSave,
                                                 object: observedManagedObjectContext.managedObjectContext,
                                                 queue: queue) { [weak self] notification in
                                                  guard let self = self else { return }

                                                  // willSave doesn't contain any info, no processing to be done
                                                  let willSaveNotification = ManagedObjectContextWillSaveNotification(notification: notification)
                                                  if self.validateContext(willSaveNotification.managedObjectContext) {
                                                    let changes = AnyManagedObjectContextChange.makeEmpty()
                                                    self.handler(changes, .didSave, willSaveNotification.managedObjectContext)
                                                  }
      }
      tokens.append(token)
    }

    if event.contains(.didSave) {
      let token = notificationCenter.addObserver(forName: .NSManagedObjectContextDidSave,
                                                 object: observedManagedObjectContext.managedObjectContext,
                                                 queue: queue) { [weak self] notification in
        guard let self = self else { return }

        let didSaveNotification = ManagedObjectContextDidSaveNotification(notification: notification)
        if let changes = self.processChanges(in: didSaveNotification) {
          self.handler(changes, .didSave, didSaveNotification.managedObjectContext)
        }
      }
      tokens.append(token)
    }
  }

  private func validateContext(_ context: NSManagedObjectContext) -> Bool {
    switch observedManagedObjectContext {
    case .one(context: let context): return context === context
    case .all(matching: let filter): return filter(context)
    }
  }

  /// Processes incoming notifications.
  private func processChanges<N: ManagedObjectContextChange & ManagedObjectContextNotification>(in notification: N) -> AnyManagedObjectContextChange<N.ManagedObject>? {
    guard validateContext(notification.managedObjectContext) else { return nil }

    return notification.isEmpty ? nil : AnyManagedObjectContextChange(notification)
  }
}
