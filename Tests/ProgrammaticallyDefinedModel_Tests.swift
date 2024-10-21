// CoreDataPlus

import CoreData
import XCTest

@testable import CoreDataPlus

// MARK: - V1

final class ProgrammaticallyDefinedModel_Tests: OnDiskWithProgrammaticallyModelTestCase {
  func test_Setup() throws {
    let context = container.viewContext
    context.fillWithSampleData2()
    try context.save()
    context.reset()

    let books = try Book.fetchObjects(in: context)
    XCTAssertEqual(books.count, 52)

    let authors = try Author.fetchObjects(in: context)
    XCTAssertEqual(authors.count, 2)

    let fetchedAuthor = try Author.fetchObjects(in: context) {
      $0.predicate = NSPredicate(format: "%K == %@", #keyPath(Author.alias), "Alessandro")
    }
    .first

    let author = try XCTUnwrap(fetchedAuthor)
    let feedbacks = try XCTUnwrap(author.feedbacks)
    XCTAssertEqual(feedbacks.map({ $0.rating }), [3.5, 4.2, 4.3])

    XCTAssertEqual(author.favFeedbacks?.count, 2)
  }

  func test_TweakFetchedPropertyAtRuntime() throws {
    let context = container.viewContext
    context.fillWithSampleData2()
    try context.save()
    context.reset()

    let fetchedAuthor = try Author.fetchObjects(in: context) {
      $0.predicate = NSPredicate(format: "%K == %@", #keyPath(Author.alias), "Alessandro")
    }
    .first

    let author = try XCTUnwrap(fetchedAuthor)
    XCTAssertEqual(author.favFeedbacks?.count, 2)

    let fetchedProperties = Author.entity().properties.compactMap { $0 as? NSFetchedPropertyDescription }
    let favFeedbacksFetchedProperty = try XCTUnwrap(
      fetchedProperties.filter({ $0.name == Author.FetchedProperty.favFeedbacks }).first)

    // During the creation of the model, an key 'search' with value 'great' has been added to the fetched property
    // If we change its value at runtime, the result will reflect that.
    favFeedbacksFetchedProperty.userInfo?["search"] = "interesting"
    XCTAssertEqual(author.favFeedbacks?.count, 1)
  }
}

// MARK: - V2

final class ProgrammaticallyDefinedModelV2Tests: XCTestCase {
  // Tests to make it sure that the model V2 is correctly defined
  func test_SetupV2() throws {
    let url = URL.newDatabaseURL(withID: UUID())
    let model = V2.makeManagedObjectModel()
    let container = NSPersistentContainer(name: "SampleModel2", managedObjectModel: model)
    let description = NSPersistentStoreDescription()
    description.url = url
    description.shouldMigrateStoreAutomatically = false
    description.shouldInferMappingModelAutomatically = false
    container.persistentStoreDescriptions = [description]
    container.loadPersistentStores { (description, error) in
      XCTAssertNil(error)
    }
    let context = container.viewContext
    context.fillWithSampleData2UsingModelV2()

    try context.save()
    context.reset()

    let fetchedAuthor = try AuthorV2.fetchObjects(in: context) {
      $0.predicate = NSPredicate(format: "%K == %@", #keyPath(Author.alias), "Alessandro")
    }.first

    let author = try XCTUnwrap(fetchedAuthor)
    let feedbacks = try XCTUnwrap(author.feedbacks)
    XCTAssertEqual(feedbacks.map({ $0.rating }), [3.5, 4.2, 4.3])

    XCTAssertEqual(author.favFeedbacks?.count, 2)
  }
}

// MARK: - V3

final class ProgrammaticallyDefinedModelV3Tests: XCTestCase {
  // Tests to make it sure that the model V3 is correctly defined
  func test_SetupV3() throws {
    let url = URL.newDatabaseURL(withID: UUID())
    let container = NSPersistentContainer(name: "SampleModel2", managedObjectModel: V3.makeManagedObjectModel())
    let description = NSPersistentStoreDescription()
    description.url = url
    description.shouldMigrateStoreAutomatically = false
    description.shouldInferMappingModelAutomatically = false
    container.persistentStoreDescriptions = [description]
    container.loadPersistentStores { (description, error) in
      XCTAssertNil(error)
    }
    let context = container.viewContext
    context.fillWithSampleData2UsingModelV3()

    try context.save()
    context.reset()

    let fetchedAuthor = try AuthorV3.fetchObjects(in: context) {
      $0.predicate = NSPredicate(format: "%K == %@", #keyPath(Author.alias), "Alessandro")
    }.first

    let author = try XCTUnwrap(fetchedAuthor)
    let feedbacks = try XCTUnwrap(author.feedbacks)
    XCTAssertEqual(feedbacks.map({ $0.rating }), [3.5, 4.2, 4.3])

    XCTAssertEqual(author.favFeedbacks?.count, 2)
  }

  func test_InvestigationVersionHashes() {
    // http://openradar.appspot.com/FB9044112
    let coverVersionHash = V3.makeManagedObjectModel().entityVersionHashesByName["Cover"]
    let bookVersionHash = V3.makeManagedObjectModel().entityVersionHashesByName["Book"]
    XCTAssertEqual(V3.makeCoverEntity().versionHash, V3.makeCoverEntity().versionHash)
    XCTAssertEqual(V3.makeBookEntity().versionHash, V3.makeBookEntity().versionHash)
    XCTAssertNotEqual(V3.makeCoverEntity().versionHash, coverVersionHash)  // Bug: these are expected to be equal
    XCTAssertNotEqual(V3.makeBookEntity().versionHash, bookVersionHash)  // Bug: these are expected to be equal
  }
}
