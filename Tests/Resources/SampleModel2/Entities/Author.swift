// CoreDataPlus

import Foundation
import CoreData

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
