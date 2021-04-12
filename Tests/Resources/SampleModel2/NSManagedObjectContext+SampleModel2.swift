// CoreDataPlus

import Foundation
import CoreData

extension NSManagedObjectContext {
  func fillWithSampleData2() {
    let author1 = Author(context: self)
    author1.alias = "Alessandro"
    author1.age = 40

    // author1 books

    let book1 = Book(context: self)
    //book1.price = Decimal(10.11)
    book1.price = NSDecimalNumber(10.11)
    book1.publishedAt = Date()
    book1.rating = 3.2
    book1.title = "title 1 - author 1"
    book1.uniqueID = UUID()

    (1..<100).forEach { index in
      let page = Page(context: self)
      page.book = book1
      page.number = Int32(index)
      page.isBookmarked = true
      book1.addToPages(page)
    }

    let book2 = Book(context: self)
    //book2.price = Decimal(3.3333333333)
    book2.price = NSDecimalNumber(3.3333333333)
    book2.publishedAt = Date()
    book2.rating = 5
    book2.title = "title 2 - author 1"
    book2.uniqueID = UUID()

    let book2Pages = NSMutableSet()
    (1..<2).forEach { index in
      let page = Page(context: self)
      page.book = book2
      page.number = Int32(index)
      page.isBookmarked = false
      book2Pages.add(page)
    }
    book2.addToPages(book2Pages)

    // TODO: add graphic novel
    let graphicNovel1 = GraphicNovel(context: self)
    graphicNovel1.price = NSDecimalNumber(3.3333333333)
    graphicNovel1.publishedAt = Date()
    graphicNovel1.rating = 5
    graphicNovel1.title = "title graphic novel - author 1"
    graphicNovel1.uniqueID = UUID()
    graphicNovel1.isBlackAndWhite = true

    let graphicNovel1Pages = NSMutableSet()
    (1..<20).forEach { index in
      let page = Page(context: self)
      page.book = graphicNovel1
      page.number = Int32(index)
      page.isBookmarked = index == 11
      graphicNovel1Pages.add(page)
    }
    graphicNovel1.addToPages(graphicNovel1Pages)

    book1.author = author1
    let author1Books = NSMutableSet()
    author1Books.add(book1)
    author1Books.add(book2)
    author1Books.add(graphicNovel1)
    author1.books = author1Books

    // author2 books
  }
}
