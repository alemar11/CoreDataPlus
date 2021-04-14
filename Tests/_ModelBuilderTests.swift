// CoreDataPlus

import XCTest
@testable import CoreDataPlus

@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
final class ModelBuilderTests: OnDiskWithProgrammaticallyModelTestCase {
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

@available(OSX 10.15, *)
final class ProgrammaticMigrationTests: XCTestCase {

//  func createSampleVersion1() throws -> URL {
//    try autoreleasepool {
//    let model = V1.makeManagedObjectModel()
//    let container = NSPersistentContainer(name: "SampleModel2", managedObjectModel: model)
//    let url = URL.newDatabaseURL(withID: UUID())
//    container.persistentStoreDescriptions[0].shouldAddStoreAsynchronously = false
//    container.persistentStoreDescriptions[0].url = url
//    container.loadPersistentStores { (description, error) in
//      XCTAssertNil(error)
//
//      let context = container.viewContext
//      context.fillWithSampleData2()
//      do {
//        try context.save()
//      } catch {
//        XCTFail(error.localizedDescription)
//      }
//    }
//      if let store = container.persistentStoreCoordinator.persistentStores.first {
//        try container.persistentStoreCoordinator.remove(store)
//      }
//
//    return url
//    }
//  }

//  func testInferringMappingModelFromV1toV2() throws {
//    let mappingModel = SampleModel2.SampleModel2Version.version1.inferredMappingModelToNextModelVersion()
//    let mappings = try XCTUnwrap(mappingModel?.entityMappings)
//    let authorMappingModel = try XCTUnwrap(mappings.first(where:{ $0.sourceEntityName == "Author" }))
//    XCTAssertEqual(authorMappingModel.mappingType, .transformEntityMappingType)
//
//    let bookMappingModel = try XCTUnwrap(mappings.first(where:{ $0.sourceEntityName == "Book" }))
//    XCTAssertEqual(bookMappingModel.mappingType, .transformEntityMappingType)
//
//    do {
//      let mappingProperties = try XCTUnwrap(authorMappingModel.mappingProperties)
//      XCTAssertEqual(mappingProperties.mappedProperties.count, 3)
//      XCTAssertTrue(mappingProperties.mappedProperties.contains("age"))
//      XCTAssertTrue(mappingProperties.mappedProperties.contains("alias"))
//      XCTAssertTrue(mappingProperties.mappedProperties.contains("books"))
//
//      XCTAssertTrue(mappingProperties.addedProperties.isEmpty)
//
//      XCTAssertEqual(mappingProperties.removedProperties.count, 1)
//      XCTAssertTrue(mappingProperties.removedProperties.contains("siteURL"))
//    }

//    do {
//      XCTAssertNotNil(bookMappingModel.attributeMappings?.first(where: { $0.name == "frontCover" })) // this is as far I can go
//      let mappingProperties = try XCTUnwrap(bookMappingModel.mappingProperties)
//
//      XCTAssertEqual(mappingProperties.mappedProperties.count, 8)
//      XCTAssertTrue(mappingProperties.mappedProperties.contains("frontCover"))
//      XCTAssertFalse(mappingProperties.mappedProperties.contains("cover"))
//      XCTAssertTrue(mappingProperties.addedProperties.isEmpty)
//      XCTAssertTrue(mappingProperties.removedProperties.isEmpty)
//    }
//  }
  
  func testMigrationFromV1ToV2() throws {
    #warning("This fails unless the model is loaded")
    //XCTAssertEqual(AuthorV2.entity().name, AuthorV2.entityName)

    let url = URL.newDatabaseURL(withID: UUID())
    
    let options = [
      //NSMigratePersistentStoresAutomaticallyOption: true,
      //NSInferMappingModelAutomaticallyOption: false,
      NSPersistentHistoryTrackingKey: true,
      NSPersistentHistoryTokenKey: true
      //NSReadOnlyPersistentStoreOption: true
    ]
    
    let oldManagedObjectModel = V1.makeManagedObjectModel()
    var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: oldManagedObjectModel)
    
    try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: SampleModel2.SampleModel2Version.version1.options)
    
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = coordinator
    context.fillWithSampleData2()
    try context.save()
    coordinator = nil
    
    // Migration
    try CoreDataPlus.Migration.migrateStore(at: url, targetVersion: SampleModel2.SampleModel2Version.version2)
    
    // Validation
    let newManagedObjectModel = V2.makeManagedObjectModel()
    let newCoordinator = NSPersistentStoreCoordinator(managedObjectModel: newManagedObjectModel)
    try newCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
    
    let newContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    newContext.persistentStoreCoordinator = newCoordinator
    
    let _authors = try AuthorV2.fetch(in: newContext)
    XCTAssertEqual(AuthorV2.entity().name, AuthorV2.entityName)
    let authorRequest = NSFetchRequest<NSManagedObject>(entityName: "Author") as! NSFetchRequest<AuthorV2>
    let authors = try newContext.fetch(authorRequest)
    XCTAssertEqual(authors.count, 2)
    authors.forEach { object in
      object.materialize()
      object.alias += "-"
      //print(object)
      //XCTAssertNil(object.value(forKey: #keyPath(V1.Author.siteURL)))
    }
    
    let bookRequest = NSFetchRequest<NSManagedObject>(entityName: "Book")
    let books = try newContext.fetch(bookRequest)
    XCTAssertEqual(books.count, 52)
    books.forEach { object in
      object.materialize()
      //print(object)
      XCTAssertNotNil(object.value(forKey: #keyPath(BookV2.frontCover)))
    }
    
    //print(authors.first?.age)
    //    let personRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: "Person")
    //          XCTAssertEqual(try! newManagedObjectContext.executeFetchRequest(personRequest).count, 2)
    //    let teacherRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: "Teacher")
    //          XCTAssertEqual(try! newManagedObjectContext.executeFetchRequest(teacherRequest).count, 1)
    
    try! newContext.save()
    newContext._fix_sqlite_warning_when_destroying_a_store()
    //try FileManager.default.removeItem(at: url)
  }


//    func testMigrationFromV1toV2() throws {
//      // step 1: populate
//      let url = try createSampleVersion1()
//
//      try CoreDataPlus.Migration.migrateStore(at: url, targetVersion: SampleModel2.SampleModel2Version.version2)
//
//      let model = V2.makeManagedObjectModel()
//      let container = NSPersistentContainer(name: "SampleModel2", managedObjectModel: model)
//      container.persistentStoreDescriptions[0].url = url
//      container.loadPersistentStores { (_, error) in
//        XCTAssertNil(error)
//      }
//
//      let context = container.viewContext
//      let fr = V2.Author.fetchRequest()
//      //let fr = NSFetchRequest<NSFetchRequestResult>.init()
//      let res = try context.fetch(fr)
//      let authors = try V2.Author.fetch(in: context)
//      XCTAssertEqual(authors.count, 2)
//  }
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
