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

@objc(FeedbackV2)
public class FeedbackV2: NSManagedObject {
  @NSManaged public var bookID: UUID
  @NSManaged public var authorAlias: String
  @NSManaged public var comment: String
  @NSManaged public var rating: Double
}

