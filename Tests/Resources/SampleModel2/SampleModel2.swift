// CoreDataPlus

import CoreData
import XCTest
@testable import CoreDataPlus
import CoreData.CoreDataDefines

enum SampleModel2 {
  static func makeManagedObjectModel() -> NSManagedObjectModel {
    let managedObjectModel = NSManagedObjectModel()
    let writer = makeWriterEntity()
    let author = makeAuthorEntity()
    let book = makeBookEntity()
    let graphicNovel = makeGraphicNovelEntity()
    let page = makePageEntity()

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

    author.properties += [authorToBooks]
    book.properties += [bookToAuthor, bookToPages]
    page.properties += [pageToBook]

    var pageUniquenessConstraints = page.uniquenessConstraints.flatMap { $0 }
    pageUniquenessConstraints.append(#keyPath(Page.book))
    page.uniquenessConstraints = [pageUniquenessConstraints]

    writer.subentities = [author]
    book.subentities = [graphicNovel]

    managedObjectModel.entities = [writer, author, book, graphicNovel, page]
    return managedObjectModel
  }

  static private func makeWriterEntity() -> NSEntityDescription {
    var entity = NSEntityDescription()
    entity = NSEntityDescription()
    entity.name = String(describing: Writer.self)
    entity.managedObjectClassName = String(describing: Writer.self)

    let age = NSAttributeDescription.int16(name: #keyPath(Writer.age))
    age.isOptional = false

    entity.isAbstract = true
    entity.properties = [age]

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
    let rule1 = (NSPredicate(format: "length >= 3 AND length <= 20"),"Title must have a length between 3 and 20 chars.")
    let rule2 = (NSPredicate(format: "SELF CONTAINS %@", "title"), "Title must contain 'title'.")
    title.setValidationPredicates([rule1.0, rule2.0], withValidationWarnings: [rule1.1, rule2.1])

    let price = NSAttributeDescription.decimal(name: #keyPath(Book.price))
    price.isOptional = false

    let cover = NSAttributeDescription.binaryData(name: #keyPath(Book.cover))
    cover.isOptional = true

    let publishedAt = NSAttributeDescription.date(name: #keyPath(Book.publishedAt))
    publishedAt.isOptional = false
    //let twelveHoursAgo = Date().addingTimeInterval(-43200)
    //Date().timeIntervalSinceReferenceDate
    //let publishedAtPredicate = NSPredicate(format: "timeIntervalSinceReferenceDate < %@", twelveHoursAgo.timeIntervalSinceReferenceDate)
    //publishedAt.setValidationPredicates([publishedAtPredicate], withValidationWarnings: ["Date error"])

    let rating = NSAttributeDescription.double(name: #keyPath(Book.rating))
    rating.isOptional = false

    entity.properties = [uniqueID, title, price, cover, publishedAt, rating]
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

    entity.properties = [isBookmarked, number]
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
}

extension SampleModel2 {
  static func fillWithSampleData(context: NSManagedObjectContext) {
    let author1 = Author(context: context)
    author1.alias = "Alessandro"
    author1.age = 40

    let book1 = Book(context: context)
    //book1.price = Decimal(10.11)
    book1.price = NSDecimalNumber(10.11)
    book1.publishedAt = Date()
    book1.rating = 3.2
    book1.title = "title 1"
    book1.uniqueID = UUID()

    (1..<100).forEach { index in
      let page = Page(context: context)
      page.book = book1
      page.number = Int32(index)
      page.isBookmarked = true
      book1.addToPages(page)
    }

    let book2 = Book(context: context)
    //book2.price = Decimal(3.3333333333)
    book2.price = NSDecimalNumber(3.3333333333)
    book2.publishedAt = Date()
    book2.rating = 5
    book2.title = "title 2"
    book2.uniqueID = UUID()

    let book2Pages = NSMutableSet()
    (1..<2).forEach { index in
      let page = Page(context: context)
      page.book = book2
      page.number = Int32(index)
      page.isBookmarked = false
      book2Pages.add(page)
    }
    //book2.pages = book2Pages
    book2.addToPages(book2Pages)

    // TODO: add graphic novel


    book1.author = author1
    let author1Books = NSMutableSet()
    author1Books.add(book1)
    author1Books.add(book2)
    author1.books = author1Books
  }
}

// Author <-->> Book <--(Ordered)>> Page

@objc(Writer)
public class Writer: NSManagedObject {
  @NSManaged public var age: Int16
}

@objc(Author)
public class Author: Writer {
  @NSManaged public var alias: String // unique
  @NSManaged public var siteURL: URL?
  @NSManaged public var books: NSSet // of Books
}

@objc(Book)
public class Book: NSManagedObject {
  @NSManaged public var uniqueID: UUID // unique
  @NSManaged public var title: String
  @NSManaged public var price: NSDecimalNumber

//  @objc var price: Decimal {
//    // https://developer.apple.com/documentation/coredata/nsattributetype
//    // NSDecimalNumber doesn't have a scalar type
//    // https://stackoverflow.com/questions/23809462/data-type-mismatch-in-xcode-core-data-class
//    get {
//      willAccessValue(forKey: #keyPath(Book.price))
//      defer { didAccessValue(forKey: #keyPath(Book.price)) }
//      let pv = primitiveValue(forKey: #keyPath(Book.price)) as! NSDecimalNumber
//      return pv.decimalValue
//    }
//    set {
//      willChangeValue(forKey: #keyPath(Book.price))
//      defer { didChangeValue(forKey: #keyPath(Book.price)) }
//      setPrimitiveValue(NSDecimalNumber(decimal: newValue), forKey: #keyPath(Book.price))
//    }
//  }

  @NSManaged public var cover: Data?
  @NSManaged public var publishedAt: Date
  @NSManaged public var rating: Double
  @NSManaged public var author: Author
  @NSManaged public var pages: NSSet // of Pages

  public override func validateForInsert() throws {
    // during a save, it's called for all the new objetcs
    // if the validation fails, the save method will thrown an error containing
    // all the validation failures
    try super.validateForInsert()
    //return

//    let attributes = entity.attributesByName.map { $0.value }
//    let errors = attributes.compactMap { attribute -> [NSError]? in
//      let rules = zip(attribute.validationPredicates, attribute.validationWarnings)
//
//      let errors = rules.compactMap { (predicate, warning) -> NSError? in
//        return validateRule((predicate,warning), for: attribute.name)
//      }
//      return errors
//    }.flatMap { $0 }
//
//    if !errors.isEmpty {
//      throw errors.first!
//    }
    
//    if !errors.isEmpty {
//      let code = NSValidationMultipleErrorsError
//      let domain = NSCocoaErrorDomain
//      let userInfo: [String: Any] = [
//        NSLocalizedDescriptionKey: "Multiple validation errors occurred.",
//        NSDetailedErrorsKey: errors
//      ]
//      let error = NSError(domain: domain, code: code, userInfo: userInfo)
//      throw error
//    }
  }

//  typealias Rule = (NSPredicate, Any)
//  func validateRule(_ rule: Rule, for name: String) -> NSError? {
//    let valueToValidate = self.value(forKey: name)
//    let result = rule.0.evaluate(with: valueToValidate)
//    if !result {
//      let userInfo: [String: Any] = [
//        NSLocalizedDescriptionKey: rule.1,
//        NSValidationObjectErrorKey: self
//      ]
//      let code = NSManagedObjectValidationError
//      let domain = NSCocoaErrorDomain
//      let error = NSError(domain: domain, code: code, userInfo: userInfo)
//      return error
//    }
//    return nil
//  }
}


extension Book {

    @objc(addPagesObject:)
    @NSManaged public func addToPages(_ value: Page)

    @objc(removePagesObject:)
    @NSManaged public func removeFromPages(_ value: Page)

    @objc(addPages:)
    @NSManaged public func addToPages(_ values: NSSet)

    @objc(removePages:)
    @NSManaged public func removeFromPages(_ values: NSSet)

}


@objc(Page)
public class Page: NSManagedObject {
  @NSManaged public var number: Int32
  @NSManaged public var isBookmarked: Bool
  @NSManaged public var book: Book
}

@objc(GraphicNovel)
public class GraphicNovel: NSManagedObject {
  @NSManaged public var isBlackAndWhite: Bool
}

// Missing fields: Int, Int16, Float, Transformable

// Learn about uniquenessConstraints [[Any]]

// indexes
