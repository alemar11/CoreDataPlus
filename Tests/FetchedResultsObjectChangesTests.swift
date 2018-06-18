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

import XCTest
import CoreData
@testable import CoreDataPlus

class FetchedResultsObjectChangesTests: XCTestCase {
    
  func testNoChanges() throws {
    // Given
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
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

  func testObjectsChanges() throws {
    // Given
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    context.fillWithSampleData()
    try context.save()

    let request = Person.newFetchRequest()
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Person.firstName), ascending: false)])

    let delegate = MockNSFetchedResultControllerDelegate()

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
    
}

fileprivate final class MockNSFetchedResultControllerDelegate<T: NSManagedObjectContext>: NSObject, NSFetchedResultsControllerDelegate {
  var changes = [FetchedResultsObjectChange<Person>]()
  var sectionChanges = [FetchedResultsSectionChange<Person>]()
  var willChangeExpectation = XCTestExpectation(description: "\(#function)\(#line)")
  var didChangeExpectation = XCTestExpectation(description: "\(#function)\(#line)")

  public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    if let change = FetchedResultsObjectChange<Person>(object: anObject, indexPath: indexPath, changeType: type, newIndexPath: newIndexPath) {
      changes.append(change)
    }
  }

  public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    if let change = FetchedResultsSectionChange<Person>(section: sectionInfo, index: sectionIndex, changeType: type) {
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
