// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

/// Tests with fetch requests targeting specific persistent stores
@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
final class FetchesWithAffectedStoresTests: XCTestCase {
  func testFetches() throws {
    let uuid = UUID().uuidString
    let url1 = URL.newDatabaseURL(withName: "part1-\(uuid)")
    let url2 = URL.newDatabaseURL(withName: "part2-\(uuid)")

    let psc = NSPersistentStoreCoordinator(managedObjectModel: V2.makeManagedObjectModel())
    try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: V2.Configurations.part1, at: url1, options: nil)
    try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: V2.Configurations.part2, at: url2, options: nil)

    let part1 = try XCTUnwrap(psc.persistentStores.first { $0.configurationName == V2.Configurations.part1 })
    let part2 = try XCTUnwrap(psc.persistentStores.first { $0.configurationName == V2.Configurations.part2 })

    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = psc

    let sharedUUID = UUID()

    let feedbackPart1 = FeedbackV2(context: context)
    feedbackPart1.authorAlias = "Alessandro"
    feedbackPart1.bookID = sharedUUID
    feedbackPart1.comment = "ok"
    feedbackPart1.rating = 3.5
    context.assign(feedbackPart1, to: part1)
    try context.save()

    let feedbackPart2 = FeedbackV2(context: context)
    feedbackPart2.authorAlias = "Alessandro"
    feedbackPart2.bookID = sharedUUID
    feedbackPart2.comment = "ok"
    feedbackPart2.rating = 3.5
    context.assign(feedbackPart2, to: part2)
    try context.save()

    context.reset()
    let predicate = NSPredicate(format: "%K == %@", #keyPath(Feedback.authorAlias), "Alessandro")

    context.reset()
    XCTAssertEqual(try FeedbackV2.fetch(in: context) { $0.affectedStores = [part1] }.count, 1)

    context.reset()
    XCTAssertEqual(try FeedbackV2.count(in: context), 2)
    XCTAssertEqual(try FeedbackV2.count(in: context) { $0.affectedStores = [part1] }, 1)
    XCTAssertEqual(try FeedbackV2.count(in: context) { $0.affectedStores = [part2] }, 1)

    // fetchObjectIDs
    context.reset()
    let ids = try FeedbackV2.fetchObjectIDs(in: context, where: predicate)
    XCTAssertEqual(ids.count, 2)
    let idsPart1 = try FeedbackV2.fetchObjectIDs(in: context, where: predicate, affectedStores: [part1])
    XCTAssertEqual(idsPart1, [feedbackPart1.objectID])
    let idsPart2 = try FeedbackV2.fetchObjectIDs(in: context, where: predicate, affectedStores: [part2])
    XCTAssertEqual(idsPart2, [feedbackPart2.objectID])

    // fetchOne
    context.reset()
    let one = try FeedbackV2.fetchOne(in: context, where: predicate)
    XCTAssertEqual(one?.objectID, feedbackPart1.objectID) // first inserted is the first one to be fetched during a query
    let onePart1 = try FeedbackV2.fetchOne(in: context, where: predicate, affectedStores: [part1])
    XCTAssertEqual(onePart1?.objectID, feedbackPart1.objectID)
    let onePart2 = try FeedbackV2.fetchOne(in: context, where: predicate, affectedStores: [part2])
    XCTAssertEqual(onePart2?.objectID, feedbackPart2.objectID)

    // fetchUnique
    context.reset()
    // let unique = try FeedbackV2.fetchUnique(in: context, where: predicate) // this fetch request crashes because uniqueness is not guaranteed for that predicate
    let uniquePart1 = try FeedbackV2.fetchUnique(in: context, where: predicate, affectedStores: [part1])
    XCTAssertEqual(uniquePart1?.objectID, feedbackPart1.objectID)
    let uniquePart2 = try FeedbackV2.fetchUnique(in: context, where: predicate, affectedStores: [part2])
    XCTAssertEqual(uniquePart2?.objectID, feedbackPart2.objectID)

    // findUniqueOrCreate (deprecated)
    context.reset()
    let predicate2 = NSPredicate(format: "%K == %@", #keyPath(Feedback.authorAlias), "Andrea")
    let objPart1 = try FeedbackV2.findUniqueOrCreate(in: context, where: predicate2, affectedStores: [part1], assignedStore: part1) { feedback in
      feedback.authorAlias = "Andrea"
      feedback.bookID = sharedUUID
      feedback.comment = "ok"
      feedback.rating = 3.5
    }
    XCTAssertTrue(objPart1.hasTemporaryID)
    try context.save()

    let obj2Part1 = try FeedbackV2.findUniqueOrCreate(in: context, where: predicate2, affectedStores: [part1]) { feedback in
      XCTFail("There should be another object matching this predicate.")
    }
    XCTAssertFalse(obj2Part1.objectID.isTemporaryID)

    let objPart2 = try FeedbackV2.findUniqueOrCreate(in: context, where: predicate2, affectedStores: [part2], assignedStore: part2) { feedback in
      feedback.authorAlias = "Andrea"
      feedback.bookID = sharedUUID
      feedback.comment = "ok"
      feedback.rating = 3.5
    }
    XCTAssertTrue(objPart2.objectID.isTemporaryID)
    try context.save()
    XCTAssertEqual(try FeedbackV2.count(in: context){ $0.predicate = predicate2 }, 2)

    // delete
    context.reset()
    try FeedbackV2.delete(in: context, includingSubentities: true, where: predicate2, limit: nil, affectedStores: [part1])
    XCTAssertEqual(try FeedbackV2.count(in: context) {
      $0.predicate = predicate2
      $0.affectedStores = [part1]
    }, 0)
    try context.save()

    XCTAssertEqual(try FeedbackV2.count(in: context){ $0.predicate = predicate2 }, 1)
    try FeedbackV2.delete(in: context, includingSubentities: true, where: predicate2, limit: nil, affectedStores: nil) // no affectedStores -> part1 & part2
    try context.save()
    XCTAssertEqual(try FeedbackV2.count(in: context){ $0.predicate = predicate2 }, 0)

    // delete excluding objects
    context.reset()
    let feedback2Part1 = FeedbackV2(context: context)
    feedback2Part1.authorAlias = "Andrea"
    feedback2Part1.bookID = UUID()
    feedback2Part1.comment = "ok"
    feedback2Part1.rating = 3.5
    context.assign(feedback2Part1, to: part1)
    try context.save()

    try FeedbackV2.delete(in: context, except: [feedbackPart1, feedbackPart2], affectedStores: [part2])
    XCTAssertEqual(try FeedbackV2.count(in: context) {
      $0.predicate = predicate2
      $0.affectedStores = [part1]
    }, 1) // feedback2Part1 is still there because the delete request has affected only part2

    XCTAssertEqual(try FeedbackV2.count(in: context) {
      $0.predicate = predicate2
      $0.affectedStores = [part2]
    }, 0)
    try FeedbackV2.delete(in: context, except: [feedbackPart1, feedbackPart2], affectedStores: nil) // no affectedStores -> part1 & part2
    XCTAssertEqual(try FeedbackV2.count(in: context) {
      $0.predicate = predicate2
      $0.affectedStores = [part1]
    }, 0)
    try context.save()

    context._fix_sqlite_warning_when_destroying_a_store()
    try NSPersistentStoreCoordinator.destroyStore(at: url1)
    try NSPersistentStoreCoordinator.destroyStore(at: url2)
  }

  func testBatchRequests() throws {
    let uuid = UUID().uuidString
    let url1 = URL.newDatabaseURL(withName: "part1-\(uuid)")
    let url2 = URL.newDatabaseURL(withName: "part2-\(uuid)")

    // Given
    let psc = NSPersistentStoreCoordinator(managedObjectModel: V2.makeManagedObjectModel())
    try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: V2.Configurations.part1, at: url1, options: nil)
    try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: V2.Configurations.part2, at: url2, options: nil)

    let part1 = try XCTUnwrap(psc.persistentStores.first { $0.configurationName == V2.Configurations.part1 })
    let part2 = try XCTUnwrap(psc.persistentStores.first { $0.configurationName == V2.Configurations.part2 })

    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = psc


    // When (insert)
    // part 1
    let feedback2: [String : Any] = [#keyPath(FeedbackV2.authorAlias): "Alessandro",
                                     #keyPath(FeedbackV2.bookID): UUID(),
                                     #keyPath(FeedbackV2.comment): "object2",
                                     #keyPath(FeedbackV2.rating): 3.5]
    let feedback4: [String : Any] = [#keyPath(FeedbackV2.authorAlias): "Alessandro",
                                     #keyPath(FeedbackV2.bookID): UUID(),
                                     #keyPath(FeedbackV2.comment): "object4",
                                     #keyPath(FeedbackV2.rating): 3.5]
    // part 2
    let feedback1: [String : Any] = [#keyPath(FeedbackV2.authorAlias): "Alessandro",
                                     #keyPath(FeedbackV2.bookID): UUID(),
                                     #keyPath(FeedbackV2.comment): "object1",
                                     #keyPath(FeedbackV2.rating): 3.5]
    let feedback3: [String : Any] = [#keyPath(FeedbackV2.authorAlias): "Andrea",
                                     #keyPath(FeedbackV2.bookID): UUID(),
                                     #keyPath(FeedbackV2.comment): "object3",
                                     #keyPath(FeedbackV2.rating): 2.5]

    let resultInsertPart1 = try FeedbackV2.batchInsert(using: context, resultType: .statusOnly, objects: [feedback2, feedback4], affectedStores: [part1])
    let resultInsertPart2 = try FeedbackV2.batchInsert(using: context, resultType: .statusOnly, objects: [feedback1, feedback3], affectedStores: [part2])
    // Then
    XCTAssertTrue(resultInsertPart1.status!)
    XCTAssertTrue(resultInsertPart2.status!)
    XCTAssertEqual(try FeedbackV2.count(in: context) { $0.affectedStores = [part1] }, 2)
    XCTAssertEqual(try FeedbackV2.count(in: context) { $0.affectedStores = [part2] }, 2)


    // When (update)
    let predicateAlessandro = NSPredicate(format: "%K == %@", #keyPath(FeedbackV2.authorAlias), "Alessandro")

    // rename the authorAlias in all the feedbacks in part1 whose authorAlias is Alessandro (2) and comment is object1 (1)
    let resultUpdatePart1 = try FeedbackV2.batchUpdate(using: context) {
      let predicate2 = NSPredicate(format: "%K == %@", #keyPath(FeedbackV2.comment), "object2")
      $0.propertiesToUpdate = [#keyPath(FeedbackV2.authorAlias): "AlessandroUpdated"]
      $0.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateAlessandro, predicate2])
      $0.resultType = .statusOnlyResultType
      $0.affectedStores = [part1]
    }
    // Then
    XCTAssertTrue(resultUpdatePart1.status!)
    XCTAssertEqual(try FeedbackV2.count(in: context) { $0.predicate = predicateAlessandro }, 2)
    XCTAssertEqual(try FeedbackV2.count(in: context) { $0.predicate = predicateAlessandro; $0.affectedStores = [part1] }, 1)
    XCTAssertEqual(try FeedbackV2.count(in: context) { $0.predicate = predicateAlessandro; $0.affectedStores = [part2] }, 1)

    // When (delete)

    // delete feedback in part2 where the authorAlias is Alessandro (1)
    let resultDeletePart2 = try FeedbackV2.batchDelete(using: context,
                                                       predicate: predicateAlessandro,
                                                       resultType: .resultTypeCount,
                                                       affectedStores: [part2])
    // Then
    XCTAssertEqual(resultDeletePart2.count!, 1)
    XCTAssertEqual(try FeedbackV2.count(in: context) { $0.predicate = predicateAlessandro; $0.affectedStores = [part2] }, 0)
    XCTAssertEqual(try FeedbackV2.count(in: context) { $0.predicate = predicateAlessandro; $0.affectedStores = [part1] }, 1)

    let resultDeleteAll = try FeedbackV2.batchDelete(using: context, affectedStores: [part1, part2])
    XCTAssertTrue(resultDeleteAll.status!)
    XCTAssertEqual(try FeedbackV2.count(in: context), 0)

    context._fix_sqlite_warning_when_destroying_a_store()
    try NSPersistentStoreCoordinator.destroyStore(at: url1)
    try NSPersistentStoreCoordinator.destroyStore(at: url2)
  }
}
