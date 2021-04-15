// CoreDataPlus

import CoreData
@testable import CoreDataPlus

extension SampleModel2.V1 {
  enum Configurations {
    static let one = "SampleConfigurationV1"
  }
  @available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  static func makeManagedObjectModel() -> NSManagedObjectModel {
    let managedObjectModel = NSManagedObjectModel()
    let writer = makeWriterEntity()
    let author = makeAuthorEntity()
    let book = makeBookEntity()
    let graphicNovel = makeGraphicNovelEntity()
    let page = makePageEntity()
    let feedback = makeFeedbackEntity()


    // Definition using the CoreDataPlus convenience init
    let feedbackList = NSFetchedPropertyDescription(name: V1.Author.FetchedProperty.feedbacks,
                                                    destinationEntity: feedback,
                                                    predicate: NSPredicate(format: "%K == $FETCH_SOURCE.%K", #keyPath(Feedback.authorAlias), #keyPath(Author.alias)),
                                                    sortDescriptors: [NSSortDescriptor(key: #keyPath(Feedback.rating), ascending: true)])

    // Definition without the CoreDataPlus convenience init
//    let request = NSFetchRequest<NSFetchRequestResult>(entity: feedback)
//    request.resultType = .managedObjectResultType
//    request.predicate = NSPredicate(format: "%K == $FETCH_SOURCE.%K", #keyPath(Feedback.authorAlias), #keyPath(Author.alias))
//    request.sortDescriptors = [NSSortDescriptor(key: #keyPath(Feedback.rating), ascending: true)]
//    let feedbackList = NSFetchedPropertyDescription()
//    feedbackList.name = Author.FetchedProperty.feedbacks
//    feedbackList.fetchRequest = request

    author.add(feedbackList)

    // Definition without the CoreDataPlus convenience init
    let request2 = NSFetchRequest<NSFetchRequestResult>(entity: feedback)
    request2.resultType = .managedObjectResultType
    request2.predicate = NSPredicate(format: "authorAlias == $FETCH_SOURCE.alias AND (comment CONTAINS [c] $FETCHED_PROPERTY.userInfo.search)")
    let favFeedbackList = NSFetchedPropertyDescription()
    favFeedbackList.name = V1.Author.FetchedProperty.favFeedbacks
    favFeedbackList.fetchRequest = request2
    favFeedbackList.userInfo?["search"] = "great"
    author.add(favFeedbackList)

    let authorToBooks = NSRelationshipDescription()
    authorToBooks.name = #keyPath(Author.books)
    authorToBooks.destinationEntity = book
    authorToBooks.isOptional = true
    authorToBooks.isOrdered = false
    authorToBooks.minCount = 0
    authorToBooks.maxCount = .max
    authorToBooks.deleteRule = .cascadeDeleteRule

    let bookToAuthor = NSRelationshipDescription()
    bookToAuthor.name = #keyPath(Book.author)
    bookToAuthor.destinationEntity = author
    bookToAuthor.isOptional = false
    bookToAuthor.isOrdered = false
    bookToAuthor.minCount = 1
    bookToAuthor.maxCount = 1
    bookToAuthor.deleteRule = .nullifyDeleteRule

    authorToBooks.inverseRelationship = bookToAuthor
    bookToAuthor.inverseRelationship = authorToBooks

    let bookToPages = NSRelationshipDescription()
    bookToPages.name = #keyPath(Book.pages)
    bookToPages.destinationEntity = page
    bookToPages.isOptional = false
    bookToPages.isOrdered = false
    bookToPages.minCount = 1
    bookToPages.maxCount = 10_000
    bookToPages.deleteRule = .cascadeDeleteRule

    let pageToBook = NSRelationshipDescription()
    pageToBook.name = #keyPath(Page.book)
    pageToBook.destinationEntity = book
    pageToBook.isOptional = false
    pageToBook.isOrdered = false
    pageToBook.minCount = 1
    pageToBook.maxCount = 1
    pageToBook.deleteRule = .nullifyDeleteRule

    author.add(authorToBooks) // author.properties += [authorToBooks]
    book.properties += [bookToAuthor, bookToPages]
    page.properties += [pageToBook]

    var pageUniquenessConstraints = page.uniquenessConstraints.flatMap { $0 }
    pageUniquenessConstraints.append(#keyPath(Page.book))
    page.uniquenessConstraints = [pageUniquenessConstraints]

    writer.subentities = [author]
    book.subentities = [graphicNovel]
    
    let entities = [writer, author, book, graphicNovel, page, feedback]
    managedObjectModel.entities = entities
    managedObjectModel.setEntities(entities, forConfigurationName: Configurations.one)
    return managedObjectModel
  }

  static private func makeWriterEntity() -> NSEntityDescription {
    let entity = NSEntityDescription(Writer.self)
    entity.isAbstract = true

    let age = NSAttributeDescription.int16(name: #keyPath(Writer.age))
    age.isOptional = false

    entity.add(age)

    return entity
  }

  static private func makeAuthorEntity() -> NSEntityDescription {
    var entity = NSEntityDescription()
    entity = NSEntityDescription()
    entity.name = String(describing: Author.self)
    entity.managedObjectClassName = String(describing: Author.self)

    let alias = NSAttributeDescription.string(name: #keyPath(Author.alias))
    alias.isOptional = false

    let siteURL = NSAttributeDescription.uri(name: #keyPath(Author.siteURL))
    siteURL.isOptional = true

    entity.properties = [alias, siteURL]
    entity.uniquenessConstraints = [[#keyPath(Author.alias)]]

    let index = NSFetchIndexDescription(name: "authorIndex", elements: [NSFetchIndexElementDescription(property: alias, collationType: .binary)])
    entity.indexes.append(index)

    return entity
  }

  @available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  static private func makeBookEntity() -> NSEntityDescription {
    var entity = NSEntityDescription()
    entity = NSEntityDescription()
    entity.name = String(describing: Book.self)
    entity.managedObjectClassName = String(describing: Book.self)

    let uniqueID = NSAttributeDescription.uuid(name: #keyPath(Book.uniqueID))
    uniqueID.isOptional = false

    let title = NSAttributeDescription.string(name: #keyPath(Book.title))
    title.isOptional = false
    // validation predicates are evaluated on validateForInsert(), overriding validateForInsert() without calling its
    // super implementation will ignore these predicates
    let rule1 = (NSPredicate(format: "length >= 3 AND length <= 50"),"Title must have a length between 3 and 50 chars.")
    let rule2 = (NSPredicate(format: "SELF CONTAINS %@", "title"), "Title must contain 'title'.")
    title.setValidationPredicates([rule1.0, rule2.0], withValidationWarnings: [rule1.1, rule2.1])

    let price = NSAttributeDescription.decimal(name: #keyPath(Book.price))
    price.isOptional = false

    let defaultCover = Cover(text: "default cover")
    let cover = NSAttributeDescription.transformable(for: Cover.self, name: #keyPath(Book.cover), defaultValue: defaultCover)
    cover.isOptional = false

    let publishedAt = NSAttributeDescription.date(name: #keyPath(Book.publishedAt))
    publishedAt.isOptional = false
    //let twelveHoursAgo = Date().addingTimeInterval(-43200)
    //let publishedAtPredicate = NSPredicate(format: "timeIntervalSinceReferenceDate < %@", twelveHoursAgo.timeIntervalSinceReferenceDate)
    //publishedAt.setValidationPredicates([publishedAtPredicate], withValidationWarnings: ["Date error"])

    let pagesCount = NSDerivedAttributeDescription(name: #keyPath(Book.pagesCount),
                                                   type: .integer64AttributeType,
                                                   derivationExpression: NSExpression(format: "pages.@count"))
    pagesCount.isOptional = true
    entity.properties = [uniqueID, title, price, cover, publishedAt, pagesCount]

    entity.uniquenessConstraints = [[#keyPath(Book.uniqueID)]]
    return entity
  }

  static private func makePageEntity() -> NSEntityDescription {
    var entity = NSEntityDescription()
    entity = NSEntityDescription()
    entity.name = String(describing: Page.self)
    entity.managedObjectClassName = String(describing: Page.self)

    let number = NSAttributeDescription.int32(name: #keyPath(Page.number))
    number.isOptional = false

    let isBookmarked = NSAttributeDescription.bool(name: #keyPath(Page.isBookmarked))
    isBookmarked.isOptional = false
    isBookmarked.defaultValue = false

    let content = NSAttributeDescription.customTransformable(for: Content.self, name: #keyPath(Page.content)) { //(content: Content?) -> Data? in
      guard let content = $0 else { return nil }
      return try? NSKeyedArchiver.archivedData(withRootObject: content, requiringSecureCoding: true)
    } reverse: { //data -> Content? in
      guard let data = $0 else { return nil }
      return try? NSKeyedUnarchiver.unarchivedObject(ofClass: Content.self, from: data)
    }
    content.isOptional = false

    entity.properties = [isBookmarked, number, content]
    entity.uniquenessConstraints = [[#keyPath(Page.number)]]
    return entity
  }

  static private func makeGraphicNovelEntity() -> NSEntityDescription {
    var entity = NSEntityDescription()
    entity = NSEntityDescription()
    entity.name = String(describing: GraphicNovel.self)
    entity.managedObjectClassName = String(describing: GraphicNovel.self)

    let isBlackAndWhite = NSAttributeDescription.bool(name: #keyPath(GraphicNovel.isBlackAndWhite))
    isBlackAndWhite.isOptional = false
    isBlackAndWhite.defaultValue = false

    entity.properties = [isBlackAndWhite]

    return entity
  }

  static private func makeFeedbackEntity() -> NSEntityDescription {
    let entity = NSEntityDescription(Feedback.self)
    let bookID = NSAttributeDescription.uuid(name: #keyPath(Feedback.bookID))
    bookID.isOptional = false
    let authorAlias = NSAttributeDescription.string(name: #keyPath(Feedback.authorAlias))
    authorAlias.isOptional = false
    let comment = NSAttributeDescription.string(name: #keyPath(Feedback.comment))
    bookID.isOptional = true
    let rating = NSAttributeDescription.double(name: #keyPath(Feedback.rating))
    rating.isOptional = false
    entity.add(authorAlias)
    entity.add(bookID)
    entity.add(comment)
    entity.add(rating)

    return entity
  }
}
