// CoreDataPlus

import CoreData

extension V1 {
  @objc(Page)
  public class Page: NSManagedObject {
    @NSManaged public var number: Int32
    @NSManaged public var isBookmarked: Bool
    @NSManaged public var content: Content?
    @NSManaged public var book: Book
    
    var isEmpty: Bool { content == .none }
  }
}

// MARK: - V1 to V2

extension V2 {
  @objc(Page)
  public class Page: NSManagedObject {
    @NSManaged public var number: Int32
    @NSManaged public var isBookmarked: Bool
    @NSManaged public var content: Content?
    @NSManaged public var book: Book
    
    var isEmpty: Bool { content == .none }
  }
}


