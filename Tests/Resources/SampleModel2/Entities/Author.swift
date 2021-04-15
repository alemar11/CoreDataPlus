// CoreDataPlus

import Foundation
import CoreData

extension V1 {
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
}

extension V1.Author {
  public enum FetchedProperty {
    static let feedbacks = "feedbacks"
    static let favFeedbacks = "favFeedbacks"
  }

  // Xcode doesn't generate the accessor for fetched properties (if you are using Xcode code gen).

  // feedbacks ordered by rating ASC
  public var feedbacks: [V1.Feedback]? { // it should probably be a NSArray to avoid prefetching all the objects
    return value(forKey: FetchedProperty.feedbacks) as? [V1.Feedback]
  }

  // feedbacks with the "great" word in their comments
  public var favFeedbacks: [V1.Feedback]? {
    return value(forKey: FetchedProperty.favFeedbacks) as? [V1.Feedback]
  }
}

// MARK: - V1 to V2
// Author:
// - siteURL is removed


@objc(WriterV2)
public class WriterV2: NSManagedObject {
  @NSManaged public var age: Int16
}

@objc(AuthorV2)
public class AuthorV2: WriterV2 {
  @NSManaged public var alias: String // unique
  @NSManaged public var books: NSSet // of Books
}

extension AuthorV2 {
  public enum FetchedProperty {
    static let feedbacks = "feedbacks"
    static let favFeedbacks = "favFeedbacks"
  }

  // Xcode doesn't generate the accessor for fetched properties (if you are using Xcode code gen).

  // feedbacks ordered by rating ASC
  public var feedbacks: [FeedbackV2]? { // it should probably be a NSArray to avoid prefetching all the objects
    return value(forKey: FetchedProperty.feedbacks) as? [FeedbackV2]
  }

  // feedbacks with the "great" word in their comments
  public var favFeedbacks: [FeedbackV2]? {
    return value(forKey: FetchedProperty.favFeedbacks) as? [FeedbackV2]
  }
}
