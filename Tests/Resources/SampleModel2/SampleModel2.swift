// CoreDataPlus

import CoreData
import XCTest
@testable import CoreDataPlus

enum SampleModel2 {
  static func makeManagedObjectModel() -> NSManagedObjectModel {
    let managedObjectModel = NSManagedObjectModel()
    let author = makeAuthorEntity()
    let book = makeBookEntity()
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
    bookToPages.isOptional = true
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
    //page.uniquenessConstraints += [[#keyPath(Page.book)]]

    managedObjectModel.entities = [author, book, page]
    return managedObjectModel
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

    let price = NSAttributeDescription.decimal(name: #keyPath(Book.price))
    price.isOptional = false

    let cover = NSAttributeDescription.binaryData(name: #keyPath(Book.cover))
    cover.isOptional = true

    let publishedAt = NSAttributeDescription.date(name: #keyPath(Book.publishedAt))
    publishedAt.isOptional = false

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

    //let number = NSAttributeDescription.int32(name: #keyPath(Page.number))
    //number.isOptional = false

    let isBookmarked = NSAttributeDescription.bool(name: #keyPath(Page.isBookmarked))
    isBookmarked.isOptional = false
    isBookmarked.defaultValue = false

    entity.properties = [isBookmarked]
    //entity.uniquenessConstraints = [[#keyPath(Page.number)]]
    return entity
  }

  static func fillWithSampleData(context: NSManagedObjectContext) throws {
    let author1 = Author(context: context)
    author1.alias = "Alessandro"

    let book1 = Book(context: context)
    book1.price = Decimal(10.11)
    book1.publishedAt = Date()
    book1.rating = 3.2
    book1.title = "title 1"
    book1.uniqueID = UUID()

    let mutableSet = NSMutableSet()
    (1..<100).forEach { index in
      let page = Page(context: context)
      page.book = book1
      page.isBookmarked = true
      mutableSet.add(page)

      //page.number = Int32(index)

      //book1.addToPages(page)
    }

    book1.pages = mutableSet

    let book2 = Book(context: context)
    book2.price = Decimal(3.3333333333)
    book2.publishedAt = Date()
    book2.rating = 5
    book2.title = "title 2"
    book2.uniqueID = UUID()

    book1.author = author1
    let author1Books = NSMutableSet()
    author1Books.add(book1)
    author1Books.add(book2)
    author1.books = author1Books
  }
}

// Author <-->> Book <--(Ordered)>> Page

@objc(Author)
public class Author: NSManagedObject {
  @NSManaged public var alias: String // unique
  @NSManaged public var siteURL: URL?
  @NSManaged public var books: NSSet // of Books
}

@objc(Book)
public class Book: NSManagedObject {
  @NSManaged public var uniqueID: UUID // unique
  @NSManaged public var title: String
  @objc var price: Decimal {
    // https://developer.apple.com/documentation/coredata/nsattributetype
    // NSDecimalNumber doesn't have a scalar type
    // https://stackoverflow.com/questions/23809462/data-type-mismatch-in-xcode-core-data-class
    get {
      willAccessValue(forKey: #keyPath(Book.price))
      defer { didAccessValue(forKey: #keyPath(Book.price)) }
      let pv = primitiveValue(forKey: #keyPath(Book.price)) as! NSDecimalNumber
      return pv.decimalValue
    }
    set {
      willChangeValue(forKey: #keyPath(Book.price))
      defer { didChangeValue(forKey: #keyPath(Book.price)) }
      setPrimitiveValue(NSDecimalNumber(decimal: newValue), forKey: #keyPath(Book.price))
    }
  }

  @NSManaged public var cover: Data?
  @NSManaged public var publishedAt: Date
  @NSManaged public var rating: Double
  @NSManaged public var author: Author
  @NSManaged public var pages: NSSet? // of Pages
}


//extension Book {
//
//    @objc(addPagesObject:)
//    @NSManaged public func addToPages(_ value: Page)
//
//    @objc(removePagesObject:)
//    @NSManaged public func removeFromPages(_ value: Page)
//
//    @objc(addPages:)
//    @NSManaged public func addToPages(_ values: NSSet)
//
//    @objc(removePages:)
//    @NSManaged public func removeFromPages(_ values: NSSet)
//
//}


@objc(Page)
public class Page: NSManagedObject {
  //@NSManaged public var number: Int32
  @NSManaged public var isBookmarked: Bool
  @NSManaged public var book: Book
}

// Missing fields: Int, Int16, Float, Transformable
