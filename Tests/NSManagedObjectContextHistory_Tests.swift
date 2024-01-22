// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
final class NSManagedObjectContextHistoryTests: BaseTestCase {

  func test_MergeHistoryAfterDate() throws {
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

    let transactionsFromDistantPast = try viewContext2.historyTransactions(using: NSPersistentHistoryChangeRequest.fetchHistory(after: .distantPast))
    XCTAssertEqual(transactionsFromDistantPast.count, 1)

    let result = try viewContext2.mergeTransactions(transactionsFromDistantPast)
    XCTAssertNotNil(result)
    XCTAssertTrue(viewContext2.registeredObjects.isEmpty)

    waitForExpectations(timeout: 5, handler: nil)
    cancellable.cancel()
    let status = try viewContext2.deleteHistory(before: result!.0)
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

  func test_MergeHistoryAfterDateWithMultipleTransactions() throws {
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

    let persons = try Person.fetchObjects(in: viewContext2)
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

    let transactionsFromDistantPast = try viewContext2.historyTransactions(using: NSPersistentHistoryChangeRequest.fetchHistory(after: .distantPast))
    XCTAssertEqual(transactionsFromDistantPast.count, 3)

    let result = try viewContext2.mergeTransactions(transactionsFromDistantPast)
    XCTAssertNotNil(result)
    waitForExpectations(timeout: 5, handler: nil)

    try viewContext2.save()
    print(viewContext2.insertedObjects)

    cancellable.cancel()
    let status = try viewContext2.deleteHistory(before: result!.0)
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

  func test_MergeHistoryAfterNilTokenWithoutAnyHistoryChanges() throws {
    let container1 = OnDiskPersistentContainer.makeNew()
    let stores = container1.persistentStoreCoordinator.persistentStores
    XCTAssertEqual(stores.count, 1)

    let currentToken = container1.persistentStoreCoordinator.currentPersistentHistoryToken(fromStores: stores)

    // it's a new store, there shouldn't be any transactions
    let requestToken: NSPersistentHistoryToken? = nil
    let transactions = try container1.viewContext.historyTransactions(using: NSPersistentHistoryChangeRequest.fetchHistory(after: requestToken))
    XCTAssertTrue(transactions.isEmpty)

    XCTAssertNotNil(currentToken)
    let transactionsAfterCurrentToken = try container1.viewContext.historyTransactions(using: NSPersistentHistoryChangeRequest.fetchHistory(after: currentToken))
    let result = try container1.viewContext.mergeTransactions(transactionsAfterCurrentToken)
    XCTAssertNil(result)

    let result2 = try container1.viewContext.mergeTransactions(transactions)
    XCTAssertNil(result2)

    try container1.destroy()
  }

  func test_PersistentStoreWithHistoryTrackingEnabledGeneratesHistoryTokens() throws {
    // Given
    let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
    let storeURL = URL.newDatabaseURL(withID: UUID())
    let options: PersistentStoreOptions = [NSPersistentHistoryTrackingKey: true as NSNumber] // enable History Tracking
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

    let result = try context.deleteHistory()
    XCTAssertTrue(result)

    // cleaning avoiding SQLITE warnings
    try psc.persistentStores.forEach {
      try psc.remove($0)
    }
    try NSPersistentStoreCoordinator.destroyStore(at: storeURL)
  }

  func test_PersistentStoreWithHistoryTrackingDisabledDoesntGenerateHistoryTokens() throws {
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
        XCTAssertNil(payload.historyToken, "The Persistent Store Coordinator doesn't have the NSPersistentStoreRemoteChangeNotificationPostOptionKey option enabled.")
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

  func test_DeleteHistoryAfterTransaction() throws {
    let container = OnDiskPersistentContainer.makeNew()
    let viewContext = container.viewContext

    // Transaction #1
    let car1 = Car(context: viewContext)
    car1.maker = "FIAT"
    car1.model = "Panda"
    car1.numberPlate = "1"

    try viewContext.save()

    // Transaction #2
    let car2 = Car(context: viewContext)
    car2.maker = "FIAT"
    car2.model = "Punto"
    car2.numberPlate = "2"

    try viewContext.save()

    let transactions1 = try viewContext.historyTransactions(using: NSPersistentHistoryChangeRequest.fetchHistory(after: .distantPast))
    XCTAssertEqual(transactions1.count, 2)
    let firstTransaction1 = try XCTUnwrap(transactions1.first)
    // Removes all the transactions before the first one: no transactions are actually deleted
    let result1 = try XCTUnwrap(try viewContext.deleteHistory(before: firstTransaction1))
    XCTAssertTrue(result1)

    let transactions2 = try viewContext.historyTransactions(using: NSPersistentHistoryChangeRequest.fetchHistory(after: .distantPast))
    XCTAssertEqual(transactions2.count, 2)
    let lastTransaction2 = try XCTUnwrap(transactions2.last)
    // Removes all the transactions before the last one: 1 transaction gets deleted
    let result2 = try XCTUnwrap(try viewContext.deleteHistory(before: lastTransaction2))
    XCTAssertTrue(result2)

    let transactions3 = try viewContext.historyTransactions(using: NSPersistentHistoryChangeRequest.fetchHistory(after: .distantPast))
    XCTAssertEqual(transactions3.count, 1)
  }

  func test_FetchHistoryChangesUsingFetchRequest() throws {
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
    let psc2 = container2.persistentStoreCoordinator

    let lastHistoryToken = try XCTUnwrap(psc2.currentPersistentHistoryToken(fromStores: psc2.persistentStores))

    viewContext1.fillWithSampleData()

    try viewContext1.save()

    let newHistoryToken = try XCTUnwrap(psc2.currentPersistentHistoryToken(fromStores: psc2.persistentStores))

    let tokenGreaterThanLastHistoryTokenPredicate = NSPredicate(format: "%@ < token", lastHistoryToken)
    let tokenGreaterThanNewHistoryTokenPredicate = NSPredicate(format: "%@ < token", newHistoryToken)
    let notAuthor2Predicate = NSPredicate(format: "author != %@", "author2")
    let notAuthor1Predicate = NSPredicate(format: "author != %@", "author1")

    func makeTransactionFetchRequest(predicate: NSPredicate) throws -> NSPersistentHistoryChangeRequest {
      let request = try XCTUnwrap(NSPersistentHistoryChangeRequest.makeTransactionFetchRequest(with: viewContext2))
      request.predicate = predicate
      let transactionsRequest = NSPersistentHistoryChangeRequest.fetchHistory(withFetch: request)
      transactionsRequest.resultType = .transactionsOnly
      return transactionsRequest
    }

    do {
      let predicate = NSCompoundPredicate(type: .and, subpredicates: [tokenGreaterThanLastHistoryTokenPredicate, notAuthor1Predicate])
      let request = try makeTransactionFetchRequest(predicate: predicate)
      let allTransactions = try viewContext2.historyTransactions(using: request)
      XCTAssertTrue(allTransactions.isEmpty)

      let result = try viewContext2.mergeTransactions(allTransactions)
      XCTAssertNil(result)
    }

    do {
      let predicate = tokenGreaterThanNewHistoryTokenPredicate
      let request = try makeTransactionFetchRequest(predicate: predicate)
      let allTransactions = try viewContext2.historyTransactions(using: request)
      XCTAssertTrue(allTransactions.isEmpty)
      XCTAssertTrue(allTransactions.isEmpty)

      let result = try viewContext2.mergeTransactions(allTransactions)
      XCTAssertNil(result)
    }

    do {
      let predicate = NSCompoundPredicate(type: .and, subpredicates: [tokenGreaterThanLastHistoryTokenPredicate, notAuthor2Predicate])
      let request = try makeTransactionFetchRequest(predicate: predicate)
      let allTransactions = try viewContext2.historyTransactions(using: request)
      XCTAssertFalse(allTransactions.isEmpty)

      let result = try viewContext2.mergeTransactions(allTransactions)
      XCTAssertNotNil(result)
    }

    // cleaning avoiding SQLITE warnings
    let psc1 = viewContext1.persistentStoreCoordinator!
    try psc1.persistentStores.forEach { store in
      try psc1.remove(store)
    }

    try psc2.persistentStores.forEach { store in
      try psc2.remove(store)
    }

    try container1.destroy()
  }

  func test_InvestigationHistoryFetches() throws {
    // Given
    let id = UUID()
    let container1 = OnDiskPersistentContainer.makeNew(id: id)
    let psc1 = container1.persistentStoreCoordinator
    let container2 = OnDiskPersistentContainer.makeNew(id: id)
    let psc2 = container2.persistentStoreCoordinator

    let viewContext1 = container1.viewContext
    viewContext1.name = "viewContext1"
    viewContext1.transactionAuthor = "author1"
    let viewContext2 = container2.viewContext
    viewContext2.name = "viewContext2"
    viewContext2.transactionAuthor = "author2"

    let changeEntityDescription = NSPersistentHistoryChange.entityDescription(with: viewContext1)!

    var tokens = [NSPersistentHistoryToken]()

    let initialToken = try XCTUnwrap(psc1.currentPersistentHistoryToken(fromStores: psc1.persistentStores))
    tokens.append(initialToken)

    // Transaction #1 - Added: 2 Cars, 1 SportCar
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
    let token1 = try XCTUnwrap(psc1.currentPersistentHistoryToken(fromStores: psc1.persistentStores))
    XCTAssertEqual(token1, psc2.currentPersistentHistoryToken(fromStores: psc2.persistentStores))
    tokens.append(token1)

    // Transaction #2 - Added: 1 Person
    let person = Person(context: viewContext1)
    let personObjectID = try person.obtainPermanentID()
    person.firstName = "Alessandro"
    person.lastName = "Marzoli"

    try viewContext1.save()

    let token2 = try XCTUnwrap(psc1.currentPersistentHistoryToken(fromStores: psc1.persistentStores))
    XCTAssertEqual(token2, psc2.currentPersistentHistoryToken(fromStores: psc2.persistentStores))
    tokens.append(token2)

    // Transaction #3 - Updated: 1 Person; Deleted: 1 Car
    person.firstName = "Alex"
    car2.delete()

    try viewContext1.save()
    let token3 = try XCTUnwrap(psc1.currentPersistentHistoryToken(fromStores: psc1.persistentStores))
    XCTAssertEqual(token3, psc2.currentPersistentHistoryToken(fromStores: psc2.persistentStores))
    tokens.append(token3)

    XCTAssertEqual(tokens.count, 4)

    let currentToken = try XCTUnwrap(psc1.currentPersistentHistoryToken(fromStores: psc1.persistentStores))
    XCTAssertEqual(currentToken, psc2.currentPersistentHistoryToken(fromStores: psc2.persistentStores))

    let lastToken = try XCTUnwrap(tokens.last)
    let secondLastToken = try XCTUnwrap(tokens.suffix(2).first)
    XCTAssertEqual(lastToken, currentToken)

    viewContext1.reset()

    do {
      // ⏺ Query the "Transaction" entity
      let predicate = NSPredicate(format: "%K > %@", #keyPath(NSPersistentHistoryTransaction.token), secondLastToken)
      let request = try XCTUnwrap(NSPersistentHistoryChangeRequest.makeTransactionFetchRequest(with: viewContext2))
      request.predicate = predicate
      let transactionRequest = NSPersistentHistoryChangeRequest.fetchHistory(withFetch: request)
      transactionRequest.resultType = .transactionsOnly

      let transactions = try viewContext2.performAndWait { _ ->[NSPersistentHistoryTransaction] in
        // swiftlint:disable force_cast
        let history = try viewContext2.execute(transactionRequest) as! NSPersistentHistoryResult
        let transactions = history.result as! [NSPersistentHistoryTransaction] // ordered from the oldest to the most recent
        // swiftlint:enable force_cast
        return transactions
      }

      XCTAssertEqual(transactions.count, 1)
      let first = try XCTUnwrap(transactions.first)
      XCTAssertEqual(first.token, tokens.last)
      XCTAssertNil(first.changes) // result type is transactionsOnly
    } catch {
      XCTFail("Querying the Transaction entity failed: \(error.localizedDescription)")
    }

    do {
      // ⏺ Query the "Change" entity by "changeType"
      let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
        NSPredicate(format: "changeType == %d", NSPersistentHistoryChangeType.update.rawValue), // Change condition
        // ⚠️ Even if it seems that some Transaction fields like "token" can be used here, the behavior is not predicatble
        // it's best if we stick with Change field names
        // NSPredicate(format: "token > %@", secondLastToken) // Transaction condition (working)
        // NSPredicate(format: "token == %@") // Transaction condition (not working)
        // NSPredicate(format: "author != %@", "author1") // Transaction condition (exception)
      ])

      let request = try XCTUnwrap(NSPersistentHistoryChangeRequest.makeChangeFetchRequest(with: viewContext2))
      request.predicate = predicate
      let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(withFetch: request)
      changeRequest.resultType = .transactionsAndChanges

      let transactions = try viewContext2.performAndWait { _ -> [NSPersistentHistoryTransaction] in
        let history = try viewContext2.execute(changeRequest) as! NSPersistentHistoryResult
        let transactions = history.result as! [NSPersistentHistoryTransaction] // ordered from the oldest to the most recent
        return transactions
      }

      XCTAssertEqual(transactions.count, 1)
      let first = try XCTUnwrap(transactions.first)
      XCTAssertEqual(first.token, tokens.last)
      let changes = try XCTUnwrap(first.changes)
      XCTAssertFalse(changes.isEmpty) // result type is transactionsAndChanges
    } catch {
      XCTFail("Querying the Change entity failed: \(error.localizedDescription)")
    }

    do {
      // ⏺ Query the "Change" entity by "changeType" and "changedEntity"
      let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
        NSPredicate(format: "changeType == %d", NSPersistentHistoryChangeType.insert.rawValue),
        NSPredicate(format: "changedEntity == %@ || changedEntity == %@", Car.entity(), Person.entity()) // ignores sub entities
      ])

      let request = try XCTUnwrap(NSPersistentHistoryChangeRequest.makeChangeFetchRequest(with: viewContext2))
      request.predicate = predicate
      let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(withFetch: request)
      changeRequest.resultType = .changesOnly

      let changes = try viewContext2.historyChanges(using: changeRequest)

      XCTAssertEqual(changes.count, 3) // 2 Cars + 1 Person
    } catch {
      XCTFail("Querying the Change entity failed: \(error.localizedDescription)")
    }

    do {
      // ⏺ Query the "Change" entity by "changedObjectID"
      // WWDC 2020, Core Data: Sundries and maxims; history pointers (16:09)
      // https://developer.apple.com/videos/play/wwdc2020/10017/
      if #available(iOS 15.0, iOSApplicationExtension 15.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, macOS 12, *) {
        let request = try XCTUnwrap(NSPersistentHistoryChangeRequest.makeChangeFetchRequest(with: viewContext1))
        let column = changeEntityDescription.attributesByName["changedObjectID"]!.name
        request.predicate = NSPredicate(format: "%K == %@", column, personObjectID)
        // equals to:
        // request.predicate = NSPredicate(format: "changedObjectID = %@", personObjectID)

        let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: token2)
        historyFetchRequest.fetchRequest = request
        historyFetchRequest.resultType = .changesOnly // ⚠️ impact the return type

        // After token2 we expect "Transaction #3" containing 2 changes:
        // Updated: 1 Person
        // Deleted: 1 Car
        // Since the fetch used a predicate on the personObjectID, we expect only the Updated change on the Person object.

        let changes = try viewContext1.historyChanges(using: historyFetchRequest)
        XCTAssertEqual(changes.count, 1) // Person

        // ⚠️ fetching history changes with a changedObjectID in the predicate doesn't work on a context associated with a different container
        // (even if the underlying store is the same)
        // If we remove from the predicate the "changedObjectID" clause, we get both the Updated Person and the Deleted Car.
        //
        // At the moment querying for changes using changedObjectID seems useful only in bulk updates (many contexts for the same container)
        let changes2 = try viewContext2.historyChanges(using: historyFetchRequest)
        XCTAssertTrue(changes2.isEmpty, "It seems that applying a predicate with changedObjectID doesn't work on a context associated with a different container.")

        let moID = psc2.managedObjectID(forURIRepresentation: personObjectID.uriRepresentation())!
        let mo = try viewContext2.existingObject(with: moID)
        XCTAssertNotNil(mo)

        let mo2 = try viewContext2.existingObject(with: personObjectID)
        XCTAssertNotNil(mo2)

        let backgroundViewContext = container1.newBackgroundContext()
        try backgroundViewContext.performAndWait {
          let changes3 = try backgroundViewContext.historyChanges(using: historyFetchRequest)
          XCTAssertEqual(changes3.count, 1) // Person
        }

        let first = try XCTUnwrap(changes.first)
        // Person has been added BEFORE token2 then updated.
        XCTAssertEqual(first.changeType, NSPersistentHistoryChangeType.update)
      } else {
        // FB8353599
        XCTAssertNil(changeEntityDescription.attributesByName["changedObjectID"], "Shown on WWDC 2020 but nil prior iOS 15 (FB8353599).")
      }
    }

    do {
      // ⏺ Query the "Change" entity by "changedEntity"
      let request = try XCTUnwrap(NSPersistentHistoryChangeRequest.makeChangeFetchRequest(with: viewContext1))
      let column = changeEntityDescription.attributesByName["changedEntity"]!.name
      request.predicate = NSPredicate(format: "%K = %@", column, Car.entity())

      let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: secondLastToken)
      historyFetchRequest.fetchRequest = request // ⚠️ WWDC 2020: history requests can be tailored using the fetchRequest property
      historyFetchRequest.resultType = .changesOnly // ⚠️ impact the return type
      let changes = try viewContext2.historyChanges(using: historyFetchRequest)

      XCTAssertEqual(changes.count, 1) // Car2 has been eliminated in the last token
      let first = try XCTUnwrap(changes.first)
      XCTAssertEqual(first.changedObjectID.uriRepresentation(), car2.objectID.uriRepresentation())
      XCTAssertEqual(first.changeType, NSPersistentHistoryChangeType.delete)
    } catch {
      XCTFail("Querying the Change entity failed: : \(error.localizedDescription)")
    }
  }
}

