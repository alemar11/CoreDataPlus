// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
final class AffectedStoresTests: XCTestCase {
  func test__() throws {
    let url1 = URL.newDatabaseURL(withName: "part1")
    let url2 = URL.newDatabaseURL(withName: "part2")
    
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
    
    let feedbackPart2 = FeedbackV2(context: context)
    feedbackPart2.authorAlias = "Alessandro"
    feedbackPart2.bookID = sharedUUID
    feedbackPart2.comment = "ok"
    feedbackPart2.rating = 3.5
    context.assign(feedbackPart2, to: part2)
    
    
    try context.save()
    context.reset()
    let predicate = NSPredicate(format: "%K == %@", #keyPath(Feedback.authorAlias), "Alessandro")
    
    let count = try FeedbackV2.count(in: context)
    XCTAssertEqual(count, 2)
    
    let countPart1 = try FeedbackV2.count(in: context) { $0.affectedStores = [part1] }
    XCTAssertEqual(countPart1, 1)
    let countPart2 = try FeedbackV2.count(in: context) { $0.affectedStores = [part2] }
    XCTAssertEqual(countPart2, 1)
    
    context.reset()
    let ids = try FeedbackV2.fetchObjectIDs(in: context, where: predicate)
    XCTAssertEqual(ids.count, 2)
    let idsPart1 = try FeedbackV2.fetchObjectIDs(in: context, where: predicate, affectedStores: [part1])
    XCTAssertEqual(idsPart1, [feedbackPart1.objectID])
    let idsPart2 = try FeedbackV2.fetchObjectIDs(in: context, where: predicate, affectedStores: [part2])
    XCTAssertEqual(idsPart2, [feedbackPart2.objectID])
    
    
//    fetchOne
//    findOneOrCreate
//    materializedObjectOrFetch
//    findUniqueOrCreate
//    fetchUnique
//    delete
//    batchUpdate, Insert, Delete
    
    context._fix_sqlite_warning_when_destroying_a_store()
    try NSPersistentStoreCoordinator.destroyStore(at: url1)
    try NSPersistentStoreCoordinator.destroyStore(at: url2)
  }
}
