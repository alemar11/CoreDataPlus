// CoreDataPlus

import CoreData
import Foundation

// MARK: - V1

@objc(Book)
public class Book: NSManagedObject {
  @NSManaged public var uniqueID: UUID  // unique
  @NSManaged public var title: String
  @NSManaged public var price: NSDecimalNumber

  public var priceAsDecimal: Decimal { price.decimalValue }

  // ⚠️ This implementation may trigger memory issues and then crashes becasue
  // price is defined as Decimal while its primitive value is defined as NSDecimalNumber
  //
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

  @NSManaged public var cover: Cover
  @NSManaged public var publishedAt: Date
  @NSManaged public var author: Author
  @NSManaged public var pages: NSSet  // of Pages
  @NSManaged public var pagesCount: Int

  public override func validateForInsert() throws {
    // during a save, it's called for all the new objetcs
    // if the validation fails, the save method will thrown an error containing
    // all the validation failures
    try super.validateForInsert()
  }
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

@objc(GraphicNovel)
public class GraphicNovel: Book {
  @NSManaged public var isBlackAndWhite: Bool
}

// MARK: - V2

// Book:
// - cover has been ranamed frontCover

@objc(BookV2)
public class BookV2: NSManagedObject {
  @NSManaged public var uniqueID: UUID  // unique
  @NSManaged public var title: String
  @NSManaged public var price: NSDecimalNumber
  public var priceAsDecimal: Decimal { price.decimalValue }
  @NSManaged public var frontCover: Cover
  @NSManaged public var publishedAt: Date
  @NSManaged public var author: AuthorV2
  @NSManaged public var pages: NSSet  // of Pages
  @NSManaged public var pagesCount: Int
}

extension BookV2 {
  @objc(addPagesObject:)
  @NSManaged public func addToPages(_ value: PageV2)

  @objc(removePagesObject:)
  @NSManaged public func removeFromPages(_ value: PageV2)

  @objc(addPages:)
  @NSManaged public func addToPages(_ values: NSSet)

  @objc(removePages:)
  @NSManaged public func removeFromPages(_ values: NSSet)
}

@objc(GraphicNovelV2)
public class GraphicNovelV2: BookV2 {
  @NSManaged public var isBlackAndWhite: Bool
}

// MARK: - V3

// CoverV3:
// - new entity
// Book:
// - frontCover is a CoverV3 type

@objc(BookV3)
public class BookV3: NSManagedObject {
  @NSManaged public var uniqueID: UUID  // unique
  @NSManaged public var title: String
  @NSManaged public var price: NSDecimalNumber
  public var priceAsDecimal: Decimal { price.decimalValue }
  @NSManaged public var frontCover: CoverV3
  @NSManaged public var publishedAt: Date
  @NSManaged public var author: AuthorV3
  @NSManaged public var pages: NSSet  // of Pages
  @NSManaged public var pagesCount: Int
}

extension BookV3 {
  @objc(addPagesObject:)
  @NSManaged public func addToPages(_ value: PageV3)

  @objc(removePagesObject:)
  @NSManaged public func removeFromPages(_ value: PageV3)

  @objc(addPages:)
  @NSManaged public func addToPages(_ values: NSSet)

  @objc(removePages:)
  @NSManaged public func removeFromPages(_ values: NSSet)
}

@objc(GraphicNovelV3)
public class GraphicNovelV3: BookV3 {
  @NSManaged public var isBlackAndWhite: Bool
}
