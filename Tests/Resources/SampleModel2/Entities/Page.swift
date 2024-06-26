// CoreDataPlus

import CoreData

// MARK: - V1

@objc(Page)
public class Page: NSManagedObject {
  @NSManaged public var number: Int32
  @NSManaged public var isBookmarked: Bool
  @NSManaged public var content: Content?
  @NSManaged public var book: Book

  var isEmpty: Bool { content == .none }
}

// MARK: - V2

@objc(PageV2)
public class PageV2: NSManagedObject {
  @NSManaged public var number: Int32
  @NSManaged public var isBookmarked: Bool
  @NSManaged public var content: Content?
  @NSManaged public var book: BookV2

  var isEmpty: Bool { content == .none }
}

// MARK: - V3

@objc(PageV3)
public class PageV3: NSManagedObject {
  @NSManaged public var number: Int32
  @NSManaged public var isBookmarked: Bool
  @NSManaged public var content: Content?
  @NSManaged public var book: BookV3

  var isEmpty: Bool { content == .none }
}
