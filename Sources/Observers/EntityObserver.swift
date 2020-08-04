// CoreDataPlus

import CoreData

/// **CoreDataPlus**
///
/// An object that observes all the changes happening in a `NSManagedObjectContext` for a specific entity.
public final class EntityObserver<T: NSManagedObject> {
  /// **CoreDataPlus**
  ///
  /// The observed event.
  public let event: NSManagedObjectContext.ObservableEvents

  /// **CoreDataPlus**
  ///
  /// If `true`, all the changes happening in the subentities will be observed.
  public let observeSubEntities: Bool

  /// **CoreDataPlus**
  ///
  /// The observed entity.
  public lazy var observedEntity: NSEntityDescription = {
    // Attention: sometimes entity() returns nil due to a CoreData bug occurring in the Unit Test targets or when Generics are used.
    // return T.entity()
    guard let entity = NSEntityDescription.entity(forEntityName: T.entityName, in: managedObjectContext) else {
      preconditionFailure("Missing NSEntityDescription for \(T.entityName)")
    }
    return entity
  }()

  // MARK: - Private properties

  private let managedObjectContext: NSManagedObjectContext
  private let queue: OperationQueue?
  private let handler: (AnyManagedObjectContextChange<T>, NSManagedObjectContext.ObservableEvents) -> Void
  private lazy var observer: ManagedObjectContextChangesObserver = {
    let observer = ManagedObjectContextChangesObserver(observedManagedObjectContext: .one(managedObjectContext),
                                                       event: event,
                                                       queue: queue) { [weak self] (changes, event, context) in
                                                        guard let self = self else { return }

                                                        self.handleChanges(changes, for: event, in: context)
    }
    return observer
  }()

  // MARK: - Initializers

  /// **CoreDataPlus**
  ///
  /// Initializes a new `EntityObserver` object.
  ///
  /// - Parameters:
  ///   - context: The NSManagedContext where the changes are observed.
  ///   - event: The kind of event observed.
  ///   - observeSubEntities: If `true`, all the changes happening in the subentities will be observed. (default: `false`)
  ///   - notificationCenter: The `NotificationCenter` listening the the `NSManagedObjectContext` notifications.
  ///   - The operation queue to which block should be added. If you pass nil, the block is run synchronously on the posting thread.
  ///   - changeHandler: The completion handler.
  public init(context: NSManagedObjectContext,
              event: NSManagedObjectContext.ObservableEvents,
              observeSubEntities: Bool = false,
              queue: OperationQueue? = nil,
              changeHandler: @escaping (AnyManagedObjectContextChange<T>, NSManagedObjectContext.ObservableEvents) -> Void) {
    self.managedObjectContext = context
    self.event = event
    self.observeSubEntities = observeSubEntities
    self.queue = queue
    self.handler = changeHandler
    _ = self.observer
  }

  // MARK: - Private implementation

  /// Processes the incoming notification.
  private func handleChanges<C: ManagedObjectContextChange>(_ changes: C, for event: NSManagedObjectContext.ObservableEvents, in context: NSManagedObjectContext) {
    func process(_ value: Set<NSManagedObject>) -> Set<T> {
      if observeSubEntities {
        return value.filter { $0.entity.topMostEntity == observedEntity } as? Set<T> ?? []
      } else {
        return value.filter { $0.entity == observedEntity } as? Set<T> ?? []
      }
    }

    let deleted = process(changes.deletedObjects)
    let inserted = process(changes.insertedObjects)
    let updated = process(changes.updatedObjects)
    let refreshed = process(changes.refreshedObjects)
    let invalidated = process(changes.invalidatedObjects)
    let invalidatedAll = changes.invalidatedAllObjects.filter { $0.entity == observedEntity }
    let change = AnyManagedObjectContextChange<T>(insertedObjects: inserted,
                                                  updatedObjects: updated,
                                                  deletedObjects: deleted,
                                                  refreshedObjects: refreshed,
                                                  invalidatedObjects: invalidated,
                                                  invalidatedAllObjects: invalidatedAll)
    if !change.isEmpty {
      handler(change, event)
    }
  }
}
