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

@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.12, *)
class NSManagedObjectContextHistoryTests: XCTestCase {
  // MARK: - History by Date
  
  func testMergeHistoryAfterDate() throws {
    // Given
    let id = UUID()
    let container1 = OnDiskPersistentContainer.makeNew(id: id)
    let container2 = OnDiskPersistentContainer.makeNew(id: id)
    let expectation1 = expectation(description: "\(#function)\(#line)")
    
    let viewContext1 = container1.viewContext
    viewContext1.name = "viewContext1"
    let viewContext2 = container2.viewContext
    viewContext2.name = "viewContext2"
    
    viewContext1.fillWithSampleData()
    
    try viewContext1.save()
    
    XCTAssertFalse(viewContext1.registeredObjects.isEmpty)
    XCTAssertTrue(viewContext2.registeredObjects.isEmpty)
    
    // When, Then
    let token = viewContext2.addManagedObjectContextObjectsDidChangeNotificationObserver { notification in
      XCTAssertEqual(notification.insertedObjects.count, 145)
      expectation1.fulfill()
    }
    
    let date = try viewContext2.mergeHistory(after: .distantPast)
    XCTAssertNotNil(date)
    XCTAssertTrue(viewContext2.registeredObjects.isEmpty)
    
    waitForExpectations(timeout: 5, handler: nil)
    NotificationCenter.default.removeObserver(token)
    let status = try viewContext2.deleteHistory(before: date!)
    XCTAssertTrue(status)
    
    // cleaning avoiding SQLITE warnings
    let psc1 = viewContext1.persistentStoreCoordinator!
    try psc1.persistentStores.forEach { store in
      try psc1.remove(store)
    }
    
    let psc2 = viewContext2.persistentStoreCoordinator!
    try psc2.persistentStores.forEach { store in
      try psc2.remove(store)
    }
    
    try container1.destroy()
  }
  
  func testMergeHistoryAfterDateWithMultipleTransactions() throws {
    // Given
    let id = UUID()
    let container1 = OnDiskPersistentContainer.makeNew(id: id)
    let container2 = OnDiskPersistentContainer.makeNew(id: id)
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    
    let viewContext1 = container1.viewContext
    viewContext1.name = "viewContext1"
    viewContext1.transactionAuthor = "\(#function)"
    let viewContext2 = container2.viewContext
    viewContext2.name = "viewContext2"
    
    let person1 = Person(context: viewContext1)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"
    
    let person2 = Person(context: viewContext1)
    person2.firstName = "Ellis"
    person2.lastName = "Khoury"
    
    try viewContext1.save()
    
    // When, Then
    
    // we don't care about the first insert because viewContext2 will fetch everything from the the db
    try viewContext1.deleteHistory(before: .distantFuture)
    
    let persons = try Person.fetch(in: viewContext2)
    // materialize all the objects to listen to updates/merges in addition to inserts and deletes
    try persons.materializeFaultedObjects()
    XCTAssertEqual(persons.count, 2)
    
    let person3 = Person(context: viewContext1)
    person3.firstName = "Faron"
    person3.lastName = "Moreton"
    
    let person4 = Person(context: viewContext1)
    person4.firstName = "Darin"
    person4.lastName = "Meadow"
    
    let person5 = Person(context: viewContext1)
    person5.firstName = "Juliana"
    person5.lastName = "Pyke"
    
    try viewContext1.save() // 3 inserts
    
    person1.firstName = person1.firstName + "*"
    
    try viewContext1.save() // 1 update
    
    person2.delete()
    
    try viewContext1.save() // 1 delete
    
    let token = viewContext2.addManagedObjectContextObjectsDidChangeNotificationObserver { notification in
      let context = notification.managedObjectContext
      XCTAssertTrue(context === viewContext2)
      if !notification.insertedObjects.isEmpty {
        expectation1.fulfill()
      } else if !notification.updatedObjects.isEmpty || !notification.refreshedObjects.isEmpty {
        expectation2.fulfill()
      } else if !notification.deletedObjects.isEmpty {
        expectation3.fulfill()
      }
    }
    
    let date = try viewContext2.mergeHistory(after: .distantPast)
    XCTAssertNotNil(date)
    waitForExpectations(timeout: 5, handler: nil)
    
    try viewContext2.save()
    print(viewContext2.insertedObjects)
    
    NotificationCenter.default.removeObserver(token)
    let status = try viewContext2.deleteHistory(before: date!)
    XCTAssertTrue(status)
    
    // cleaning avoiding SQLITE warnings
    let psc1 = viewContext1.persistentStoreCoordinator!
    try psc1.persistentStores.forEach { store in
      try psc1.remove(store)
    }
    
    let psc2 = viewContext2.persistentStoreCoordinator!
    try psc2.persistentStores.forEach { store in
      try psc2.remove(store)
    }
    
    try container1.destroy()
  }
  
