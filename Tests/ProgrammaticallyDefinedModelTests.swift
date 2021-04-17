// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
final class ProgrammaticallyDefinedModelTests: OnDiskWithProgrammaticallyModelTestCase {
  func testSetup() throws {
    let context = container.viewContext
    context.fillWithSampleData2()
    try context.save()
    context.reset()
    
    let books = try V1.Book.fetch(in: context)
    XCTAssertEqual(books.count, 52)
    
    let authors = try V1.Author.fetch(in: context)
    XCTAssertEqual(authors.count, 2)
    
    let fetchedAuthor = try V1.Author.fetch(in: context) { $0.predicate = NSPredicate(format: "%K == %@", #keyPath(V1.Author.alias), "Alessandro") }.first
    
    let author = try XCTUnwrap(fetchedAuthor)
    let feedbacks = try XCTUnwrap(author.feedbacks)
    XCTAssertEqual(feedbacks.map({ $0.rating }), [3.5, 4.2, 4.3])
    
    XCTAssertEqual(author.favFeedbacks?.count, 2)
  }
  
  func testTweakFetchedPropertyAtRuntime() throws {
    let context = container.viewContext
    context.fillWithSampleData2()
    try context.save()
    context.reset()
    
    let fetchedAuthor = try V1.Author.fetch(in: context) { $0.predicate = NSPredicate(format: "%K == %@", #keyPath(V1.Author.alias), "Alessandro") }.first
    
    let author = try XCTUnwrap(fetchedAuthor)
    XCTAssertEqual(author.favFeedbacks?.count, 2)
    
    let fetchedProperties = V1.Author.entity().properties.compactMap { $0 as? NSFetchedPropertyDescription }
    let favFeedbacksFetchedProperty = try XCTUnwrap(fetchedProperties.filter ({ $0.name == V1.Author.FetchedProperty.favFeedbacks }).first)
    
    // During the creation of the model, an key 'search' with value 'great' has been added to the fetched property
    // If we change its value at runtime, the result will reflect that.
    favFeedbacksFetchedProperty.userInfo?["search"] = "interesting"
    XCTAssertEqual(author.favFeedbacks?.count, 1)
  }
}
