// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

@available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
final class NSManagedObjectContextHistoryTests: XCTestCase {
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
    let cancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewContext2)
      .sink { _ in
        expectation1.fulfill()
    }

    let transactionsFromDistantPast = try viewContext2.historyTransactions(after: .distantPast)
    let allTransactions = try viewContext2.historyTransactions(after: .distantPast)
    XCTAssertEqual(transactionsFromDistantPast.count, allTransactions.count)
    XCTAssertEqual(transactionsFromDistantPast.count, 1)

    let date = try viewContext2.mergeHistory(after: .distantPast)
    XCTAssertNotNil(date)
    XCTAssertTrue(viewContext2.registeredObjects.isEmpty)

    waitForExpectations(timeout: 5, handler: nil)
    cancellable.cancel()
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
    try persons.materializeFaults()
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

    let cancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewContext2)
      .map { ManagedObjectContextObjectsDidChange(notification: $0) }
      .sink { payload in
        XCTAssertTrue(payload.managedObjectContext === viewContext2)
        if !payload.insertedObjects.isEmpty {
          expectation1.fulfill()
        } else if !payload.updatedObjects.isEmpty || !payload.refreshedObjects.isEmpty {
          expectation2.fulfill()
        } else if !payload.deletedObjects.isEmpty {
          expectation3.fulfill()
        }
    }

    let transactionsFromDistantPast = try viewContext2.historyTransactions(after: .distantPast)
    let allTransactions = try viewContext2.historyTransactions(after: .distantPast)
    XCTAssertEqual(transactionsFromDistantPast.count, allTransactions.count)
    XCTAssertEqual(transactionsFromDistantPast.count, 3)

    let date = try viewContext2.mergeHistory(after: .distantPast)
    XCTAssertNotNil(date)
    waitForExpectations(timeout: 5, handler: nil)

    try viewContext2.save()
    print(viewContext2.insertedObjects)

    cancellable.cancel()
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

  func testProcessHistoryWithMultipleTransactionsAfterDate() throws {
    // Given
    let id = UUID()
    let container1 = OnDiskPersistentContainer.makeNew(id: id)
    let container2 = OnDiskPersistentContainer.makeNew(id: id)

    let viewContext1 = container1.viewContext
    viewContext1.name = "viewContext1"
    let viewContext2 = container2.viewContext
    viewContext2.name = "viewContext2"

    let person1 = Person(context: viewContext1)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    try viewContext1.save()

    let person2 = Person(context: viewContext1)
    person2.firstName = "Ellis"
    person2.lastName = "Khoury"

    try viewContext1.save()

    let person3 = Person(context: viewContext1)
    person3.firstName = "Faron"
    person3.lastName = "Moreton"

    try viewContext1.save()

    // When, Then
    var transactions = [Int64:Int]()
    try viewContext2.processHistory(after: .distantPast, transactionHandler: { transaction in
      let insertionsPerTransaction = transaction.changes?.filter { $0.changeType == .insert }.count ?? 0
      transactions[transaction.transactionNumber] = insertionsPerTransaction
    })

    // Expecting 3 transactions with 1 insert each.
    XCTAssertEqual(transactions.keys.count, 3)
    transactions.forEach { (_, value: Int) in
      XCTAssertEqual(value, 1)
    }

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

    let currentToken = container1.persistentStoreCoordinator.currentPersistentHistoryToken(fromStores: stores)

    // it's a new store, there shouldn't be any transactions
    let transactions = try container1.viewContext.historyTransactions(after: nil)
    XCTAssertTrue(transactions.isEmpty)

    XCTAssertNotNil(currentToken)
    let token = try container1.viewContext.mergeHistory(after: currentToken)
    XCTAssertNil(token)

    let token2 = try container1.viewContext.mergeHistory(after: nil)
    XCTAssertNil(token2)
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
    let cancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewContext2)
      .sink { _ in
        expectation1.fulfill()
    }

    let historyToken = try viewContext2.mergeHistory(after: nil)
    XCTAssertNotNil(historyToken)
    XCTAssertTrue(viewContext2.registeredObjects.isEmpty)

    waitForExpectations(timeout: 5, handler: nil)
    cancellable.cancel()
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

    var lastMergedToken: NSPersistentHistoryToken?
    let cancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: viewContext1)
      .map { ManagedObjectContextDidSaveObjects(notification: $0) }
      .sink { payload in
        if run == 0 {
          guard let historyToken = payload.historyToken else {
            XCTFail("A didSave notification should contain an history token") // the option for history token is enabled
            return
          }
          do {
            let transactions = try viewContext2.historyTransactions(after: nil)
            XCTAssertEqual(transactions.count, 1, "After the first save there should be only 1 history transaction")
            let transactionsAfterTheNewestToken = try! viewContext2.historyTransactions(after: historyToken)
            XCTAssertTrue(transactionsAfterTheNewestToken.isEmpty, "There shouldn't be any new transactions after the newest token.")
            lastMergedToken = try viewContext2.mergeHistory(after: nil) // from the start til the last token
          } catch {
            XCTFail(error.localizedDescription)
          }
          run += 1
        } else if run == 1 {
          guard let historyToken = payload.historyToken, let lastToken = lastMergedToken else {
            XCTFail("A didSave notification should contain an history token") // the option for history token is enabled
            return
          }

          // This is how when can retrive a token after a save directly from a store

          let stores = container2.persistentStoreCoordinator.persistentStores
          let lastHistoryToken = container2.persistentStoreCoordinator.currentPersistentHistoryToken(fromStores: stores)
          let transactionsAfterTheLastUsedToken = try! viewContext2.historyTransactions(after: lastToken)
          XCTAssertEqual(transactionsAfterTheLastUsedToken.count, 1)
          let transactionsAfterTheNewestToken = try! viewContext2.historyTransactions(after: lastHistoryToken)
          XCTAssertTrue(transactionsAfterTheNewestToken.isEmpty, "There shouldn't be any new transactions after the newest token.")


          let token = try! viewContext2.mergeHistory(after: lastToken)
          XCTAssertEqual(token, historyToken)
        } else {
          XCTFail("Error")
        }
    }

    let cancellable2 = NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewContext2).map { ManagedObjectContextObjectsDidChange(notification: $0)}
      .sink { payload in
        if run == 0 {
          XCTAssertEqual(payload.insertedObjects.count, 2)
          expectation1.fulfill()
        } else if run == 1 {
          XCTAssertEqual(payload.insertedObjects.count, 1)
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
    cancellable.cancel()
    cancellable2.cancel()

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
    let storeURL = URL.newDatabaseURL(withID: UUID())
    let options: [AnyHashable: Any] = [NSPersistentHistoryTrackingKey: true as NSNumber] // enable History Tracking
    try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = psc

    // When, Then
    let cancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: context)
      .map { ManagedObjectContextDidSaveObjects(notification: $0) }
      .sink { payload in
        XCTAssertNotNil(payload.historyToken)
        expectation1.fulfill()
    }

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    try context.save()
    waitForExpectations(timeout: 5, handler: nil)
    cancellable.cancel()

    // cleaning avoiding SQLITE warnings
    try psc.persistentStores.forEach {
      try psc.remove($0)
    }
    try NSPersistentStoreCoordinator.destroyStore(at: storeURL)
  }

  func testPersistentHistoryTrackingDisabledDoesntGenerateHistoryTokens() throws {
    // Given
    let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
    let storeURL = URL.newDatabaseURL(withID: UUID())
    try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = psc

    // When, Then
    let cancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: context)
      .map { ManagedObjectContextDidSaveObjects(notification: $0) }
      .sink { payload in
        XCTAssertNil(payload.historyToken, "The Persistent Store Coordianator doesn't have the NSPersistentStoreRemoteChangeNotificationPostOptionKey option enabled.")
        expectation1.fulfill()
    }

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    try context.save()
    waitForExpectations(timeout: 5, handler: nil)
    cancellable.cancel()

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
    try cars.materializeFaults()
    let persons = try Person.fetch(in: viewContext2)
    try persons.materializeFaults()
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

  // MARK: - History by Transaction

  func testFetchHistoryChangesUsingFetchRequest() throws {
    // Given
    let id = UUID()
    let container1 = OnDiskPersistentContainer.makeNew(id: id)
    let container2 = OnDiskPersistentContainer.makeNew(id: id)

    let viewContext1 = container1.viewContext
    viewContext1.name = "viewContext1"
    viewContext1.transactionAuthor = "author1"
    let viewContext2 = container2.viewContext
    viewContext2.name = "viewContext2"
    viewContext2.transactionAuthor = "author2"

    let lastHistoryToken = try XCTUnwrap(container2.persistentStoreCoordinator.currentPersistentHistoryToken(fromStores: viewContext2.persistentStores))

    viewContext1.fillWithSampleData()

    try viewContext1.save()

    let newHistoryToken = try XCTUnwrap(container2.persistentStoreCoordinator.currentPersistentHistoryToken(fromStores: viewContext2.persistentStores))

    let tokenGreaterThanLastHistoryTokenPredicate = NSPredicate(format: "%@ < token", lastHistoryToken)
    let tokenGreaterThanNewHistoryTokenPredicate = NSPredicate(format: "%@ < token", newHistoryToken)
    let notAuthor2Predicate = NSPredicate(format: "author != %@", "author2")
    let notAuthor1Predicate = NSPredicate(format: "author != %@", "author1")

    do {
      let predicate = NSCompoundPredicate(type: .and, subpredicates: [tokenGreaterThanLastHistoryTokenPredicate, notAuthor1Predicate])
      let allTransactions = try viewContext2.historyTransactions(where: predicate)
      XCTAssertTrue(allTransactions.isEmpty)
      try viewContext2.processHistory(where: predicate) { transaction in
        XCTFail("There shouldn't be any transactions matching \(predicate) to process")
      }

      let result = try viewContext2.mergeHistory(where: predicate)
      XCTAssertFalse(result)
    }

    do {
      let predicate = tokenGreaterThanNewHistoryTokenPredicate
      let allTransactions = try viewContext2.historyTransactions(where: predicate)
      XCTAssertTrue(allTransactions.isEmpty)
      try viewContext2.processHistory(where: predicate) { transaction in
        XCTFail("There shouldn't be any transactions matching \(predicate) to process")
      }

      let result = try viewContext2.mergeHistory(where: predicate)
      XCTAssertFalse(result)
    }

    do {
      let predicate = NSCompoundPredicate(type: .and, subpredicates: [tokenGreaterThanLastHistoryTokenPredicate, notAuthor2Predicate])
      let allTransactions = try viewContext2.historyTransactions(where: predicate)
      XCTAssertFalse(allTransactions.isEmpty)

      var count = 0
      try viewContext2.processHistory(where: predicate) { transaction in
        count += 1
      }
      XCTAssertEqual(allTransactions.count, count)
      let result = try viewContext2.mergeHistory(where: predicate)
      XCTAssertTrue(result)
    }

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

  func testInvestigationHistoryFetches() throws {
    // Given
    let id = UUID()
    let container1 = OnDiskPersistentContainer.makeNew(id: id)
    let container2 = OnDiskPersistentContainer.makeNew(id: id)

    let viewContext1 = container1.viewContext
    viewContext1.name = "viewContext1"
    viewContext1.transactionAuthor = "author1"
    let viewContext2 = container2.viewContext
    viewContext2.name = "viewContext2"
    viewContext2.transactionAuthor = "author2"

    var tokens = [NSPersistentHistoryToken]()

    let initialToken = try XCTUnwrap(container2.persistentStoreCoordinator.currentPersistentHistoryToken(fromStores: viewContext1.persistentStores))
    tokens.append(initialToken)

    // Transaction #1 - 2 Cars, 1 SportCar
    let car1 = Car(context: viewContext1)
    car1.maker = "FIAT"
    car1.model = "Panda"
    car1.numberPlate = "1"

    let car2 = Car(context: viewContext1)
    car2.maker = "FIAT"
    car2.model = "Punto"
    car2.numberPlate = "2"

    let sportCar1 = SportCar(context: viewContext1)
    sportCar1.maker = "McLaren"
    sportCar1.model = "570GT"
    sportCar1.numberPlate = "3"

    try viewContext1.save()
    let token1 = try XCTUnwrap(container2.persistentStoreCoordinator.currentPersistentHistoryToken(fromStores: viewContext1.persistentStores))
    tokens.append(token1)

    // Transaction #2 - 1 Person
    let person = Person(context: viewContext1)
    person.firstName = "Alessandro"
    person.lastName = "Marzoli"

    try viewContext1.save()
    let token2 = try XCTUnwrap(container2.persistentStoreCoordinator.currentPersistentHistoryToken(fromStores: viewContext1.persistentStores))
    tokens.append(token2)

    // Transaction #3 - 1 Person updated, 1 Car deleted
    person.firstName = "Alex"
    car2.delete()

    try viewContext1.save()
    let token3 = try XCTUnwrap(container2.persistentStoreCoordinator.currentPersistentHistoryToken(fromStores: viewContext1.persistentStores))
    tokens.append(token3)

    XCTAssertEqual(tokens.count, 4)

    let currentToken = try XCTUnwrap(container2.persistentStoreCoordinator.currentPersistentHistoryToken(fromStores: viewContext2.persistentStores))

    let lastToken = try XCTUnwrap(tokens.last)
    let secondLastToken = try XCTUnwrap(tokens.suffix(2).first)
    XCTAssertEqual(lastToken, currentToken)

    do {
      // ⏺ Query the Transaction entity
      let transactionsRequest = NSFetchRequest.historyTransationFetchRequest(with: viewContext1)!
      transactionsRequest.predicate = NSPredicate(format: "token > %@", secondLastToken)
      // same as:
      //transactionsRequest.predicate = NSPredicate(format: "token == %@", lastToken)

      let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(withFetch: transactionsRequest)
      historyFetchRequest.resultType = .transactionsOnly

      let transactions = try viewContext2.performAndWaitResult { context ->[NSPersistentHistoryTransaction] in
        // swiftlint:disable force_cast
        let history = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
        let transactions = history.result as! [NSPersistentHistoryTransaction] // ordered from the oldest to the most recent
        // swiftlint:enable force_cast
        return transactions
      }
      XCTAssertEqual(transactions.count, 1)
      let first = try XCTUnwrap(transactions.first)
      XCTAssertEqual(first.token, tokens.last)
      XCTAssertNil(first.changes) // result type is transactionsOnly
    } catch {
      throw NSError.fetchFailed(underlyingError: error)
    }

    do {
      // ⏺ Query the Change entity

      let changesRequest = NSFetchRequest.historyChangeFetchRequest(with: viewContext1)!
      changesRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
        NSPredicate(format: "changeType == %d", NSPersistentHistoryChangeType.update.rawValue), // Change condition
        // ⚠️ Even if it seems that some Transaction fields like "token" can be used here, the behavior is not predicatble
        // it's best if we stick with Change fields
        // NSPredicate(format: "token > %@", secondLastToken) // Transaction condition (working)
        // NSPredicate(format: "token == %@") // Transaction condition (not working)
        // NSPredicate(format: "author != %@", "author1") // Transaction condition (exception)
      ])

      let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(withFetch: changesRequest)
      historyFetchRequest.resultType = .transactionsAndChanges

      let transactions = try viewContext2.performAndWaitResult { context ->[NSPersistentHistoryTransaction] in
        let history = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
        let transactions = history.result as! [NSPersistentHistoryTransaction] // ordered from the oldest to the most recent
        return transactions
      }

      XCTAssertEqual(transactions.count, 1)
      let first = try XCTUnwrap(transactions.first)
      XCTAssertEqual(first.token, tokens.last)
      let changes = try XCTUnwrap(first.changes)
      XCTAssertFalse(changes.isEmpty) // result type is transactionsAndChanges
    } catch {
      throw NSError.fetchFailed(underlyingError: error)
    }

    do {
      // ⏺ Query the Change entity
      let changesRequest = NSFetchRequest.historyChangeFetchRequest(with: viewContext1)!
      changesRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
        NSPredicate(format: "changeType == %d", NSPersistentHistoryChangeType.insert.rawValue),
        NSPredicate(format: "changedEntity == %@ || changedEntity == %@", Car.entity(), Person.entity()) // ignores sub entities
      ])

      let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(withFetch: changesRequest)
      historyFetchRequest.resultType = .changesOnly // ⚠️ impact the return type

      let changes = try viewContext2.performAndWaitResult { context ->[NSPersistentHistoryChange] in
        let history = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
        let changes = history.result as! [NSPersistentHistoryChange] // ordered from the oldest to the most recent
        return changes
      }

      XCTAssertEqual(changes.count, 3) // 2 Cars + 1 Person
    } catch {
      throw NSError.fetchFailed(underlyingError: error)
    }

    do {
      // ⏺ Query the Change entity
      let changeEntity = NSPersistentHistoryChange.entityDescription(with: viewContext1)!
      XCTAssertNil(changeEntity.attributesByName["changedObjectID"], "Shown on WWDC 2020 but currently nil.") // FB8353599
      let request = NSFetchRequest<NSFetchRequestResult>()
      request.entity = changeEntity
      let columnName = changeEntity.attributesByName["changedEntity"]!.name // WWDC 2020
      request.predicate = NSPredicate(format: "%K = %@", columnName, Car.entity())

      let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: secondLastToken)
      historyFetchRequest.fetchRequest = request
      historyFetchRequest.resultType = .changesOnly // ⚠️ impact the return type

      let changes = try viewContext2.performAndWaitResult { context ->[NSPersistentHistoryChange] in
        let history = try context.execute(historyFetchRequest) as! NSPersistentHistoryResult
        let changes = history.result as! [NSPersistentHistoryChange] // ordered from the oldest to the most recent
        return changes
      }

      XCTAssertEqual(changes.count, 1) // Car2 has been eliminated in the last token
      let first = try XCTUnwrap(changes.first)
      XCTAssertEqual(first.changedObjectID.uriRepresentation(), car2.objectID.uriRepresentation())
      XCTAssertEqual(first.changeType, NSPersistentHistoryChangeType.delete)
    } catch {
      throw NSError.fetchFailed(underlyingError: error)
    }
  }
}
