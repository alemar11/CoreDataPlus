// CoreDataPlus

import CoreData

@testable import CoreDataPlus

extension V2 {
  enum Configurations {
    static let part1 = "SampleConfigurationV2Part1"  // all the entities
    static let part2 = "SampleConfigurationV2Part2"  // only Feedback
  }

  static func makeManagedObjectModel() -> NSManagedObjectModel {
    if let model = SampleModel2.modelCache.withLock({ $0["V2"] }) {
      return model
    }

    let managedObjectModel = NSManagedObjectModel()
    let writer = makeWriterEntity()
    let author = makeAuthorEntity()
    let book = makeBookEntity()
    let graphicNovel = makeGraphicNovelEntity()
    let page = makePageEntity()
    let feedback = makeFeedbackEntity()

    // Definition using the CoreDataPlus convenience init
    let feedbackList = NSFetchedPropertyDescription(
      name: AuthorV2.FetchedProperty.feedbacks, destinationEntity: feedback
    ) {
      $0.predicate = NSPredicate(
        format: "%K == $FETCH_SOURCE.%K", #keyPath(FeedbackV2.authorAlias), #keyPath(AuthorV2.alias))
      $0.sortDescriptors = [NSSortDescriptor(key: #keyPath(FeedbackV2.rating), ascending: true)]
    }
    author.add(feedbackList)

    // Definition without the CoreDataPlus convenience init
    let request2 = NSFetchRequest<NSFetchRequestResult>(entity: feedback)
    request2.resultType = .managedObjectResultType
    request2.predicate = NSPredicate(
      format: "authorAlias == $FETCH_SOURCE.alias AND (comment CONTAINS [c] $FETCHED_PROPERTY.userInfo.search)")
    let favFeedbackList = NSFetchedPropertyDescription()
    favFeedbackList.name = AuthorV2.FetchedProperty.favFeedbacks
    favFeedbackList.fetchRequest = request2
    favFeedbackList.userInfo?["search"] = "great"
    author.add(favFeedbackList)

    let authorToBooks = NSRelationshipDescription()
    authorToBooks.name = #keyPath(AuthorV2.books)
    authorToBooks.destinationEntity = book
    authorToBooks.isOptional = true
    authorToBooks.isOrdered = false
    authorToBooks.minCount = 0
    authorToBooks.maxCount = .max
    authorToBooks.deleteRule = .cascadeDeleteRule

    let bookToAuthor = NSRelationshipDescription()
    bookToAuthor.name = #keyPath(BookV2.author)
    bookToAuthor.destinationEntity = author
    bookToAuthor.isOptional = false
    bookToAuthor.isOrdered = false
    bookToAuthor.minCount = 1
    bookToAuthor.maxCount = 1
    bookToAuthor.deleteRule = .nullifyDeleteRule

    authorToBooks.inverseRelationship = bookToAuthor
    bookToAuthor.inverseRelationship = authorToBooks

    let bookToPages = NSRelationshipDescription()
    bookToPages.name = #keyPath(BookV2.pages)
    bookToPages.destinationEntity = page
    bookToPages.isOptional = false
    bookToPages.isOrdered = false
    bookToPages.minCount = 1
    bookToPages.maxCount = 10_000
    bookToPages.deleteRule = .cascadeDeleteRule

    let pageToBook = NSRelationshipDescription()
    pageToBook.name = #keyPath(PageV2.book)
    pageToBook.destinationEntity = book
    pageToBook.isOptional = false
    pageToBook.isOrdered = false
    pageToBook.minCount = 1
    pageToBook.maxCount = 1
    pageToBook.deleteRule = .nullifyDeleteRule

    bookToPages.inverseRelationship = pageToBook
    pageToBook.inverseRelationship = bookToPages

    author.add(authorToBooks)  // author.properties += [authorToBooks]
    book.properties += [bookToAuthor, bookToPages]
    page.properties += [pageToBook]

    writer.subentities = [author]
    book.subentities = [graphicNovel]

    // Relationships can't be split between different stores (configurations)
    // "Feedback" is related to "Author" only via a fetched property and can be moved safely to another store
    // but, in order to migrate all the feedbacks from store 1 to store 2, we need a step in where the both the configurations
    // have the "Feedback" entity; doing so, once the migration is completed we can:
    // 1. load store 1 with the migrated url
    // 2. load another store - store 2 - with a different url (this db is going to be empty)
    // 3. move all the "Feedback" records from store 1 to store 2 (this can be done because both the stores have "Feedback" in their configurations)
    // 4. delete all the "Feedback" records from store 1 (optional)
    // 5. (alternative to 4) create a migration for store 1 in where the "Feedback" entity is deleted and removed from its configuration. At this point store 1 an store 2 will have 2 separate models.migration
    let entities = [writer, author, book, graphicNovel, page, feedback]
    managedObjectModel.entities = entities
    managedObjectModel.setEntities([writer, author, book, page, feedback], forConfigurationName: Configurations.part1)
    managedObjectModel.setEntities([feedback], forConfigurationName: Configurations.part2)
    SampleModel2.modelCache.withLock { $0["V2"] = managedObjectModel }

    return managedObjectModel
  }

  static func makeWriterEntity() -> NSEntityDescription {
    let entity = NSEntityDescription(for: WriterV2.self, withName: String(describing: Writer.self))
    entity.isAbstract = true

    let age = NSAttributeDescription.int16(name: #keyPath(WriterV2.age))
    age.isOptional = false

    entity.add(age)

    return entity
  }

  static func makeAuthorEntity() -> NSEntityDescription {
    var entity = NSEntityDescription()
    entity = NSEntityDescription()
    entity.name = String(describing: Author.self)  // 🚩 the entity name should stay the same
    entity.managedObjectClassName = String(describing: AuthorV2.self)

    // ❌ Removed siteURL

    let alias = NSAttributeDescription.string(name: #keyPath(AuthorV2.alias))
    alias.isOptional = false

    entity.properties = [alias]
    entity.uniquenessConstraints = [[#keyPath(AuthorV2.alias)]]

    let index = NSFetchIndexDescription(
      name: "authorIndex", elements: [NSFetchIndexElementDescription(property: alias, collationType: .binary)])
    entity.indexes.append(index)

    return entity
  }

  static func makeBookEntity() -> NSEntityDescription {
    var entity = NSEntityDescription()
    entity = NSEntityDescription()
    entity.name = String(describing: Book.self)
    entity.managedObjectClassName = String(describing: BookV2.self)

    let uniqueID = NSAttributeDescription.uuid(name: #keyPath(BookV2.uniqueID))
    uniqueID.isOptional = false

    let title = NSAttributeDescription.string(name: #keyPath(BookV2.title))
    title.isOptional = false
    let rule1 = (
      NSPredicate(format: "length >= 3 AND length <= 50"), "Title must have a length between 3 and 50 chars."
    )
    let rule2 = (NSPredicate(format: "SELF CONTAINS %@", "title"), "Title must contain 'title'.")
    title.setValidationPredicates([rule1.0, rule2.0], withValidationWarnings: [rule1.1, rule2.1])

    let price = NSAttributeDescription.decimal(name: #keyPath(BookV2.price))
    price.isOptional = false

    // ✅ Renamed cover as frontCover
    let defaultCover = Cover(text: "default cover")
    let cover = NSAttributeDescription.transformable(
      for: Cover.self, name: #keyPath(BookV2.frontCover), defaultValue: defaultCover)
    cover.isOptional = false
    cover.renamingIdentifier = #keyPath(Book.cover)

    let publishedAt = NSAttributeDescription.date(name: #keyPath(BookV2.publishedAt))
    publishedAt.isOptional = false

    let pagesCount = NSDerivedAttributeDescription(
      name: #keyPath(BookV2.pagesCount),
      type: .integer64,
      derivationExpression: NSExpression(format: "pages.@count"))
    pagesCount.isOptional = true
    entity.properties = [uniqueID, title, price, cover, publishedAt, pagesCount]

    entity.uniquenessConstraints = [[#keyPath(BookV2.uniqueID)]]
    return entity
  }

  static func makePageEntity() -> NSEntityDescription {
    var entity = NSEntityDescription()
    entity = NSEntityDescription()
    entity.name = String(describing: Page.self)
    entity.managedObjectClassName = String(describing: PageV2.self)

    let number = NSAttributeDescription.int32(name: #keyPath(PageV2.number))
    number.isOptional = false

    let isBookmarked = NSAttributeDescription.bool(name: #keyPath(PageV2.isBookmarked))
    isBookmarked.isOptional = false
    isBookmarked.defaultValue = false

    let content = NSAttributeDescription.customTransformable(for: Content.self, name: #keyPath(PageV2.content)) {
      guard let content = $0 else { return nil }
      return try? NSKeyedArchiver.archivedData(withRootObject: content, requiringSecureCoding: true)
    } reverse: {  //data -> Content? in
      guard let data = $0 else { return nil }
      return try? NSKeyedUnarchiver.unarchivedObject(ofClass: Content.self, from: data)
    }
    content.isOptional = false

    entity.properties = [isBookmarked, number, content]
    return entity
  }

  static func makeGraphicNovelEntity() -> NSEntityDescription {
    var entity = NSEntityDescription()
    entity = NSEntityDescription()
    entity.name = String(describing: GraphicNovel.self)
    entity.managedObjectClassName = String(describing: GraphicNovelV2.self)

    let isBlackAndWhite = NSAttributeDescription.bool(name: #keyPath(GraphicNovel.isBlackAndWhite))
    isBlackAndWhite.isOptional = false
    isBlackAndWhite.defaultValue = false

    entity.properties = [isBlackAndWhite]

    return entity
  }

  static func makeFeedbackEntity() -> NSEntityDescription {
    let entity = NSEntityDescription(for: FeedbackV2.self, withName: String(describing: Feedback.self))
    let bookID = NSAttributeDescription.uuid(name: #keyPath(FeedbackV2.bookID))
    bookID.isOptional = false
    let authorAlias = NSAttributeDescription.string(name: #keyPath(FeedbackV2.authorAlias))
    authorAlias.isOptional = false
    let comment = NSAttributeDescription.string(name: #keyPath(FeedbackV2.comment))
    comment.isOptional = true
    let rating = NSAttributeDescription.double(name: #keyPath(FeedbackV2.rating))
    rating.isOptional = false
    entity.add(authorAlias)
    entity.add(bookID)
    entity.add(comment)
    entity.add(rating)

    return entity
  }
}
