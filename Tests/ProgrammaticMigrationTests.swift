// CoreDataPlus

import XCTest
@testable import CoreDataPlus

@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
final class ProgrammaticMigrationTests: XCTestCase {
  
  func testInferringMappingModelFromV1toV2() throws {
    let mappingModel = SampleModel2.SampleModel2Version.version1.inferredMappingModelToNextModelVersion()
    let mappings = try XCTUnwrap(mappingModel?.entityMappings)
    let authorMappingModel = try XCTUnwrap(mappings.first(where:{ $0.sourceEntityName == "Author" }))
    XCTAssertEqual(authorMappingModel.mappingType, .transformEntityMappingType)
    
    let bookMappingModel = try XCTUnwrap(mappings.first(where:{ $0.sourceEntityName == "Book" }))
    XCTAssertEqual(bookMappingModel.mappingType, .transformEntityMappingType)
    
    do {
      let mappingProperties = try XCTUnwrap(authorMappingModel.mappingProperties)
      XCTAssertEqual(mappingProperties.mappedProperties.count, 3)
      XCTAssertTrue(mappingProperties.mappedProperties.contains("age"))
      XCTAssertTrue(mappingProperties.mappedProperties.contains("alias"))
      XCTAssertTrue(mappingProperties.mappedProperties.contains("books"))
      
      XCTAssertTrue(mappingProperties.addedProperties.isEmpty)
      
      XCTAssertEqual(mappingProperties.removedProperties.count, 1)
      XCTAssertTrue(mappingProperties.removedProperties.contains("siteURL"))
    }
    
    do {
      XCTAssertNotNil(bookMappingModel.attributeMappings?.first(where: { $0.name == "frontCover" })) // this is as far I can go
      let mappingProperties = try XCTUnwrap(bookMappingModel.mappingProperties)
      
      XCTAssertEqual(mappingProperties.mappedProperties.count, 8)
      XCTAssertTrue(mappingProperties.mappedProperties.contains("frontCover"))
      XCTAssertFalse(mappingProperties.mappedProperties.contains("cover"))
      XCTAssertTrue(mappingProperties.addedProperties.isEmpty)
      XCTAssertTrue(mappingProperties.removedProperties.isEmpty)
    }
  }
  
  func testEntityName() {
    XCTAssertNil(V1.Author.entity().name)
    _ = NSPersistentStoreCoordinator(managedObjectModel: V1.makeManagedObjectModel())
    XCTAssertNotNil(V1.Author.entity().name)
  }
  
  func testMigrationFromV1ToV2() throws {
    let url = URL.newDatabaseURL(withID: UUID())
    
    let options = [
      NSMigratePersistentStoresAutomaticallyOption: true,
      NSInferMappingModelAutomaticallyOption: false,
      NSPersistentHistoryTrackingKey: true, // ⚠️ cannot be changed once set to true
      NSPersistentHistoryTokenKey: true
    ]
    
    let description = NSPersistentStoreDescription(url: url)
    description.configuration = nil
    description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    description.setOption(true as NSNumber, forKey: NSPersistentHistoryTokenKey)
    
    let oldManagedObjectModel = V1.makeManagedObjectModel()
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: oldManagedObjectModel)
    coordinator.addPersistentStore(with: description) { (description, error) in
      XCTAssertNil(error)
    }
    
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = coordinator
    context.fillWithSampleData2()
    try context.save()
    // ⚠️ This step is required if you want to do a migration with WAL checkpoint enabled
    try coordinator.persistentStores.forEach({ (store) in
      try coordinator.remove(store)
    })
    
    // Migration
    try CoreDataPlus.Migration.migrateStore(at: url, options: options, targetVersion: SampleModel2.SampleModel2Version.version2, enableWALCheckpoint: true)
    
    // Validation
    let newManagedObjectModel = V2.makeManagedObjectModel()
    let newCoordinator = NSPersistentStoreCoordinator(managedObjectModel: newManagedObjectModel)
    try newCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
    
