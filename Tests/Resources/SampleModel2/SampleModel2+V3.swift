// CoreDataPlus

import CoreData
@testable import CoreDataPlus

extension V3 {
  enum Configurations {
    static let one = "SampleConfigurationV3" // all the entities
  }

  @available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  static func makeManagedObjectModel() -> NSManagedObjectModel {
    if let model = SampleModel2.modelCache["V3"] {
      return model
    }

    let managedObjectModel = NSManagedObjectModel()
    let writer = makeWriterEntity()
    let author = makeAuthorEntity()
    let book = makeBookEntity()
    let cover = makeCoverEntity()
    let graphicNovel = makeGraphicNovelEntity()
    let page = makePageEntity()
    let feedback = makeFeedbackEntity()

    // Definition using the CoreDataPlus convenience init
    let feedbackList = NSFetchedPropertyDescription(name: AuthorV3.FetchedProperty.feedbacks,
                                                    destinationEntity: feedback,
                                                    predicate: NSPredicate(format: "%K == $FETCH_SOURCE.%K", #keyPath(FeedbackV3.authorAlias), #keyPath(AuthorV3.alias)),
                                                    sortDescriptors: [NSSortDescriptor(key: #keyPath(FeedbackV3.rating), ascending: true)])
    author.add(feedbackList)

    // Definition without the CoreDataPlus convenience init
    let request2 = NSFetchRequest<NSFetchRequestResult>(entity: feedback)
    request2.resultType = .managedObjectResultType
    request2.predicate = NSPredicate(format: "authorAlias == $FETCH_SOURCE.alias AND (comment CONTAINS [c] $FETCHED_PROPERTY.userInfo.search)")
    let favFeedbackList = NSFetchedPropertyDescription()
    favFeedbackList.name = AuthorV3.FetchedProperty.favFeedbacks
    favFeedbackList.fetchRequest = request2
    favFeedbackList.userInfo?["search"] = "great"
    author.add(favFeedbackList)

    let authorToBooks = NSRelationshipDescription()
    authorToBooks.name = #keyPath(AuthorV3.books)
    authorToBooks.destinationEntity = book
    authorToBooks.isOptional = true
    authorToBooks.isOrdered = false
    authorToBooks.minCount = 0
    authorToBooks.maxCount = .max
    authorToBooks.deleteRule = .cascadeDeleteRule

    let bookToAuthor = NSRelationshipDescription()
    bookToAuthor.name = #keyPath(BookV3.author)
    bookToAuthor.destinationEntity = author
    bookToAuthor.isOptional = false
    bookToAuthor.isOrdered = false
    bookToAuthor.minCount = 1
    bookToAuthor.maxCount = 1
    bookToAuthor.deleteRule = .nullifyDeleteRule

    authorToBooks.inverseRelationship = bookToAuthor
    bookToAuthor.inverseRelationship = authorToBooks

    let coverToBook = NSRelationshipDescription()
    coverToBook.name = #keyPath(CoverV3.book)
    coverToBook.destinationEntity = book
    coverToBook.isOptional = false
    coverToBook.isOrdered = false
    coverToBook.minCount = 1
    coverToBook.maxCount = 1
    coverToBook.deleteRule = .cascadeDeleteRule

    let bookToCover = NSRelationshipDescription()
    bookToCover.name = #keyPath(Book.cover)
    bookToCover.destinationEntity = cover
    bookToCover.isOptional = false
    bookToCover.isOrdered = false
    bookToCover.minCount = 1
    bookToCover.maxCount = 1
    bookToCover.deleteRule = .nullifyDeleteRule

    coverToBook.inverseRelationship = bookToCover
    bookToCover.inverseRelationship = coverToBook

    let bookToPages = NSRelationshipDescription()
    bookToPages.name = #keyPath(BookV3.pages)
    bookToPages.destinationEntity = page
    bookToPages.isOptional = false
    bookToPages.isOrdered = false
    bookToPages.minCount = 1
    bookToPages.maxCount = 10_000
    bookToPages.deleteRule = .cascadeDeleteRule

    let pageToBook = NSRelationshipDescription()
    pageToBook.name = #keyPath(PageV3.book)
    pageToBook.destinationEntity = book
    pageToBook.isOptional = false
    pageToBook.isOrdered = false
    pageToBook.minCount = 1
    pageToBook.maxCount = 1
    pageToBook.deleteRule = .nullifyDeleteRule

    bookToPages.inverseRelationship = pageToBook
    pageToBook.inverseRelationship = bookToPages

    author.add(authorToBooks) // author.properties += [authorToBooks]
    book.properties += [bookToAuthor, bookToPages, bookToCover]
    cover.properties += [coverToBook]
    page.properties += [pageToBook]

    writer.subentities = [author]
    book.subentities = [graphicNovel]

    let entities = [writer, author, book, graphicNovel, page, feedback, cover]
    managedObjectModel.entities = entities
    managedObjectModel.setEntities(entities, forConfigurationName: Configurations.one)

    SampleModel2.modelCache["V3"] = managedObjectModel
    return managedObjectModel
  }

  static private func makeWriterEntity() -> NSEntityDescription {
    let entity = NSEntityDescription(for: WriterV3.self, withName: String(describing: Writer.self))
    entity.isAbstract = true

    let age = NSAttributeDescription.int16(name: #keyPath(WriterV3.age))
    age.isOptional = false

    entity.add(age)

    return entity
  }

  static private func makeAuthorEntity() -> NSEntityDescription {
    var entity = NSEntityDescription()
    entity = NSEntityDescription()
    entity.name = String(describing: Author.self) // 🚩 the entity name should stay the same
    entity.managedObjectClassName = String(describing: AuthorV3.self)

    // ✅ added in V3
    let socialURL = NSAttributeDescription.uri(name: #keyPath(AuthorV3.socialURL))
    socialURL.isOptional = true
    socialURL.renamingIdentifier = #keyPath(AuthorV3.socialURL)

    let alias = NSAttributeDescription.string(name: #keyPath(AuthorV3.alias))
    alias.isOptional = false

    entity.properties = [alias, socialURL]
    entity.uniquenessConstraints = [[#keyPath(AuthorV3.alias)]]

    let index = NSFetchIndexDescription(name: "authorIndex", elements: [NSFetchIndexElementDescription(property: alias, collationType: .binary)])
    entity.indexes.append(index)

    return entity
  }

  @available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  static private func makeCoverEntity() -> NSEntityDescription {
    var entity = NSEntityDescription()
    entity = NSEntityDescription()
    entity.name = String(describing: "Cover")
    entity.managedObjectClassName = String(describing: CoverV3.self)

    let data = NSAttributeDescription.binaryData(name: #keyPath(CoverV3.data))
    data.isOptional = false

    entity.properties = [data]
    return entity
  }

  @available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  static private func makeBookEntity() -> NSEntityDescription {
    var entity = NSEntityDescription()
    entity = NSEntityDescription()
    entity.name = String(describing: Book.self)
    entity.managedObjectClassName = String(describing: BookV3.self)

    let uniqueID = NSAttributeDescription.uuid(name: #keyPath(BookV3.uniqueID))
    uniqueID.isOptional = false

    let title = NSAttributeDescription.string(name: #keyPath(BookV3.title))
    title.isOptional = false
    let rule1 = (NSPredicate(format: "length >= 3 AND length <= 50"),"Title must have a length between 3 and 50 chars.")
    let rule2 = (NSPredicate(format: "SELF CONTAINS %@", "title"), "Title must contain 'title'.")
    title.setValidationPredicates([rule1.0, rule2.0], withValidationWarnings: [rule1.1, rule2.1])

    let price = NSAttributeDescription.decimal(name: #keyPath(BookV3.price))
    price.isOptional = false

    // ✅ Renamed cover as frontCover
    let defaultCover = Cover(text: "default cover")
    let cover = NSAttributeDescription.transformable(for: Cover.self, name: #keyPath(BookV3.frontCover), defaultValue: defaultCover)
    cover.isOptional = false

    let publishedAt = NSAttributeDescription.date(name: #keyPath(BookV3.publishedAt))
    publishedAt.isOptional = false

    let pagesCount = NSDerivedAttributeDescription(name: #keyPath(BookV3.pagesCount),
                                                   type: .integer64AttributeType,
                                                   derivationExpression: NSExpression(format: "pages.@count"))
    pagesCount.isOptional = true
    entity.properties = [uniqueID, title, price, cover, publishedAt, pagesCount]

    entity.uniquenessConstraints = [[#keyPath(BookV3.uniqueID)]]
    return entity
  }

  static private func makePageEntity() -> NSEntityDescription {
    var entity = NSEntityDescription()
    entity = NSEntityDescription()
    entity.name = String(describing: Page.self)
    entity.managedObjectClassName = String(describing: PageV3.self)

    let number = NSAttributeDescription.int32(name: #keyPath(PageV3.number))
    number.isOptional = false

    let isBookmarked = NSAttributeDescription.bool(name: #keyPath(PageV3.isBookmarked))
    isBookmarked.isOptional = false
    isBookmarked.defaultValue = false

    let content = NSAttributeDescription.customTransformable(for: Content.self, name: #keyPath(PageV3.content)) { //(content: Content?) -> Data? in
      guard let content = $0 else { return nil }
      return try? NSKeyedArchiver.archivedData(withRootObject: content, requiringSecureCoding: true)
    } reverse: { //data -> Content? in
      guard let data = $0 else { return nil }
      return try? NSKeyedUnarchiver.unarchivedObject(ofClass: Content.self, from: data)
    }
    content.isOptional = false

    entity.properties = [isBookmarked, number, content]
    return entity
  }

  static private func makeGraphicNovelEntity() -> NSEntityDescription {
    var entity = NSEntityDescription()
    entity = NSEntityDescription()
    entity.name = String(describing: GraphicNovel.self)
    entity.managedObjectClassName = String(describing: GraphicNovelV3.self)

    let isBlackAndWhite = NSAttributeDescription.bool(name: #keyPath(GraphicNovel.isBlackAndWhite))
    isBlackAndWhite.isOptional = false
    isBlackAndWhite.defaultValue = false

    entity.properties = [isBlackAndWhite]

    return entity
  }

  static private func makeFeedbackEntity() -> NSEntityDescription {
    let entity = NSEntityDescription(for: FeedbackV3.self, withName: String(describing: Feedback.self))
    let bookID = NSAttributeDescription.uuid(name: #keyPath(FeedbackV3.bookID))
    bookID.isOptional = false
    let authorAlias = NSAttributeDescription.string(name: #keyPath(FeedbackV3.authorAlias))
    authorAlias.isOptional = false
    let comment = NSAttributeDescription.string(name: #keyPath(FeedbackV3.comment))
    comment.isOptional = true
    let rating = NSAttributeDescription.double(name: #keyPath(FeedbackV3.rating))
    rating.isOptional = false
    entity.add(authorAlias)
    entity.add(bookID)
    entity.add(comment)
    entity.add(rating)

    return entity
  }
}

@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
extension V3 {

  static func makeCoverMapping() -> NSEntityMapping {
    let destinationEntityVersionHash = V3.makeManagedObjectModel().entityVersionHashesByName["Cover"]

    let mapping = NSEntityMapping()
    mapping.name = "Cover"
    mapping.mappingType = .addEntityMappingType
    mapping.sourceEntityName = nil
    mapping.destinationEntityName = "Cover"
    mapping.destinationEntityVersionHash = destinationEntityVersionHash

    let data = NSPropertyMapping()
    data.name = #keyPath(CoverV3.data)
    data.valueExpression = nil

    let book = NSPropertyMapping()
    book.name = #keyPath(CoverV3.book)
    book.valueExpression = nil

    mapping.attributeMappings = [data]
    mapping.relationshipMappings = [book]
    return mapping
  }

  static func makeBookMapping() -> NSEntityMapping {
    let mapping = NSEntityMapping()
    mapping.name = "BookToBook"
    mapping.mappingType = .customEntityMappingType
    mapping.sourceEntityName = "Book"
    mapping.destinationEntityName = "Book"
    mapping.entityMigrationPolicyClassName = String(describing: BookCoverToCoverMigrationPolicy.self)
    mapping.sourceEntityVersionHash = V2.makeBookEntity().versionHash
    mapping.destinationEntityVersionHash = V3.makeBookEntity().versionHash

    let uniqueID = NSPropertyMapping()
    uniqueID.name = #keyPath(BookV3.uniqueID)
    uniqueID.valueExpression = NSExpression(format: "$source.\(#keyPath(BookV2.uniqueID))")

    let title = NSPropertyMapping()
    title.name = #keyPath(BookV3.title)
    title.valueExpression = NSExpression(format: "$source.\(#keyPath(BookV2.title))")

    let price = NSPropertyMapping()
    price.name = #keyPath(BookV3.price)
    price.valueExpression = NSExpression(format: "$source.\(#keyPath(BookV2.price))")

    let publishedAt = NSPropertyMapping()
    publishedAt.name = #keyPath(BookV3.publishedAt)
    publishedAt.valueExpression = NSExpression(format: "$source.\(#keyPath(BookV2.publishedAt))")

    let pagesCount = NSPropertyMapping()
    pagesCount.name = #keyPath(BookV3.pagesCount)
    pagesCount.valueExpression = NSExpression(format: "$source.\(#keyPath(BookV2.pagesCount))")

    let pages = NSPropertyMapping()
    pages.name = #keyPath(BookV3.pages)
    pages.valueExpression = NSExpression(format: "FUNCTION($manager, \"destinationInstancesForEntityMappingNamed:sourceInstances:\", \"PageToPage\", $source.pages)")

    let author = NSPropertyMapping()
    author.name = #keyPath(BookV3.author)
    //author.valueExpression = NSExpression(format: "$source.author") // TODO
    author.valueExpression = NSExpression(format: "FUNCTION($manager, \"destinationInstancesForEntityMappingNamed:sourceInstances:\", \"AuthorToAuthor\", $source.\(#keyPath(BookV2.author)))")

    let frontCover = NSPropertyMapping()
    frontCover.name = #keyPath(BookV3.frontCover)

    mapping.attributeMappings = [pagesCount,
                                 price,
                                 publishedAt,
                                 title,
                                 uniqueID
    ]

    mapping.relationshipMappings = [author, frontCover, pages]
    mapping.sourceExpression = NSExpression(format: "FETCH(FUNCTION($manager, \"fetchRequestForSourceEntityNamed:predicateString:\" , \"Book\", \"TRUEPREDICATE\"), $manager.sourceContext, NO)")
    return mapping
  }

  static func makeGraphicNovelMapping() -> NSEntityMapping {
    let mapping = NSEntityMapping()
    mapping.name = "GraphicNovelToGraphicNovel"
    mapping.mappingType = .customEntityMappingType
    mapping.sourceEntityName = "GraphicNovel"
    mapping.destinationEntityName = "GraphicNovel"
    mapping.entityMigrationPolicyClassName = String(describing: BookCoverToCoverMigrationPolicy.self)
    mapping.sourceEntityVersionHash = V2.makeGraphicNovelEntity().versionHash
    mapping.destinationEntityVersionHash = V3.makeGraphicNovelEntity().versionHash

    let uniqueID = NSPropertyMapping()
    uniqueID.name = #keyPath(BookV3.uniqueID)
    uniqueID.valueExpression = NSExpression(format: "$source.\(#keyPath(GraphicNovelV2.uniqueID))")

    let title = NSPropertyMapping()
    title.name = #keyPath(BookV3.title)
    title.valueExpression = NSExpression(format: "$source.\(#keyPath(GraphicNovelV2.title))")

    let price = NSPropertyMapping()
    price.name = #keyPath(BookV3.price)
    price.valueExpression = NSExpression(format: "$source.\(#keyPath(GraphicNovelV2.price))")

    let publishedAt = NSPropertyMapping()
    publishedAt.name = #keyPath(BookV3.publishedAt)
    publishedAt.valueExpression = NSExpression(format: "$source.\(#keyPath(GraphicNovelV2.publishedAt))")

    let pageCount = NSPropertyMapping()
    pageCount.name = #keyPath(BookV3.pagesCount)
    pageCount.valueExpression = NSExpression(format: "$source.\(#keyPath(GraphicNovelV2.pagesCount))")

    let pages = NSPropertyMapping()
    pages.name = #keyPath(BookV3.pages)
    pages.valueExpression = NSExpression(format: "FUNCTION($manager, \"destinationInstancesForEntityMappingNamed:sourceInstances:\", \"PageToPage\", $source.\(#keyPath(BookV2.pages)))")

    let author = NSPropertyMapping()
    author.name = #keyPath(BookV3.author)
    //author.valueExpression = NSExpression(format: "$source.author") // TODO
    author.valueExpression = NSExpression(format: "FUNCTION($manager, \"destinationInstancesForEntityMappingNamed:sourceInstances:\", \"AuthorToAuthor\", $source.\(#keyPath(GraphicNovelV2.author)))")

    let frontCover = NSPropertyMapping()
    frontCover.name = #keyPath(BookV3.frontCover)

    let isBlackAndWhite = NSPropertyMapping()
    isBlackAndWhite.name = #keyPath(GraphicNovelV3.isBlackAndWhite)
    isBlackAndWhite.valueExpression = NSExpression(format: "$source.\(#keyPath(GraphicNovelV2.isBlackAndWhite))")

    mapping.attributeMappings = [isBlackAndWhite,
                                 pageCount,
                                 price,
                                 publishedAt,
                                 title,
                                 uniqueID,
    ]

    mapping.relationshipMappings = [author, frontCover, pages]
    mapping.sourceExpression = NSExpression(format: "FETCH(FUNCTION($manager, \"fetchRequestForSourceEntityNamed:predicateString:\" , \"GraphicNovel\", \"TRUEPREDICATE\"), $manager.sourceContext, NO)")
    return mapping
  }

  static func makeFeedbackMapping() -> NSEntityMapping {
    let mapping = NSEntityMapping()
    mapping.name = "FeedbackToFeedback"
    mapping.mappingType = .copyEntityMappingType
    mapping.sourceEntityName = "Feedback"
    mapping.destinationEntityName = "Feedback"
    mapping.sourceEntityVersionHash = V2.makeFeedbackEntity().versionHash
    mapping.destinationEntityVersionHash = V3.makeFeedbackEntity().versionHash

    let bookID = NSPropertyMapping()
    bookID.name = #keyPath(FeedbackV3.bookID)
    bookID.valueExpression = NSExpression(format: "$source.\(#keyPath(FeedbackV2.bookID))")
    //bookIDPropertyMapping.valueExpression = NSExpression(format: "FUNCTION($source, \"valueForKey:\", \"bookID\"") // TODO

    let authorAlias = NSPropertyMapping()
    authorAlias.name = #keyPath(FeedbackV3.authorAlias)
    authorAlias.valueExpression = NSExpression(format: "$source.\(#keyPath(FeedbackV2.authorAlias))")

    let comment = NSPropertyMapping()
    comment.name = #keyPath(FeedbackV3.comment)
    comment.valueExpression = NSExpression(format: "$source.\(#keyPath(FeedbackV2.comment))")

    let rating = NSPropertyMapping()
    rating.name = #keyPath(FeedbackV3.rating)
    rating.valueExpression = NSExpression(format: "$source.\(#keyPath(FeedbackV2.rating))")

    mapping.attributeMappings = [authorAlias, bookID, comment, rating]
    mapping.sourceExpression = NSExpression(format: "FETCH(FUNCTION($manager, \"fetchRequestForSourceEntityNamed:predicateString:\" , \"Feedback\", \"TRUEPREDICATE\"), $manager.sourceContext, NO)")

    return mapping
  }

  static func makePageMapping() -> NSEntityMapping {
    let sourceEntityVersionHash = V2.makeManagedObjectModel().entityVersionHashesByName["Page"]
    let destinationEntityVersionHash = V3.makeManagedObjectModel().entityVersionHashesByName["Page"]

    let mapping = NSEntityMapping()
    mapping.name = "PageToPage"
    mapping.mappingType = .copyEntityMappingType
    mapping.sourceEntityName = "Page"
    mapping.destinationEntityName = "Page"
    mapping.sourceEntityVersionHash = sourceEntityVersionHash
    mapping.destinationEntityVersionHash = destinationEntityVersionHash

    let number = NSPropertyMapping()
    number.name = #keyPath(PageV3.number)
    number.valueExpression = NSExpression(format: "$source.\(#keyPath(PageV2.number))")

    let book = NSPropertyMapping()
    book.name = #keyPath(PageV3.book)
    book.valueExpression = NSExpression(format: "FUNCTION($manager, \"destinationInstancesForSourceRelationshipNamed:sourceInstances:\", \"book\", $source.\(#keyPath(PageV2.book)))")

    let isBookmarked = NSPropertyMapping()
    isBookmarked.name = #keyPath(PageV3.isBookmarked)
    isBookmarked.valueExpression = NSExpression(format: "$source.\(#keyPath(PageV2.isBookmarked))")

    let content = NSPropertyMapping()
    content.name = #keyPath(PageV3.content)
    content.valueExpression = NSExpression(format: "$source.\(#keyPath(PageV2.content))")

    mapping.attributeMappings = [content, isBookmarked, number]
    mapping.relationshipMappings = [book]
    mapping.sourceExpression = NSExpression(format: "FETCH(FUNCTION($manager, \"fetchRequestForSourceEntityNamed:predicateString:\" , \"Page\", \"TRUEPREDICATE\"), $manager.sourceContext, NO)")
    return mapping
  }

  static func makeAuthorMapping() -> NSEntityMapping {
    let sourceEntityVersionHash = V2.makeManagedObjectModel().entityVersionHashesByName["Author"]
    let destinationEntityVersionHash = V3.makeManagedObjectModel().entityVersionHashesByName["Author"]

    // Author
    let mapping = NSEntityMapping()
    mapping.name = "AuthorToAuthor"
    mapping.sourceEntityName = "Author"
    mapping.destinationEntityName = "Author"
    mapping.mappingType = .copyEntityMappingType
    mapping.sourceEntityVersionHash = sourceEntityVersionHash
    mapping.destinationEntityVersionHash = destinationEntityVersionHash

    let alias = NSPropertyMapping()
    alias.name = #keyPath(AuthorV3.alias)
    alias.valueExpression = NSExpression(format: "$source.\(#keyPath(AuthorV2.alias))")

    let socialURL = NSPropertyMapping()
    socialURL.name = #keyPath(AuthorV3.socialURL)

    let age = NSPropertyMapping()
    age.name = #keyPath(WriterV3.age)
    age.valueExpression = NSExpression(format: "$source.\(#keyPath(AuthorV2.age))")

    let books = NSPropertyMapping()
    books.name = #keyPath(AuthorV3.books)
    books.valueExpression = NSExpression(format: "FUNCTION($manager, \"destinationInstancesForSourceRelationshipNamed:sourceInstances:\", \"books\", $source.\(#keyPath(AuthorV2.books)))")

    mapping.attributeMappings = [age, alias, socialURL]
    mapping.relationshipMappings = [books]
    mapping.sourceExpression = NSExpression(format: "FETCH(FUNCTION($manager, \"fetchRequestForSourceEntityNamed:predicateString:\" , \"Author\", \"TRUEPREDICATE\"), $manager.sourceContext, NO)")
    return mapping
  }

  static func makeMappingModelV2toV3() -> NSMappingModel {
    let mappingModel = NSMappingModel()

    mappingModel.entityMappings.append(makeGraphicNovelMapping())
    mappingModel.entityMappings.append(makeFeedbackMapping())
    mappingModel.entityMappings.append(makePageMapping())
    mappingModel.entityMappings.append(makeAuthorMapping())
    mappingModel.entityMappings.append(makeCoverMapping())
    mappingModel.entityMappings.append(makeBookMapping())

    return mappingModel
  }
}

@objc(BookCoverToCoverMigrationPolicy)
class BookCoverToCoverMigrationPolicy: NSEntityMigrationPolicy {
  override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
    try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)

    guard let frontCover = sInstance.value(forKey: "frontCover") as? Cover else {
      return
    }

    guard let book = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance]).first else {
      fatalError("must return book") }

    guard let context = book.managedObjectContext else {
      fatalError("must have context")
    }

    let cover = NSEntityDescription.insertNewObject(forEntityName: "Cover", into: context)
    cover.setValue(frontCover.text.data(using: .utf8), forKey: "data")
    cover.setValue(book, forKey: "book")
  }
}
