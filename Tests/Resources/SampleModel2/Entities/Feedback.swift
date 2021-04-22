// CoreDataPlus

import CoreData

// MARK: - V1

@objc(Feedback)
public class Feedback: NSManagedObject {
  @NSManaged public var bookID: UUID
  @NSManaged public var authorAlias: String
  @NSManaged public var comment: String
  @NSManaged public var rating: Double
}

// MARK: - V2

@objc(FeedbackV2)
public class FeedbackV2: NSManagedObject {
  @NSManaged public var bookID: UUID
  @NSManaged public var authorAlias: String
  @NSManaged public var comment: String
  @NSManaged public var rating: Double
}

// MARK: - V3

@objc(FeedbackV3)
public class FeedbackV3: NSManagedObject {
  @NSManaged public var bookID: UUID
  @NSManaged public var authorAlias: String
  @NSManaged public var comment: String
  @NSManaged public var rating: Double
}