    let newContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    newContext.persistentStoreCoordinator = newCoordinator
    
    let authorRequest = NSFetchRequest<NSManagedObject>(entityName: "Author") as! NSFetchRequest<AuthorV2>
    let authors = try newContext.fetch(authorRequest)
    XCTAssertEqual(authors.count, 2)
    authors.forEach { object in
      object.materialize()
      object.alias += "-"
    }
    
    let bookRequest = NSFetchRequest<NSManagedObject>(entityName: "Book")
    let books = try newContext.fetch(bookRequest)
    XCTAssertEqual(books.count, 52)
    books.forEach { object in
      object.materialize()
      XCTAssertNotNil(object.value(forKey: #keyPath(BookV2.frontCover)))
    }
    
    let feedbacksCount = try FeedbackV2.count(in: newContext)
    XCTAssertEqual(feedbacksCount, 444)
    
    try! newContext.save()
    newContext._fix_sqlite_warning_when_destroying_a_store()
    try FileManager.default.removeItem(at: url)
  }
  
  func testMigrationFromV1ToV2WithMultipleStores() throws {
    let options = [
      NSMigratePersistentStoresAutomaticallyOption: true,
      NSInferMappingModelAutomaticallyOption: false,
      NSPersistentHistoryTrackingKey: true, // ⚠️ cannot be changed once set to true
      NSPersistentHistoryTokenKey: true
    ]
        
    let url = URL.newDatabaseURL(withID: UUID())
    let oldManagedObjectModel = V1.makeManagedObjectModel()
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: oldManagedObjectModel)
    
    try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: V1.Configurations.one, at: url, options: options)
    
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = coordinator
    context.fillWithSampleData2()
    try context.save()
    // ⚠️ This step is required if you want to do a migration with WAL checkpoint enabled
    try coordinator.persistentStores.forEach({ (store) in
      try coordinator.remove(store)
    })
    
    // Migration
    try CoreDataPlus.Migration.migrateStore(at: url, options: options, targetVersion: SampleModel2.SampleModel2Version.version2)
    
    // Validation
    
    // V2 model has 2 configurations: "SampleConfigurationV2Part1" and "SampleConfigurationV2Part2"
    // "SampleConfigurationV2Part1" has all the entities while "SampleConfigurationV2Part2" has only "Feedback"
    // We can't copy the migrated db and use it for the second store with configuration "SampleConfigurationV2Part2" because CoreData will throw an exception;
    // instead we create an empty db for the second store and we will move records (Feedback) from one db to the other (that is why we need to have both the configurations with the "Feedback" entity on them.
    // An optional step would be to delete "Feedback" records from the store with configuration "SampleConfigurationV2Part1"
    let urlPart2 = URL.newDatabaseURL(withID: UUID())
    
    let newCoordinator = NSPersistentStoreCoordinator(managedObjectModel: V2.makeManagedObjectModel())
    
    try newCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: V2.Configurations.part1, at: url, options: options)
    try newCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: V2.Configurations.part2, at: urlPart2, options: options)
    
    let newContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    newContext.persistentStoreCoordinator = newCoordinator
    
    let part1 = try XCTUnwrap(newCoordinator.persistentStores.first { $0.configurationName == V2.Configurations.part1 })
    let part2 = try XCTUnwrap(newCoordinator.persistentStores.first { $0.configurationName == V2.Configurations.part2 })

