// CoreDataPlus

import XCTest
import CoreData
import Foundation
@testable import CoreDataPlus

@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
final class ProgrammaticMigrationTests: XCTestCase {

  func testInferringMappingModelFromV1toV2() throws {
    let mappingModel = try XCTUnwrap(SampleModel2.SampleModel2Version.version1.inferredMappingModelToNextModelVersion())
    XCTAssertTrue(mappingModel.isInferred)
    let mappings = try XCTUnwrap(mappingModel.entityMappings)
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
    let sourceDescription = NSPersistentStoreDescription(url: url)
    let destinationDescription = NSPersistentStoreDescription(url: url)
    options.forEach { key, value in
      sourceDescription.setOption(value as NSObject, forKey: key)
      destinationDescription.setOption(value as NSObject, forKey: key)
    }

    let migrator = Migrator<SampleModel2.SampleModel2Version>(sourceStoreDescription: sourceDescription,
                                                              destinationStoreDescription: destinationDescription,
                                                              targetVersion: .version2)
    try migrator.migrate(enableWALCheckpoint: true)

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
    //try FileManager.default.removeItem(at: url)
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
    let sourceDescription = NSPersistentStoreDescription(url: url)
    let destinationDescription = NSPersistentStoreDescription(url: url)
    options.forEach { key, value in
      sourceDescription.setOption(value as NSObject, forKey: key)
      destinationDescription.setOption(value as NSObject, forKey: key)
    }

    let migrator = Migrator<SampleModel2.SampleModel2Version>(sourceStoreDescription: sourceDescription,
                                                              destinationStoreDescription: destinationDescription,
                                                              targetVersion: .version2)
    try migrator.migrate(enableWALCheckpoint: true)

    // Validation

    // V2 model has 2 configurations: "SampleConfigurationV2Part1" and "SampleConfigurationV2Part2"
    // "SampleConfigurationV2Part1" has all the entities while "SampleConfigurationV2Part2" has only "Feedback"
    // We can't copy the migrated db and use it for the second store with configuration "SampleConfigurationV2Part2" because CoreData will throw an exception;
    // instead we create an empty db for the second store and we will move records (Feedback) from one db to the other (that is why we need to have both the configurations with the "Feedback" entity on them.
    // An optional step would be to delete "Feedback" records from the store with configuration "SampleConfigurationV2Part1"
    let urlPart2 = URL.newDatabaseURL(withID: UUID())

    // The new coordinator will load both the stores.
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
      fetchedAuthorRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Author.alias), "Alessandro")
      let fetchedAuthor = try newContext.fetch(fetchedAuthorRequest).first

      let author = try XCTUnwrap(fetchedAuthor)
      XCTAssertEqual(author.feedbacks?.count, 6) // 3 each store
    }

    do {
      let fetchedAuthorRequest = NSFetchRequest<NSManagedObject>(entityName: "Author") as! NSFetchRequest<AuthorV2>
      fetchedAuthorRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Author.alias), "Andrea")
      let fetchedAuthor = try newContext.fetch(fetchedAuthorRequest).first

      let author = try XCTUnwrap(fetchedAuthor)
      XCTAssertEqual(author.feedbacks?.count, 882) // 441 each store
    }

    newContext._fix_sqlite_warning_when_destroying_a_store()
    try FileManager.default.removeItem(at: url)
    try FileManager.default.removeItem(at: urlPart2)
  }

  func testMigrationFromV1toV3() throws {
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

    let migrator = Migrator<SampleModel2.SampleModel2Version>(sourceStoreDescription: description,
                                                              destinationStoreDescription: description,
                                                              targetVersion: .version3)
    var completion = 0.0
    let token = migrator.progress.observe(\.fractionCompleted, options: [.new]) { (progress, change) in
      print(progress.fractionCompleted)
      completion = progress.fractionCompleted
    }

    try migrator.migrate(enableWALCheckpoint: true) { metadata in
      if metadata.mappingModel.isInferred {
        let manager = LightweightMigrationManager(sourceModel: metadata.sourceModel, destinationModel: metadata.destinationModel)
        manager.updateProgressInterval = 0.001 // we need to set a very low refresh interval to get some fake progress updates
        manager.estimatedTime = 0.1
        return manager
      } else {
        // In FeedbackMigrationManager.swift there are 2 possibile solutions:

        // solution #1
        if metadata.mappingModel.entityMappingsByName["FeedbackToFeedbackPartOne"] != nil && metadata.mappingModel.entityMappingsByName["FeedbackToFeedbackPartTwo"] != nil {
          return FeedbackMigrationManager(sourceModel: metadata.sourceModel, destinationModel: metadata.destinationModel)
        } else {
          return NSMigrationManager(sourceModel: metadata.sourceModel, destinationModel: metadata.destinationModel)
        }

        // solution #2 (currently commented out in FeedbackMigrationManager.swift)
        // return NSMigrationManager(sourceModel: metadata.sourceModel, destinationModel: metadata.destinationModel)
      }
    }

    // Validation
    XCTAssertEqual(completion, 1.0)
    token.invalidate()

    let newManagedObjectModel = V3.makeManagedObjectModel()
    let newCoordinator = NSPersistentStoreCoordinator(managedObjectModel: newManagedObjectModel)
    try newCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)

    let newContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    newContext.persistentStoreCoordinator = newCoordinator

    let authors = try AuthorV3.fetchObjects(in: newContext) {
      $0.predicate = NSPredicate(format: "%K == %@", #keyPath(Author.alias), "Andrea")
    }
    let author = try XCTUnwrap(authors.first)
    let booksCount = try BookV3.count(in: newContext)
    XCTAssertEqual(booksCount, 52)
    XCTAssertEqual(author.books.count, 49)
    let feedbacksForAndrea = try XCTUnwrap(author.feedbacks)
    XCTAssertEqual(feedbacksForAndrea.count, 441)
    feedbacksForAndrea.forEach {
      if $0.comment.contains("great") {
        // min value assigned randomly is 1.3, during the migration all the ratings get a +10
        XCTAssertTrue($0.rating >= 11.3)
      } else {
        // The max value assigned randomly is 5.8
        XCTAssertTrue($0.rating <= 5.8, "Rating \($0.rating) should be lesser than 5.8")
      }
    }

    let books = try XCTUnwrap(author.books as? Set<BookV3>)
    books.forEach {
      XCTAssertEqual($0.pages.count, 99)
    }

    newContext._fix_sqlite_warning_when_destroying_a_store()
    try FileManager.default.removeItem(at: url)
  }

  func testInvestigationNSExpression() {
    // https://nshipster.com/nsexpression/
    // https://funwithobjc.tumblr.com/post/2922267976/using-custom-functions-with-nsexpression
    // https://nshipster.com/kvc-collection-operators/
    // https://spin.atomicobject.com/2015/03/24/evaluate-string-expressions-ios-objective-c-swift/
    do {
      let expression = NSExpression(format: "4 + 5 - 2**3")
      let value = expression.expressionValue(with: nil, context: nil) as? Int
      XCTAssertEqual(value, 1)
    }

    do {
      let expression = NSPredicate(format: "1 + 2 > 2") // for logical expressions use NSPredicate
      let value = expression.evaluate(with: nil)
      XCTAssertEqual(value, true)
    }

    do {
      let numbers = [1, 2, 3, 4, 4, 5, 9, 11]
      let args = [NSExpression(forConstantValue: numbers)]
      let expression = NSExpression(forFunction:"max:", arguments: args)
      let value = expression.expressionValue(with: nil, context: nil) as? Int
      XCTAssertEqual(value, 11)
    }

    do {
      // This test demonstrate how to use a custom function with arguments
      // One of the things to be wary of when using custom functions is that all of the parameters to the method must be objects,
      // and the return value of the method must also be an object!
      // FUNCTION(operand, 'function', arguments, ...)

      let expression = NSExpression(format:#"FUNCTION(%@, 'substring2ToIndex:', %@)"#, argumentArray: ["hello world", NSNumber(1)])
      // same as:
      //let expression = NSExpression(format:#"FUNCTION("hello world", 'substring2ToIndex:', %@)"#, argumentArray: [NSNumber(1)])
      let value = expression.expressionValue(with: nil, context: nil) as? NSString
      XCTAssertEqual(value, "h")
    }
  }
}

extension NSString {
  @objc(substring2ToIndex:)
  func substring2(to index: NSNumber) -> NSString {
    return self.substring(to: index.intValue) as NSString
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
