// CoreDataPlus

import CoreData
import Foundation

extension NSManagedObjectContext {
  func fillWithSampleData2() {
    fillWithAuthor1()  // Author with 2 books and 1 Graphic Novel
    fillWithAuthor2()  // Author with 49 books
  }

  func fillWithSampleData2UsingModelV2() {
    fillWithAuthor1UsingModelV2()
  }

  func fillWithSampleData2UsingModelV3() {
    fillWithAuthor1UsingModelV3()
  }

  func fillWithAuthor1() {
    let author = Author(context: self)
    author.alias = "Alessandro"
    author.age = 40

    let book1 = Book(context: self)
    //book1.price = Decimal(10.11)
    book1.price = NSDecimalNumber(10.11)
    book1.publishedAt = Date()
    book1.title = "title 1 - author 1"
    book1.uniqueID = UUID()

    for index in 1..<100 {
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
    for index in 1..<2 {
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
    for index in 1..<20 {
      let page = Page(context: self)
      page.book = graphicNovel1
      page.number = Int32(index)
      page.isBookmarked = index == 11
      page.content = Content(text: "content for page \(index)")
      graphicNovel1Pages.add(page)
    }
    graphicNovel1.addToPages(graphicNovel1Pages)

    book1.author = author
    let author1Books = NSMutableSet()
    author1Books.add(book1)
    author1Books.add(book2)
    author1Books.add(graphicNovel1)
    author.books = author1Books

    let feedbackBook1 = Feedback(context: self)
    feedbackBook1.bookID = book1.uniqueID
    feedbackBook1.rating = 4.2
    feedbackBook1.comment = "great book"
    feedbackBook1.authorAlias = author.alias

    let feedbackBook2 = Feedback(context: self)
    feedbackBook2.bookID = book2.uniqueID
    feedbackBook2.rating = 3.5
    feedbackBook2.comment = "interesting book"
    feedbackBook2.authorAlias = author.alias

    let feedbackGrapthicNovel1 = Feedback(context: self)
    feedbackGrapthicNovel1.bookID = graphicNovel1.uniqueID
    feedbackGrapthicNovel1.rating = 4.3
    feedbackGrapthicNovel1.comment = "great novel"
    feedbackGrapthicNovel1.authorAlias = author.alias
  }

  func fillWithAuthor2() {
    let author = Author(context: self)
    author.alias = "Andrea"
    author.age = 30

    for index in 1..<50 {
      let book = Book(context: self)
      book.price = NSDecimalNumber(10.11)
      book.publishedAt = Date()
      book.title = "title \(index) - author 2"
      book.uniqueID = UUID()
      book.author = author

      for index in 1..<100 {
        let page = Page(context: self)
        page.book = book
        page.number = Int32(index)
        page.isBookmarked = true
        page.content = Content(text: "content for page \(index)")
        book.addToPages(page)
      }

      for _ in 1..<10 {
        let feedbackBook1 = Feedback(context: self)
        feedbackBook1.bookID = book.uniqueID
        feedbackBook1.rating = [1.3, 2.4, 3.5, 4.6, 5.8].randomElement()!
        let comment = ["great book", "interesting book"].randomElement()!
        feedbackBook1.comment = comment
        feedbackBook1.authorAlias = author.alias
      }
    }
  }

  func fillWithAuthor1UsingModelV2() {
    let author = AuthorV2(context: self)
    author.alias = "Alessandro"
    author.age = 40

    let book1 = BookV2(context: self)
    //book1.price = Decimal(10.11)
    book1.price = NSDecimalNumber(10.11)
    book1.publishedAt = Date()
    book1.title = "title 1 - author 1"
    book1.uniqueID = UUID()

    for index in 1..<100 {
      let page = PageV2(context: self)
      page.book = book1
      page.number = Int32(index)
      page.isBookmarked = true
      page.content = Content(text: "content for page \(index)")
      book1.addToPages(page)
    }

    let book2 = BookV2(context: self)
    //book2.price = Decimal(3.3333333333)
    book2.price = NSDecimalNumber(3.3333333333)
    book2.publishedAt = Date()
    book2.title = "title 2 - author 1"
    book2.uniqueID = UUID()

    let book2Pages = NSMutableSet()
    for index in 1..<2 {
      let page = PageV2(context: self)
      page.book = book2
      page.number = Int32(index)
      page.isBookmarked = false
      page.content = Content(text: "content for page \(index)")
      book2Pages.add(page)
    }
    book2.addToPages(book2Pages)

    let graphicNovel1 = GraphicNovelV2(context: self)
    graphicNovel1.price = NSDecimalNumber(3.3333333333)
    graphicNovel1.publishedAt = Date()
    graphicNovel1.title = "title graphic novel - author 1"
    graphicNovel1.uniqueID = UUID()
    graphicNovel1.isBlackAndWhite = true
    graphicNovel1.frontCover = Cover(text: "Cover Graphic Novel")

    let graphicNovel1Pages = NSMutableSet()
    for index in 1..<20 {
      let page = PageV2(context: self)
      page.book = graphicNovel1
      page.number = Int32(index)
      page.isBookmarked = index == 11
      page.content = Content(text: "content for page \(index)")
      graphicNovel1Pages.add(page)
    }
    graphicNovel1.addToPages(graphicNovel1Pages)

    book1.author = author
    let author1Books = NSMutableSet()
    author1Books.add(book1)
    author1Books.add(book2)
    author1Books.add(graphicNovel1)
    author.books = author1Books

    let feedbackBook1 = FeedbackV2(context: self)
    feedbackBook1.bookID = book1.uniqueID
    feedbackBook1.rating = 4.2
    feedbackBook1.comment = "great book"
    feedbackBook1.authorAlias = author.alias

    let feedbackBook2 = FeedbackV2(context: self)
    feedbackBook2.bookID = book2.uniqueID
    feedbackBook2.rating = 3.5
    feedbackBook2.comment = "interesting book"
    feedbackBook2.authorAlias = author.alias

    let feedbackGrapthicNovel1 = FeedbackV2(context: self)
    feedbackGrapthicNovel1.bookID = graphicNovel1.uniqueID
    feedbackGrapthicNovel1.rating = 4.3
    feedbackGrapthicNovel1.comment = "great novel"
    feedbackGrapthicNovel1.authorAlias = author.alias
  }

  func fillWithAuthor1UsingModelV3() {
    let author = AuthorV3(context: self)
    author.alias = "Alessandro"
    author.age = 40

    let book1 = BookV3(context: self)
    //book1.price = Decimal(10.11)
    book1.price = NSDecimalNumber(10.11)
    book1.publishedAt = Date()
    book1.title = "title 1 - author 1"
    book1.uniqueID = UUID()

    let coverForBook1 = CoverV3(context: self)
    coverForBook1.data = "Cover book 1".data(using: .utf8)!
    book1.frontCover = coverForBook1
    coverForBook1.book = book1

    for index in 1..<100 {
      let page = PageV3(context: self)
      page.book = book1
      page.number = Int32(index)
      page.isBookmarked = true
      page.content = Content(text: "content for page \(index)")
      book1.addToPages(page)
    }

    let book2 = BookV3(context: self)
    //book2.price = Decimal(3.3333333333)
    book2.price = NSDecimalNumber(3.3333333333)
    book2.publishedAt = Date()
    book2.title = "title 2 - author 1"
    book2.uniqueID = UUID()

    let coverForBook2 = CoverV3(context: self)
    coverForBook2.data = "Cover book 2".data(using: .utf8)!
    book2.frontCover = coverForBook2
    coverForBook2.book = book2

    let book2Pages = NSMutableSet()
    for index in 1..<2 {
      let page = PageV3(context: self)
      page.book = book2
      page.number = Int32(index)
      page.isBookmarked = false
      page.content = Content(text: "content for page \(index)")
      book2Pages.add(page)
    }
    book2.addToPages(book2Pages)

    let graphicNovel1 = GraphicNovelV3(context: self)
    graphicNovel1.price = NSDecimalNumber(3.3333333333)
    graphicNovel1.publishedAt = Date()
    graphicNovel1.title = "title graphic novel - author 1"
    graphicNovel1.uniqueID = UUID()
    graphicNovel1.isBlackAndWhite = true

    let coverForGraphicNovel1 = CoverV3(context: self)
    coverForGraphicNovel1.data = "Cover Graphic Novel".data(using: .utf8)!
    graphicNovel1.frontCover = coverForGraphicNovel1
    coverForGraphicNovel1.book = graphicNovel1

    let graphicNovel1Pages = NSMutableSet()
    for index in 1..<20 {
      let page = PageV3(context: self)
      page.book = graphicNovel1
      page.number = Int32(index)
      page.isBookmarked = index == 11
      page.content = Content(text: "content for page \(index)")
      graphicNovel1Pages.add(page)
    }
    graphicNovel1.addToPages(graphicNovel1Pages)

    book1.author = author
    let author1Books = NSMutableSet()
    author1Books.add(book1)
    author1Books.add(book2)
    author1Books.add(graphicNovel1)
    author.books = author1Books

    let feedbackBook1 = FeedbackV3(context: self)
    feedbackBook1.bookID = book1.uniqueID
    feedbackBook1.rating = 4.2
    feedbackBook1.comment = "great book"
    feedbackBook1.authorAlias = author.alias

    let feedbackBook2 = FeedbackV3(context: self)
    feedbackBook2.bookID = book2.uniqueID
    feedbackBook2.rating = 3.5
    feedbackBook2.comment = "interesting book"
    feedbackBook2.authorAlias = author.alias

    let feedbackGrapthicNovel1 = FeedbackV3(context: self)
    feedbackGrapthicNovel1.bookID = graphicNovel1.uniqueID
    feedbackGrapthicNovel1.rating = 4.3
    feedbackGrapthicNovel1.comment = "great novel"
    feedbackGrapthicNovel1.authorAlias = author.alias
  }
}
