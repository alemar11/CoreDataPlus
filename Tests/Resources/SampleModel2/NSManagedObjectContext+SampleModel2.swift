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
    book1.title = "title 1 - author 1"
    book1.uniqueID = UUID()

    (1..<100).forEach { index in
      let page = Page(context: self)
      page.book = book1
      page.number = Int32(index)
      page.isBookmarked = true
      page.content = Content(text: "content for page \(index)")
      book1.addToPages(page)
    }

    let book2 = Book(context: self)
    //book2.price = Decimal(3.3333333333)
    book2.price = NSDecimalNumber(3.3333333333)
    book2.publishedAt = Date()
    book2.title = "title 2 - author 1"
    book2.uniqueID = UUID()

    let book2Pages = NSMutableSet()
    (1..<2).forEach { index in
      let page = Page(context: self)
      page.book = book2
      page.number = Int32(index)
      page.isBookmarked = false
      page.content = Content(text: "content for page \(index)")
      book2Pages.add(page)
    }
    book2.addToPages(book2Pages)

    let graphicNovel1 = GraphicNovel(context: self)
    graphicNovel1.price = NSDecimalNumber(3.3333333333)
    graphicNovel1.publishedAt = Date()
    graphicNovel1.title = "title graphic novel - author 1"
    graphicNovel1.uniqueID = UUID()
    graphicNovel1.isBlackAndWhite = true
    graphicNovel1.cover = Cover(text: "Cover Graphic Novel")

    let graphicNovel1Pages = NSMutableSet()
    (1..<20).forEach { index in
      let page = Page(context: self)
      page.book = graphicNovel1
      page.number = Int32(index)
      page.isBookmarked = index == 11
      page.content = Content(text: "content for page \(index)")
      graphicNovel1Pages.add(page)
    }
    graphicNovel1.addToPages(graphicNovel1Pages)

    book1.author = author1
    let author1Books = NSMutableSet()
    author1Books.add(book1)
    author1Books.add(book2)
    author1Books.add(graphicNovel1)
    author1.books = author1Books

    let feedbackBook1 = Feedback(context: self)
    feedbackBook1.bookID = book1.uniqueID
    feedbackBook1.rating = 4.2
    feedbackBook1.comment = "great book"
    feedbackBook1.authorAlias = author1.alias

    let feedbackBook2 = Feedback(context: self)
    feedbackBook2.bookID = book2.uniqueID
    feedbackBook2.rating = 3.5
    feedbackBook2.comment = "interesting book"
    feedbackBook2.authorAlias = author1.alias

    let feedbackGrapthicNovel1 = Feedback(context: self)
    feedbackGrapthicNovel1.bookID = graphicNovel1.uniqueID
    feedbackGrapthicNovel1.rating = 4.3
    feedbackGrapthicNovel1.comment = "great novel"
    feedbackGrapthicNovel1.authorAlias = author1.alias
  }
}