extension NSPersistentHistoryChangeRequest {
  /// Creates a NSFetchRequest for NSPersistentHistoryTransaction.
  /// - Note: context is used as hint to discover the Transaction entity.
  ///
  /// The predicate conditions must be applied to these fields (of the "Transaction" entity):
  ///
  /// - `author` (`NSString`)
  /// - `bundleID` (`NSString`)
  /// - `contextName` (`NSString`)
  /// - `processID` (`NSString`)
  /// - `timestamp` (`NSDate`)
  /// - `token` (`NSNumber` - `NSInteger64`)
  /// - `transactionNumber` (`NSNumber` - `NSInteger64`)
  @available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  fileprivate final class func makeTransactionFetchRequest(with context: NSManagedObjectContext) -> NSFetchRequest<NSFetchRequestResult>? {
    // https://developer.apple.com/videos/play/wwdc2019/230
    let transactionFetchRequest: NSFetchRequest<NSFetchRequestResult>
    if let request = NSPersistentHistoryTransaction.fetchRequest {
      transactionFetchRequest = request
    } else if let transactionEntityDescription = NSPersistentHistoryTransaction.entityDescription(with: context) {
      // ⚠️ NSPersistentHistoryTransaction.fetchRequest is nil during tests
      // TODO: open feedback
      transactionFetchRequest = NSFetchRequest<NSFetchRequestResult>()
      transactionFetchRequest.entity = transactionEntityDescription
    } else {
      return nil
    }

    return transactionFetchRequest
  }

  /// Creates a NSFetchRequest for NSPersistentHistoryChange.
  /// - Note: context is used as hint to discover the Change entity.
  ///
  /// The predicate conditions must be applied to these fields (of the "Change" entity):
  ///
  /// - `changedID` (`NSNumber` - `NSInteger64`)
  /// - `changedEntity` (`NSNumber` - `NSInteger64`)
  /// - `changeType` (`NSNumber` - `NSInteger64`)
  @available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public final class func makeChangeFetchRequest(with context: NSManagedObjectContext) -> NSFetchRequest<NSFetchRequestResult>? {
    let changeFetchRequest: NSFetchRequest<NSFetchRequestResult>
    if let request = NSPersistentHistoryChange.fetchRequest {
      changeFetchRequest = request
    } else if let changeEntityDescription = NSPersistentHistoryChange.entityDescription(with: context) {
      // ⚠️ NSPersistentHistoryChange.fetchRequest is nil during tests
      // TODO: open feedback
      changeFetchRequest = NSFetchRequest<NSFetchRequestResult>()
      changeFetchRequest.entity = changeEntityDescription
    } else {
      return nil
    }

    return changeFetchRequest
  }
}