//    let _authors = try AuthorV2.fetch(in: newContext)
//    XCTAssertEqual(AuthorV2.entity().name, AuthorV2.entityName)
    
    let authorRequest = NSFetchRequest<NSManagedObject>(entityName: "Author") as! NSFetchRequest<AuthorV2>
    let authors = try newContext.fetch(authorRequest)
    XCTAssertEqual(authors.count, 2)
    authors.forEach {
      $0.materialize()
    }
    try newContext.save()
    
    let bookRequest = NSFetchRequest<NSManagedObject>(entityName: "Book") as! NSFetchRequest<BookV2>
    let books = try newContext.fetch(bookRequest)
    XCTAssertEqual(books.count, 52)
    books.forEach { book in
      XCTAssertNotNil(book.value(forKey: #keyPath(BookV2.frontCover)))
    }
    
    let feedbackRequest = NSFetchRequest<NSManagedObject>(entityName: "Feedback") as! NSFetchRequest<FeedbackV2>
    feedbackRequest.affectedStores = [part1] // important to take values from part1
    let feedbacks = try newContext.fetch(feedbackRequest)
    XCTAssertEqual(feedbacks.count, 444)
    
    feedbacks.forEach {
      let feedback = FeedbackV2(context: newContext)
      feedback.authorAlias = $0.authorAlias
      feedback.bookID = $0.bookID
      feedback.comment = $0.comment
      feedback.rating = $0.rating * 10
      newContext.assign(feedback, to: part2) // or it will stored in the first added persistent store
    }
    try newContext.save()
    
    let feedbackRequest2 = NSFetchRequest<NSManagedObject>(entityName: "Feedback") as! NSFetchRequest<FeedbackV2>
    feedbackRequest2.affectedStores = [part2]
    let feedbacks2 = try newContext.fetch(feedbackRequest)
    XCTAssertEqual(feedbacks2.count, 444)
    
    do {
      let fetchedAuthorRequest = NSFetchRequest<NSManagedObject>(entityName: "Author") as! NSFetchRequest<AuthorV2>
      fetchedAuthorRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(V1.Author.alias), "Alessandro")
      let fetchedAuthor = try newContext.fetch(fetchedAuthorRequest).first
      
      let author = try XCTUnwrap(fetchedAuthor)
      XCTAssertEqual(author.feedbacks?.count, 6) // 3 each store
    }
    
    do {
      let fetchedAuthorRequest = NSFetchRequest<NSManagedObject>(entityName: "Author") as! NSFetchRequest<AuthorV2>
      fetchedAuthorRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(V1.Author.alias), "Andrea")
      let fetchedAuthor = try newContext.fetch(fetchedAuthorRequest).first
      
      let author = try XCTUnwrap(fetchedAuthor)
      XCTAssertEqual(author.feedbacks?.count, 882) // 441 each store
    }
    
    newContext._fix_sqlite_warning_when_destroying_a_store()
    try FileManager.default.removeItem(at: url)
    try FileManager.default.removeItem(at: urlPart2)
  }
}

extension NSEntityMapping {
  // Represents all the mapping properties.
  public struct Properties {
    let mappedProperties: Set<String>
    let addedProperties: Set<String>
    let removedProperties: Set<String>
    
    fileprivate init(userInfo: [AnyHashable: Any]) {
      self.mappedProperties = userInfo["mappedProperties"] as? Set<String> ?? Set()
      self.addedProperties = userInfo["addedProperties"] as? Set<String> ?? Set()
      self.removedProperties = userInfo["removedProperties"] as? Set<String> ?? Set()
    }
  }
  
  public var mappingProperties: Properties? {
    guard let info = userInfo else { return nil }
    return Properties(userInfo: info)
  }
}
/*
 https://developer.apple.com/forums/thread/118924
 That error is because you also removed the history tracking option. Which you shouldn't do after you've enabled it.
 You can disable CloudKit sync simply by setting the cloudKitContainer options property on your store description to nil.
 However, you should leave history tracking on so that NSPersitentCloudKitContainer can catch up if you turn it on again.
 
 NSPersistentStoreRemoteChangeNotificationPostOptionKey
 */

// TODO: migration isn't commited to the actual url until the end (which is expected)
// but if we try to run mutiple steps, using a tempURL is probably better

// TODO: use NSPersistentStoreDescription

// TODO: affectedStores as param in all the fetch methods