  func testProcessHistoryAfterDate() throws {
    // Given
    let id = UUID()
    let container1 = OnDiskPersistentContainer.makeNew(id: id)
    let container2 = OnDiskPersistentContainer.makeNew(id: id)
    
    let viewContext1 = container1.viewContext
    viewContext1.name = "viewContext1"
    let viewContext2 = container2.viewContext
    viewContext2.name = "viewContext2"
    
    viewContext1.fillWithSampleData()
    
    try viewContext1.save()
    
    // When, Then
    XCTAssertFalse(viewContext1.registeredObjects.isEmpty)
    XCTAssertTrue(viewContext2.registeredObjects.isEmpty)
    
    var inserts = [NSManagedObjectID]()
    try viewContext2.processHistory(after: .distantPast, transactionHandler: { transaction in
      transaction.changes?.forEach { (change) in
        switch change.changeType {
        case .delete:
          XCTFail("There shouldn't be deletions")
        case .insert:
          inserts.append(change.changedObjectID)
          XCTAssertNil(change.updatedProperties)
        case .update:
          XCTFail("There shouldn't be updates")
        @unknown default:
          XCTFail("Unmanaged case")
        }
      }
    })
    
    XCTAssertEqual(inserts.count, 145)
    
    // cleaning avoiding SQLITE warnings
    let psc1 = viewContext1.persistentStoreCoordinator!
    try psc1.persistentStores.forEach { store in
      try psc1.remove(store)
    }
    
    let psc2 = viewContext2.persistentStoreCoordinator!
    try psc2.persistentStores.forEach { store in
      try psc2.remove(store)
    }
    
    try container1.destroy()
  }
  
  // MARK: - History by Token
  
