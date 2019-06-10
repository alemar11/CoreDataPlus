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

import XCTest
import CoreData
@testable import CoreDataPlus

class FetchedResultsChangesTests: CoreDataPlusTestCase {
  func testNoChanges() throws {
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
  
  func testRefreshAllObjects() throws {
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
  
  func testObjectsChanges() throws {
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
  
  func testSectionsChanges() throws {
    // Given
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()
    
    let request = Person.newFetchRequest()
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Person.lastName), ascending: false)])
    
    let delegate = MockNSFetchedResultControllerDelegate()
    
    // When
    let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: #keyPath(Person.lastName), cacheName: nil)
    controller.delegate = delegate
    
    try controller.performFetch()
    
    // sections starting with A and B will be destroyed and a new sections Z will be created
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
