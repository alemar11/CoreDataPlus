// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

final class FetchedResultsChanges_Tests: InMemoryTestCase {
  func test__NoChanges() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let request = Person.newFetchRequest()
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Person.firstName), ascending: false)])

    let delegate = MockNSFetchedResultControllerDelegate()
    delegate.willChangeExpectation.isInverted = true
    delegate.didChangeExpectation.isInverted = true

    // When
    let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    controller.delegate = delegate

    try controller.performFetch()

    // Then
    wait(for: [delegate.willChangeExpectation, delegate.didChangeExpectation], timeout: 10)
    XCTAssertEqual(context, controller.managedObjectContext)
    XCTAssertNotNil(controller.fetchedObjects)
    XCTAssertEqual(controller.object(at: IndexPath(item: 0, section: 0)), controller.fetchedObjects?.first)
    XCTAssertEqual(controller.fetchRequest, request)
    XCTAssertFalse(controller.fetchedObjects!.isEmpty)
  }

  func test__RefreshAllObjects() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let request = Person.newFetchRequest()
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Person.firstName), ascending: false)])
    let delegate = MockNSFetchedResultControllerDelegate()

    // When
    let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    controller.delegate = delegate

    try controller.performFetch()

    context.refreshAllObjects()

    // Then
    wait(for: [delegate.willChangeExpectation, delegate.didChangeExpectation], timeout: 10)
    XCTAssertEqual(context, controller.managedObjectContext)
    XCTAssertNotNil(controller.fetchedObjects)
    XCTAssertEqual(controller.object(at: IndexPath(item: 0, section: 0)), controller.fetchedObjects?.first)
    XCTAssertEqual(controller.fetchRequest, request)
    XCTAssertFalse(controller.fetchedObjects!.isEmpty)

    delegate.changes.forEach { change in
      switch change  {
      case .delete(object: _, indexPath: _), .insert(object: _, indexPath: _): XCTFail("Unexpected change.")
      default: break // during a regresh we can have an update or a move
      }
    }
  }

  func test__ObjectsChanges() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let request = Person.newFetchRequest()
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Person.firstName), ascending: false)])

    let delegate = MockNSFetchedResultControllerDelegate()

    // When
    let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    controller.delegate = delegate

    try controller.performFetch()

    let firstPerson = controller.fetchedObjects!.first!
    controller.managedObjectContext.delete(firstPerson)

    let secondPerson = controller.fetchedObjects![1]
    secondPerson.lastName = "updated"

    let thirdPerson = controller.fetchedObjects![2]
    thirdPerson.lastName = "updated"

    let lastPerson = controller.fetchedObjects!.last!
    lastPerson.firstName = "moved"

    let newPerson1 = Person(context: context)
    newPerson1.firstName = "zzz1"
    newPerson1.lastName = "test"

    let newPerson2 = Person(context: context)
    newPerson2.firstName = "zzz2"
    newPerson2.lastName = "test"

    // Then
    wait(for: [delegate.willChangeExpectation, delegate.didChangeExpectation], timeout: 10)
    XCTAssertEqual(delegate.changes.count, 6)

    let inserts = delegate.changes.filter {
      guard case FetchedResultsObjectChange.insert = $0 else { return false }
      return true
    }
    let deletes = delegate.changes.filter {
      guard case FetchedResultsObjectChange.delete = $0 else { return false }
      return true
    }
    let moves = delegate.changes.filter {
      guard case FetchedResultsObjectChange.move = $0 else { return false }
      return true
    }
    let updates = delegate.changes.filter {
      guard case FetchedResultsObjectChange.update = $0 else { return false }
      return true
    }
    XCTAssertEqual(inserts.count, 2)
    XCTAssertEqual(deletes.count, 1)
    XCTAssertEqual(moves.count, 1)
    XCTAssertEqual(updates.count, 2)

  }

  func test__SectionsChanges() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let request = Person.newFetchRequest()
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Person.lastName), ascending: false)])

    let delegate = MockNSFetchedResultControllerDelegate()

    // When
    let controller = NSFetchedResultsController(fetchRequest: request,
                                                managedObjectContext: context,
                                                sectionNameKeyPath: #keyPath(Person.lastName),
                                                cacheName: nil)
    controller.delegate = delegate

    try controller.performFetch()

    // sections starting with A and B will be destroyed and a new section Z will be created
    for person in controller.fetchedObjects! {
      if person.lastName.starts(with: "A") {
        person.lastName = "Z"
      }
      if person.lastName.starts(with: "B") {
        person.lastName = "Z"
      }
    }

    // Then
    wait(for: [delegate.willChangeExpectation, delegate.didChangeExpectation], timeout: 10)
    XCTAssertEqual(delegate.sectionChanges.count, 3)
    let inserts = delegate.sectionChanges.filter {
      guard case FetchedResultsSectionChange.insert = $0 else { return false }
      return true
    }
    let deletes = delegate.sectionChanges.filter {
      guard case FetchedResultsSectionChange.delete = $0 else { return false }
      return true
    }
    XCTAssertEqual(inserts.count, 1)
    XCTAssertEqual(deletes.count, 2)
  }

  func test__DeleteDueToThePredicate() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()

    let request = Car.newFetchRequest()
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Car.numberPlate), ascending: false)])
    let predicate = NSPredicate(format: "\(#keyPath(Car.numberPlate)) == %@", "304")
    request.predicate = predicate

    let delegate = MockNSFetchedResultControllerDelegate()

    // When
    let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    controller.delegate = delegate

    try controller.performFetch()
    let car = controller.fetchedObjects!.first
    car!.numberPlate = "304 no more" // car needs to be deleted because the numberPlate doesn't fullfil the predicate anymore
    try context.save()

    // Then
    wait(for: [delegate.willChangeExpectation, delegate.didChangeExpectation], timeout: 10)
    XCTAssertEqual(context, controller.managedObjectContext)
    XCTAssertNotNil(controller.fetchedObjects)
    XCTAssertEqual(delegate.changes.count, 1)

    switch delegate.changes.first! {
    case .delete(object: _, indexPath: _):
      break
    default:
      XCTFail("Unexpected change")
    }
    XCTAssertEqual(controller.fetchRequest, request)
    XCTAssertTrue(controller.fetchedObjects!.isEmpty)
  }
}

fileprivate final class MockNSFetchedResultControllerDelegate<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
  var changes = [FetchedResultsObjectChange<T>]()
  var sectionChanges = [FetchedResultsSectionChange<T>]()
  var willChangeExpectation = XCTestExpectation(description: "\(#function)\(#line)")
  var didChangeExpectation = XCTestExpectation(description: "\(#function)\(#line)")

  public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    if let change = FetchedResultsObjectChange<T>(object: anObject, indexPath: indexPath, changeType: type, newIndexPath: newIndexPath) {
      changes.append(change)
    }
  }

  public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    if let change = FetchedResultsSectionChange<T>(section: sectionInfo, index: sectionIndex, changeType: type) {
      sectionChanges.append(change)
    }
  }

  public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    changes = []
    sectionChanges = []
    willChangeExpectation.fulfill()
  }

  public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    didChangeExpectation.fulfill()
  }
}