  func testMergeHistoryAfterNilTokenWithoutAnyHistoryChanges() throws {
    let container1 = OnDiskPersistentContainer.makeNew()
    let stores = container1.persistentStoreCoordinator.persistentStores
    XCTAssertEqual(stores.count, 1)
    let store = stores.first!
    if #available(iOS 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, *) {
      let currentToken = container1.persistentStoreCoordinator.currentPersistentHistoryToken(fromStores: [store])
      XCTAssertNil(currentToken)
    }
    let token = try container1.viewContext.mergeHistory(after: nil)
    XCTAssertNil(token)
    try container1.destroy()
  }
  
  func testMergeHistoryAfterNilToken() throws {
    // Given
    let id = UUID()
    let container1 = OnDiskPersistentContainer.makeNew(id: id)
    let container2 = OnDiskPersistentContainer.makeNew(id: id)
    let expectation1 = expectation(description: "\(#function)\(#line)")
    
    let viewContext1 = container1.viewContext
    viewContext1.name = "viewContext1"
    let viewContext2 = container2.viewContext
    viewContext2.name = "viewContext2"
    
    viewContext1.fillWithSampleData()
    
    try viewContext1.save()
    
    // When, Then
    let token = viewContext2.addManagedObjectContextObjectsDidChangeNotificationObserver { notification in
      XCTAssertEqual(notification.insertedObjects.count, 145)
      expectation1.fulfill()
    }
    
    let historyToken = try viewContext2.mergeHistory(after: nil)
    XCTAssertNotNil(token)
    XCTAssertTrue(viewContext2.registeredObjects.isEmpty)
    
    waitForExpectations(timeout: 5, handler: nil)
    NotificationCenter.default.removeObserver(token)
    let status = try viewContext2.deleteHistory(before: historyToken)
    XCTAssertTrue(status)
    
    // cleaning avoiding SQLITE warnings
    let psc1 = viewContext1.persistentStoreCoordinator!
    try psc1.persistentStores.forEach { store in
      try psc1.remove(store)
    }
    
    let psc2 = viewContext2.persistentStoreCoordinator!
    try psc2.persistentStores.forEach { store in
      try psc2.remove(store)
    }
    
    try container1.destroy()
  }
  
  func testMergeHistoryAfterToken() throws {
    // Given
    let id = UUID()
    let container1 = OnDiskPersistentContainer.makeNew(id: id)
    let container2 = OnDiskPersistentContainer.makeNew(id: id)
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    
    let viewContext1 = container1.viewContext
    viewContext1.name = "viewContext1"
    let viewContext2 = container2.viewContext
    viewContext2.name = "viewContext2"
    viewContext1.transactionAuthor = "\(#function)"
    
    // When, Then
    var run = 0
    
    var lastToken: NSPersistentHistoryToken?
    let token1 = viewContext1.addManagedObjectContextDidSaveNotificationObserver { notification in
      if run == 0 {
        guard let historyToken = notification.historyToken else {
          XCTFail("A didSave notification should contain an history token") // the option for history token is enabled
          return
        }
        do {
          let token = try viewContext2.mergeHistory(after: nil) // from the start till the last token
          XCTAssertEqual(token, historyToken)
          lastToken = token
        } catch {
          XCTFail(error.localizedDescription)
        }
        run += 1
      } else if run == 1 {
        guard let historyToken = notification.historyToken, let lastToken = lastToken else {
          XCTFail("A didSave notification should contain an history token") // the option for history token is enabled
          return
        }
        
        // This is how when can retrive a token after a save directly from a store
        if #available(iOS 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, *) {
          if let store = container2.persistentStoreCoordinator.persistentStores.first {
            let lastHistoryToken = container2.persistentStoreCoordinator.currentPersistentHistoryToken(fromStores: [store])
            XCTAssertEqual(lastHistoryToken, historyToken)
          }
        }
        
        let token = try! viewContext2.mergeHistory(after: lastToken)
        XCTAssertEqual(token, historyToken)
      } else {
        XCTFail("Error")
      }
    }
    
    let token2 = viewContext2.addManagedObjectContextObjectsDidChangeNotificationObserver { notification in
      if run == 0 {
        XCTAssertEqual(notification.insertedObjects.count, 2)
        expectation1.fulfill()
      } else if run == 1 {
        XCTAssertEqual(notification.insertedObjects.count, 1)
        expectation2.fulfill()
      } else {
        XCTFail("Error")
      }
    }
    
    // run 0
    let person1 = Person(context: viewContext1)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"
    
    let person2 = Person(context: viewContext1)
    person2.firstName = "Ellis"
    person2.lastName = "Khoury"
    try viewContext1.save()
    
    // run 1
    let person3 = Person(context: viewContext1)
    person3.firstName = "Faron"
    person3.lastName = "Moreton"
    try viewContext1.save()
    
    waitForExpectations(timeout: 5, handler: nil)
    NotificationCenter.default.removeObserver(token1)
    NotificationCenter.default.removeObserver(token2)
    
    // cleaning avoiding SQLITE warnings
    let psc1 = viewContext1.persistentStoreCoordinator!
    try psc1.persistentStores.forEach { store in
      try psc1.remove(store)
    }
    
    let psc2 = viewContext2.persistentStoreCoordinator!
    try psc2.persistentStores.forEach { store in
      try psc2.remove(store)
    }
    
    try container1.destroy()
  }
  
  func testPersistentHistoryTrackingEnabledGenerateHistoryTokens() throws {
    // Given
    let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
    let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
    let storeURL = urls.first!.appendingPathComponent("org.tinrobots.CoreDataPlusTests").appendingPathComponent("\(UUID().uuidString).sqlite")
    let options: [AnyHashable: Any] = [NSPersistentHistoryTrackingKey: true as NSNumber] // enable History Tracking
    try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = psc
    
    // When, Then
    let token = context.addManagedObjectContextDidSaveNotificationObserver { notification in
      XCTAssertNotNil(notification.historyToken)
      expectation1.fulfill()
    }
    
    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"
    
    try context.save()
    waitForExpectations(timeout: 5, handler: nil)
    NotificationCenter.default.removeObserver(token)
    
    // cleaning avoiding SQLITE warnings
    try psc.persistentStores.forEach {
      try psc.remove($0)
    }
    try NSPersistentStoreCoordinator.destroyStore(at: storeURL)
  }
  
  func testPersistentHistoryTrackingDisabledDoesntGenerateHistoryTokens() throws {
    // Given
    let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
    let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
    let storeURL = urls.first!.appendingPathComponent("org.tinrobots.CoreDataPlusTests").appendingPathComponent("\(UUID().uuidString).sqlite")
    try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = psc
    
    // When, Then
    let token = context.addManagedObjectContextDidSaveNotificationObserver { notification in
      XCTAssertNil(notification.historyToken)
      expectation1.fulfill()
    }
    
    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"
    
    try context.save()
    waitForExpectations(timeout: 5, handler: nil)
    NotificationCenter.default.removeObserver(token)
    
    // cleaning avoiding SQLITE warnings
    try psc.persistentStores.forEach {
      try psc.remove($0)
    }
    try NSPersistentStoreCoordinator.destroyStore(at: storeURL)
  }
  
  func testProcessHistoryAfterToken() throws {
    // Given
    let id = UUID()
    let container1 = OnDiskPersistentContainer.makeNew(id: id)
    let container2 = OnDiskPersistentContainer.makeNew(id: id)
    
    let viewContext1 = container1.viewContext
    viewContext1.name = "viewContext1"
    let viewContext2 = container2.viewContext
    viewContext2.name = "viewContext2"
    
    let car = Car(context: viewContext1)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = "1"
    car.maker = "123!"
    
    let person1 = Person(context: viewContext1)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"
    
    try viewContext1.save()
    let lastToken1 = try viewContext2.mergeHistory(after: nil)
    let cars = try Car.fetch(in: viewContext2)
    try cars.materializeFaultedObjects()
    let persons = try Person.fetch(in: viewContext2)
    try persons.materializeFaultedObjects()
    XCTAssertEqual(cars.count, 1)
    XCTAssertEqual(persons.count, 1)
    
    
    car.maker = "*FIAT*"
    person1.firstName += "*Edythe*"
    car.owner = person1
    
    try viewContext1.save()
    
    // When, Then
    var changes = 0
    var lastToken2: NSPersistentHistoryToken?
    try viewContext2.processHistory(after: lastToken1, transactionHandler: { transaction in
      lastToken2 = transaction.token
      transaction.changes?.forEach { (change) in
        switch change.changeType {
        case .delete:
          XCTFail("There shouldn't be deletions")
        case .insert:
          XCTFail("There shouldn't be insertions")
        case .update:
          changes += 1
        @unknown default:
          XCTFail("Unmanaged case")
        }
      }
    })
    
    XCTAssertEqual(changes, 2)
    XCTAssertNotNil(lastToken2)
    
    let person1Id = person1.id
    person1.delete()
    car.delete()
    try viewContext1.save()
    
    var deletions = 0
    try viewContext2.processHistory(after: lastToken2, transactionHandler: { transaction in
      try transaction.changes?.forEach { (change) in
        switch change.changeType {
        case .delete:
          let id = change.changedObjectID
          let object = try viewContext2.existingObject(with: id)
          if let _ = object as? Car {
            XCTAssertNil(change.tombstone)
            deletions += 1
          } else if let _ = object as? Person {
            XCTAssertNotNil(change.tombstone)
            if let id = change.tombstone![#keyPath(Person.id)] as? UUID {
              XCTAssertEqual(id, person1Id)
            } else {
              XCTFail("Unexpected tombstone value, only Person id should persisted after deletion.")
            }
            
            deletions += 1
          } else {
            XCTFail("Unexpected deletion")
          }
        case .insert:
          XCTFail("There shouldn't be insertions")
        case .update:
          XCTFail("There shouldn't be updates")
        @unknown default:
          XCTFail("Unmanaged case")
        }
      }
    })
    
    XCTAssertEqual(deletions, 2)
    
    // cleaning avoiding SQLITE warnings
    let psc1 = viewContext1.persistentStoreCoordinator!
    try psc1.persistentStores.forEach { store in
      try psc1.remove(store)
    }
    
    let psc2 = viewContext2.persistentStoreCoordinator!
    try psc2.persistentStores.forEach { store in
      try psc2.remove(store)
    }
    
    try container1.destroy()
  }
}
