// CoreDataPlus

import CoreData

extension V1 {
  @objc(Feedback)
  public class Feedback: NSManagedObject {
    @NSManaged public var bookID: UUID
    @NSManaged public var authorAlias: String
    @NSManaged public var comment: String
    @NSManaged public var rating: Double
  }
}

extension V2 {
  @objc(Feedback)
  public class Feedback: NSManagedObject {
    @NSManaged public var bookID: UUID
    @NSManaged public var authorAlias: String
    @NSManaged public var comment: String
    @NSManaged public var rating: Double
  }
}
