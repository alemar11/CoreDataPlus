// CoreDataPlus

import Foundation
import CoreData

// Author <-->> Book <--(Ordered)>> Page

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


@objc(Page)
public class Page: NSManagedObject {
  @NSManaged public var number: Int32
  @NSManaged public var isBookmarked: Bool
  @NSManaged public var book: Book
}

@objc(GraphicNovel)
public class GraphicNovel: Book {
  @NSManaged public var isBlackAndWhite: Bool
}
