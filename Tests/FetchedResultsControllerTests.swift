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
@testable import CoreDataPlus

final class FetchedResultsControllerTests: XCTestCase {

  func testReferenceCycleBetweenFetchedResultsControllerAndAnyFetchedResultsControllerDelegate() {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let request = Person.newFetchRequest()
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Person.firstName), ascending: false)])
    let controller = FetchedResultsController<Person>(fetchRequest: request, managedObjectContext: context)
    controller.delegate = AnyFetchedResultsControllerDelegate(MockPersonFetchedResultsControllerDelegate())
    XCTAssertNil(controller.__wrappedDelegate?.delegate, "AnyFetchedResultsControllerDelegate should be referenced weakly by the FetchedResultsController.")
  }

  func testSetup() throws {
    // Given
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    context.fillWithSampleData()
    try context.save()

    let request = Person.newFetchRequest()
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Person.firstName), ascending: false)]) // at least a descriptor is required

    let delegate = MockPersonFetchedResultsControllerDelegate()

    let expectation1 = expectation(description: "\(#function)\(#line)")
    expectation1.isInverted = true
    delegate.willChangeContent = { controller in
      expectation1.fulfill()
    }

    let expectation2 = expectation(description: "\(#function)\(#line)")
    expectation2.isInverted = true
    delegate.didChangeContent = { controller in
      expectation2.fulfill()
    }

    let expectation3 = expectation(description: "\(#function)\(#line)")
    delegate.didPerformFetch = { controller in
      expectation3.fulfill()
    }

    let anyDelegate = AnyFetchedResultsControllerDelegate(delegate)

    // When
    let controller = FetchedResultsController<Person>(fetchRequest: request, managedObjectContext: context)
    controller.delegate = anyDelegate

    try controller.performFetch()

    // Then
    waitForExpectations(timeout: 3)
    XCTAssertNotNil(controller.fetchedObjects)
    XCTAssertEqual(controller.fetchRequest, request)
    XCTAssertTrue(anyDelegate === controller.delegate)
    XCTAssertFalse(controller.fetchedObjects!.isEmpty)
  }

  func testNoFetchedObject() throws {
    // Given
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    context.fillWithSampleData()
    try context.save()

    let request = Person.newFetchRequest()
    request.predicate = NSPredicate(format: "lastName == %@", "QWERTY123")
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Person.firstName), ascending: false)]) // at least a descriptor is required
    let controller = FetchedResultsController<Person>(fetchRequest: request, managedObjectContext: context)

    // Then
    try controller.performFetch()

    // When
    XCTAssertTrue(controller.fetchedObjects!.isEmpty)
  }

  func testDealloc() throws {
    // Given
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    context.fillWithSampleData()
    try context.save()

    let request = Person.newFetchRequest()
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Person.firstName), ascending: false)]) // at least a descriptor is required

    let delegate = MockPersonFetchedResultsControllerDelegate()
    let expectation1 = expectation(description: "\(#function)\(#line)")
    expectation1.isInverted = true
    delegate.willChangeContent = { controller in
      expectation1.fulfill()
    }

    let expectation2 = expectation(description: "\(#function)\(#line)")
    expectation2.isInverted = true
    delegate.didChangeContent = { controller in
      expectation2.fulfill()
    }

    let expectation3 = expectation(description: "\(#function)\(#line)")
    delegate.didPerformFetch = { controller in
      expectation3.fulfill()
    }

    // When
    var anyDelegate: AnyFetchedResultsControllerDelegate? = AnyFetchedResultsControllerDelegate(delegate)
    weak var weakAnyDelegate = anyDelegate

    let controller = FetchedResultsController<Person>(fetchRequest: request, managedObjectContext: context)
    controller.delegate = anyDelegate!

    try controller.performFetch()

    // Then
    waitForExpectations(timeout: 3)
    XCTAssertNotNil(controller.fetchedObjects)
    XCTAssertFalse(controller.fetchedObjects!.isEmpty)

    anyDelegate = nil
    XCTAssertNil(weakAnyDelegate)
    XCTAssertNil(controller.__wrappedDelegate?.delegate, "The retain cycle should be broken.")
    XCTAssertNotNil(controller.__wrappedDelegate)
    controller.delegate = nil
    XCTAssertNil(controller.__wrappedDelegate)
  }

  func testInsertsAndDeletes() throws {
    // Given
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    context.fillWithSampleData() // 20 persons and 25 cars
    try context.save()

    let request = Person.newFetchRequest()
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Person.firstName), ascending: true)]) // at least a descriptor is required

    let delegate = MockPersonFetchedResultsControllerDelegate()

    var count1 = 0
    let expectation1 = expectation(description: "\(#function)\(#line)") // insert
    let expectation6 = expectation(description: "\(#function)\(#line)") // delete
    delegate.willChangeContent = { controller in
      if count1 == 0 {
        expectation1.fulfill()
      } else if count1 == 1 {
        expectation6.fulfill()
      }
      count1 += 1
    }

    var count2 = 0
    let expectation2 = expectation(description: "\(#function)\(#line)") // insert
    let expectation7 = expectation(description: "\(#function)\(#line)") // delete
    delegate.didChangeContent = { controller in
      if count2 == 0 {
        expectation2.fulfill()
      } else if count2 == 1 {
        expectation7.fulfill()
      }
      count2 += 1
    }

    let expectation3 = expectation(description: "\(#function)\(#line)")
    delegate.didPerformFetch = { controller in
      expectation3.fulfill()
    }

    let expectation4 = expectation(description: "\(#function)\(#line)")
    let expectation5 = expectation(description: "\(#function)\(#line)")
    var changes = [FetchedResultsObjectChange<Person>]()
    delegate.didChangeObject = { controller, change in
      changes.append(change)
      if changes.count == 2 {
        expectation4.fulfill()
      } else if changes.count == 19 {
        expectation5.fulfill()
      }
    }

    // When
    let anyDelegate = AnyFetchedResultsControllerDelegate(delegate)

    let controller = FetchedResultsController<Person>(fetchRequest: request, managedObjectContext: context)
    controller.delegate = anyDelegate

    try controller.performFetch()

    XCTAssertNotNil(controller.fetchedObjects)
    XCTAssertNil(controller.cacheName)
    XCTAssertEqual(controller.sections?.count, 1)
    XCTAssertEqual(controller.fetchedObjects!.count, 20)

    let newPerson1 = Person(context: context)
    newPerson1.firstName = "zzz1"
    newPerson1.lastName = "test"

    let newPerson2 = Person(context: context)
    newPerson2.firstName = "zzz2"
    newPerson2.lastName = "test"

    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 3)
    XCTAssertNotNil(controller.fetchedObjects)
    XCTAssertFalse(controller.fetchedObjects!.isEmpty)

    let inserts = changes.filter {
      switch $0 {
      case .insert: return true
      default: return false
      }
    }

    // Then
    XCTAssertEqual(inserts.count, 2)
    XCTAssertEqual(controller[IndexPath(item: 20, section: 0)], newPerson1)
    XCTAssertEqual(controller[IndexPath(item: 21, section: 0)], newPerson2)

    XCTAssertEqual(controller.indexPathForObject(newPerson1), IndexPath(item: 20, section: 0))
    XCTAssertEqual(controller.indexPathForObject(newPerson2), IndexPath(item: 21, section: 0))

    // Wehn
    let firstPerson = controller[IndexPath(item: 0, section: 0)]
    try Person.deleteAll(in: context, except: [firstPerson, newPerson1, newPerson2])

    // Then
    wait(for: [expectation5, expectation6, expectation7], timeout: 10)
    XCTAssertEqual(controller.fetchedObjects?.count, 3)

    let inserts2 = changes.filter {
      switch $0 {
      case .insert: return true
      default: return false
      }
    }

    XCTAssertEqual(inserts2.count, 2)

    let delete2 = changes.filter {
      switch $0 {
      case .delete: return true
      default: return false
      }
    }

    XCTAssertEqual(delete2.count, 19)

  }

  func testChangesAndUpdates() throws {
    // Given
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    context.fillWithSampleData()
    try context.save()

    let request = Person.newFetchRequest()
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Person.firstName), ascending: true)])

    let delegate = MockPersonFetchedResultsControllerDelegate()

    let expectation1 = expectation(description: "\(#function)\(#line)")
    delegate.willChangeContent = { controller in
      expectation1.fulfill()
    }

    let expectation2 = expectation(description: "\(#function)\(#line)")
    delegate.didChangeContent = { controller in
      expectation2.fulfill()
    }

    let expectation3 = expectation(description: "\(#function)\(#line)")
    delegate.didPerformFetch = { controller in
      expectation3.fulfill()
    }

    var changes = [FetchedResultsObjectChange<Person>]()
    delegate.didChangeObject = { controller, change in
      changes.append(change)
    }

    let anyDelegate = AnyFetchedResultsControllerDelegate(delegate)

    // When
    let controller = FetchedResultsController<Person>(fetchRequest: request, managedObjectContext: context)
    controller.delegate = anyDelegate

    try controller.performFetch()
    XCTAssertNotNil(controller.fetchedObjects)
    XCTAssertEqual(controller.fetchedObjects?.count, 20)

    for (index, person) in controller.fetchedObjects!.enumerated() {
      if index == 0 {
        person.firstName = "zzz" // this change should trigger a move (this person should be in the last position)
        person.cars = nil
      } else if index == 1 {
        person.cars = nil
      }
    }

    XCTAssertNotNil(controller.fetchedObjects)
    XCTAssertEqual(controller.fetchedObjects?.count, 20)

    waitForExpectations(timeout: 3)
    XCTAssertEqual(changes.count, 2)

    for change in changes {
      switch change {
      case let .move(object: person, fromIndexPath: from, toIndexPath: to):
        XCTAssertEqual(from, IndexPath(item: 0, section: 0))
        XCTAssertEqual(to, IndexPath(item: 19, section: 0))
        XCTAssertEqual(person.firstName, "zzz")
        XCTAssertTrue(person.cars!.isEmpty)
      case let .update(object: _, indexPath: index):
        XCTAssertEqual(index, IndexPath(item: 1, section: 0))
      default:
        XCTFail("Wrong change")
      }
    }

  }

  func testSectionsChanges() throws {
    // Given
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    context.fillWithSampleData()
    try context.save()

    let request = Person.newFetchRequest()
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Person.lastName), ascending: true)])
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Person.firstName), ascending: true)])

    let delegate = MockPersonFetchedResultsControllerDelegate()

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    var count1 = 0
    delegate.willChangeContent = { controller in
      if count1 == 0 {
        expectation1.fulfill()
      } else if count1 == 1 {
        expectation4.fulfill()
      }
      count1 += 1
    }

    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation5 = expectation(description: "\(#function)\(#line)")
    var count2 = 0
    delegate.didChangeContent = { controller in
      if count2 == 0 {
        expectation2.fulfill()
      } else if count2 == 1 {
        expectation5.fulfill()
      }
      count2 += 1
    }

    let expectation3 = expectation(description: "\(#function)\(#line)")
    delegate.didPerformFetch = { controller in
      expectation3.fulfill()
    }

    var changes = [FetchedResultsObjectChange<Person>]()
    delegate.didChangeObject = { controller, change in
      changes.append(change)
    }

    var sectionChanges = [FetchedResultsSectionChange<Person>]()
    delegate.didChangeSection = { controller, change in
      sectionChanges.append(change)
    }

    let anyDelegate = AnyFetchedResultsControllerDelegate(delegate)

    // When
    let controller = FetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: #keyPath(Person.lastName), cacheName: "Persons")
    controller.delegate = anyDelegate

    try controller.performFetch()
    XCTAssertNotNil(controller.fetchedObjects)
    XCTAssertEqual(controller.fetchedObjects?.count, 20)
    XCTAssertEqual(controller.sections?.count, 18)
    print(controller.sectionIndexTitles)

    // Section change: none
    // Add an Alvis member (from 1 to 2)
    let newAlvisPerson = Person(context: context)
    newAlvisPerson.firstName = "Alex"
    newAlvisPerson.lastName = "Alves"

    // Section change: delete
    // Remove a Boosalis (from 1 to 0)
    try Person.deleteAll(in: context, includingSubentities: true, where: NSPredicate(format: "lastName == %@", "Boosalis"))

    // Rename Wigner in Wignner> --> from 1 to differet 1 (insert and delete)
    let persons = try Person.fetch(in: context) { (request) in
      request.predicate = NSPredicate(format: "lastName == %@", "Wigner")
    }
    XCTAssertEqual(persons.count, 1)
    for person in persons {
      person.lastName = "AAWigner"
    }
    try context.save()

    waitForExpectations(timeout: 3)
    XCTAssertEqual(controller.sections?.first?.name, "AAWigner")
    XCTAssertEqual(controller.sections?.count, 17)

    for change in sectionChanges {
      switch change {
      case let .insert(info: info, index: index):
        if info.name == "AAWigner" {
          XCTAssertEqual(index, 0)
        } else {
          XCTFail("Unexpected section insert: \(change)")
        }
      case let .delete(info: info, index: index):
        if info.name == "Boosalis" {
          XCTAssertEqual(index, 1)
        } else if info.name == "Wigner" {
          XCTAssertEqual(index, 16)
        } else {
          XCTFail("Unexpected section deletion: \(change)")
        }
      }
    }
  }

  func testCustomSectionIndexTitles() throws {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    context.fillWithSampleData()
    try context.save()

    let request = Person.newFetchRequest()
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Person.lastName), ascending: true)])
    request.addSortDescriptors([NSSortDescriptor(key: #keyPath(Person.firstName), ascending: true)])

    let controller = FetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: #keyPath(Person.lastName))
    controller.customSectionIndexTitleHandler = { sectionName in
      let firstLetter = String(sectionName.first!)
      if firstLetter.lowercased() == "w" {
        return "❗️" + firstLetter.lowercased()
      }
      return "🔹" + firstLetter
    }
    try controller.performFetch()
    //print(controller.sections!.enumerated().map { $0.element.name })

    // Sections
    // ["Alves", "Boosalis", "Chuang", "Coster", "Distefano", "Gleaves", "Hurowitz", "Khoury", "Meadow", "Moreton", "Munger", "Nabokov", "Pyke", "Rathbun", "Reynolds", "Stone", "Wade", "Wigner"]

    // Defaults index titles: A, B, C, D, G, H, K, M, N, P, R, S, W

    XCTAssertEqual(controller.sections?.count, 18)
    XCTAssertEqual(controller.sectionIndexTitles.count, 13)

    let expectedValues = ["🔹A", "🔹B", "🔹C", "🔹D", "🔹G", "🔹H", "🔹K", "🔹M", "🔹N", "🔹P", "🔹R", "🔹S", "❗️w"]
    for title in controller.sectionIndexTitles {
      print(title)
      guard expectedValues.contains(title) else {
        XCTFail("\(title) doesn't start with 🔹")
        return
      }

    }
  }

}

fileprivate final class MockPersonFetchedResultsControllerDelegate: FetchedResultsControllerDelegate {

  var didChangeObject: ((FetchedResultsController<Person>, FetchedResultsObjectChange<Person>) -> Void)?
  var didChangeSection: ((FetchedResultsController<Person>, FetchedResultsSectionChange<Person>) -> Void)?
  var willChangeContent: ((FetchedResultsController<Person>) -> Void)?
  var didChangeContent: ((FetchedResultsController<Person>) -> Void)?
  var didPerformFetch: ((FetchedResultsController<Person>) -> Void)?

  func fetchedResultsController(_ controller: FetchedResultsController<Person>, didChangeObject change: FetchedResultsObjectChange<Person>) {
    didChangeObject?(controller, change)
  }

  func fetchedResultsController(_ controller: FetchedResultsController<Person>, didChangeSection change: FetchedResultsSectionChange<Person>) {
    didChangeSection?(controller, change)
  }

  func fetchedResultsControllerWillChangeContent(_ controller: FetchedResultsController<Person>) {
    willChangeContent?(controller)
  }

  func fetchedResultsControllerDidChangeContent(_ controller: FetchedResultsController<Person>) {
    didChangeContent?(controller)
  }

  func fetchedResultsControllerDidPerformFetch(_ controller: FetchedResultsController<Person>) {
    didPerformFetch?(controller)
  }

}
