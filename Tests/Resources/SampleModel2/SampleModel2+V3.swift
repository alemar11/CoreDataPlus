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
    bookToCover.deleteRule = .cascadeDeleteRule

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
    bookID.isOptional = true
    let rating = NSAttributeDescription.double(name: #keyPath(FeedbackV3.rating))
    rating.isOptional = false
    entity.add(authorAlias)
    entity.add(bookID)
    entity.add(comment)
    entity.add(rating)

    return entity
  }
}

extension V3 {
  @available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  static func makeMappingModelV2toV3() -> NSMappingModel {
    let mappingModel = NSMappingModel(from: [Bundle.tests], forSourceModel: V2.makeManagedObjectModel(), destinationModel: V3.makeManagedObjectModel())!

    // Writer
    let writerToWriter = NSEntityMapping()
    writerToWriter.name = "WriterV2toWriterV3"
    writerToWriter.mappingType = .copyEntityMappingType
    writerToWriter.sourceEntityName = "Writer"
    writerToWriter.destinationEntityName = "Writer"

    let agePropertyMapping = NSPropertyMapping()
    agePropertyMapping.name = #keyPath(WriterV3.age)
    agePropertyMapping.valueExpression = NSExpression(format: "$source.age")
    writerToWriter.attributeMappings = [agePropertyMapping]

    // Author
    let authorToAuthor = NSEntityMapping()
    authorToAuthor.name = "AuthorV2toAuthorV3"
    authorToAuthor.sourceEntityName = "Author"
    authorToAuthor.destinationEntityName = "Author"
    authorToAuthor.mappingType = .transformEntityMappingType // TODO: custom?

    let aliasPropertyMapping = NSPropertyMapping()
    aliasPropertyMapping.name = #keyPath(AuthorV3.alias)
    aliasPropertyMapping.valueExpression = NSExpression(format: "$source.alias")

    let socialURLPropertyMapping = NSPropertyMapping()
    socialURLPropertyMapping.name = #keyPath(AuthorV3.socialURL)

    let booksPropertyMapping = NSPropertyMapping()
    booksPropertyMapping.name = #keyPath(AuthorV3.books)
    booksPropertyMapping.valueExpression = NSExpression(format: "FUNCTION($manager, \"destinationInstancesForEntityMappingNamed:sourceInstances:\", \"BookV2toBookV3\", $source.books)")

    authorToAuthor.attributeMappings = [aliasPropertyMapping, socialURLPropertyMapping]
    authorToAuthor.relationshipMappings = [booksPropertyMapping]

    // Cover
    let cover = NSEntityMapping()
    cover.name = "Cover"
    cover.mappingType = .addEntityMappingType
    cover.sourceEntityName = nil
    cover.destinationEntityName = "Cover"

    let dataPropertyMapping = NSPropertyMapping()
    dataPropertyMapping.name = #keyPath(CoverV3.data)
    dataPropertyMapping.valueExpression = nil

    let bookPropertyMapping = NSPropertyMapping()
    bookPropertyMapping.name = #keyPath(CoverV3.book)
    bookPropertyMapping.valueExpression = nil

    cover.attributeMappings = [dataPropertyMapping]
    cover.relationshipMappings = [booksPropertyMapping]

    // Book
    let bookToBook = NSEntityMapping()
    bookToBook.name = "BookV2toBookV3"
    bookToBook.mappingType = .customEntityMappingType
    bookToBook.sourceEntityName = "Cover"
    bookToBook.destinationEntityName = "Cover"
    bookToBook.entityMigrationPolicyClassName = "BookV2toBookV3MigrationPolicy"

    let bookIdPropertyMapping = NSPropertyMapping()
    bookIdPropertyMapping.name = #keyPath(BookV3.uniqueID)
    bookIdPropertyMapping.valueExpression = NSExpression(format: "$source.uniqueID")

    let titlePropertyMapping = NSPropertyMapping()
    titlePropertyMapping.name = #keyPath(BookV3.title)
    titlePropertyMapping.valueExpression = NSExpression(format: "$source.title")

    let pricePropertyMapping = NSPropertyMapping()
    pricePropertyMapping.name = #keyPath(BookV3.price)
    pricePropertyMapping.valueExpression = NSExpression(format: "$source.price")

    let publishedAtPropertyMapping = NSPropertyMapping()
    publishedAtPropertyMapping.name = #keyPath(BookV3.publishedAt)
    publishedAtPropertyMapping.valueExpression = NSExpression(format: "$source.publishedAt")

    let pagesPropertyMapping = NSPropertyMapping()
    pagesPropertyMapping.name = #keyPath(BookV3.pages)
    pagesPropertyMapping.valueExpression = NSExpression(format: "FUNCTION($manager, \"destinationInstancesForEntityMappingNamed:sourceInstances:\", \"PageV2toPageV3\", $source.pages)")

    let authorPropertyMapping = NSPropertyMapping()
    authorPropertyMapping.name = #keyPath(BookV3.author)
    authorPropertyMapping.valueExpression = NSExpression(format: "$source.author")

    // TODO: cover
    // TODO: pageCount?
    bookToBook.attributeMappings = [booksPropertyMapping,
                                    titlePropertyMapping,
                                    pricePropertyMapping,
                                    publishedAtPropertyMapping,
                                    pagesPropertyMapping
    ]

    bookToBook.relationshipMappings = [pagesPropertyMapping, authorPropertyMapping]

    // Graphic Novel

    let graphicNovelToGraphicNovel = NSEntityMapping()
    graphicNovelToGraphicNovel.name = "GraphicNovelV2toGraphicNovelV3"
    graphicNovelToGraphicNovel.mappingType = .copyEntityMappingType
    graphicNovelToGraphicNovel.sourceEntityName = "GraphicNovel"
    graphicNovelToGraphicNovel.destinationEntityName = "GraphicNovel"

    let blackAndWhitePropertyMapping = NSPropertyMapping()
    blackAndWhitePropertyMapping.name = #keyPath(GraphicNovelV3.isBlackAndWhite)
    blackAndWhitePropertyMapping.valueExpression = NSExpression(format: "$source.isBlackAndWhite")

    graphicNovelToGraphicNovel.attributeMappings = [blackAndWhitePropertyMapping]

    // Page

    let pageToPage = NSEntityMapping()
    pageToPage.name = "PageV2toPageV3"
    pageToPage.mappingType = .copyEntityMappingType
    pageToPage.sourceEntityName = "Page"
    pageToPage.destinationEntityName = "Page"

    let numberPropertyMapping = NSPropertyMapping()
    numberPropertyMapping.name = #keyPath(PageV3.number)
    numberPropertyMapping.valueExpression = NSExpression(format: "$source.number")

    let pageBookPropertyMapping = NSPropertyMapping()
    pageBookPropertyMapping.name = #keyPath(PageV3.book)
    pageBookPropertyMapping.valueExpression = NSExpression(format: "$source.book")

    let isBookmarkedPropertyMapping = NSPropertyMapping()
    isBookmarkedPropertyMapping.name = #keyPath(PageV3.isBookmarked)
    isBookmarkedPropertyMapping.valueExpression = NSExpression(format: "$source.isBookmarked")

    let contentPropertyMapping = NSPropertyMapping()
    contentPropertyMapping.name = #keyPath(PageV3.content)
    contentPropertyMapping.valueExpression = NSExpression(format: "$source.content")

    pageToPage.attributeMappings = [numberPropertyMapping,
                                    isBookmarkedPropertyMapping,
                                    contentPropertyMapping]
    pageToPage.relationshipMappings = [pageBookPropertyMapping]

    // Feedback

    let feedbackToFeedback = NSEntityMapping()
    pageToPage.name = "FeedbackV2ToFeedbackV3"
    pageToPage.mappingType = .copyEntityMappingType
    pageToPage.sourceEntityName = "Feedback"
    pageToPage.destinationEntityName = "Feedback"

    let bookIDPropertyMapping = NSPropertyMapping()
    bookIDPropertyMapping.name = #keyPath(PageV3.content)
    bookIDPropertyMapping.valueExpression = NSExpression(format: "$source.bookID")

    let authorAliasPropertyMapping = NSPropertyMapping()
    authorAliasPropertyMapping.name = #keyPath(PageV3.content)
    authorAliasPropertyMapping.valueExpression = NSExpression(format: "$source.authorAlias")

    let commentPropertyMapping = NSPropertyMapping()
    commentPropertyMapping.name = #keyPath(PageV3.content)
    commentPropertyMapping.valueExpression = NSExpression(format: "$source.comment")

    let ratingPropertyMapping = NSPropertyMapping()
    ratingPropertyMapping.name = #keyPath(PageV3.content)
    ratingPropertyMapping.valueExpression = NSExpression(format: "$source.rating")

    feedbackToFeedback.attributeMappings = [bookIdPropertyMapping, authorAliasPropertyMapping, commentPropertyMapping, ratingPropertyMapping]

    mappingModel.entityMappings = [writerToWriter,
                                   authorToAuthor,
                                   cover,
                                   bookToBook,
                                   graphicNovelToGraphicNovel,
                                   pageToPage,
                                   feedbackToFeedback
    ]
    return mappingModel
  }
}

@objc(BookV2toBookV3MigrationPolicy)
class BookV2toBookV3MigrationPolicy: NSEntityMigrationPolicy {
  override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
    print("----")
  }
}
