// CoreDataPlus

import CoreData
import Foundation

// MARK: - V1

@objc(Writer)
public class Writer: NSManagedObject {
  @NSManaged public var age: Int16
}

@objc(Author)
public class Author: Writer {
  @NSManaged public var alias: String  // unique
  @NSManaged public var siteURL: URL?
  @NSManaged public var books: NSSet  // of Books
}

extension Author {
  public enum FetchedProperty {
    static let feedbacks = "feedbacks"
    static let favFeedbacks = "favFeedbacks"
  }

  // Xcode doesn't generate the accessor for fetched properties (if you are using Xcode code gen).

  // feedbacks ordered by rating ASC
  public var feedbacks: [Feedback]? {  // it should probably be a NSArray to avoid prefetching all the objects
    value(forKey: FetchedProperty.feedbacks) as? [Feedback]
  }

  // feedbacks with the "great" word in their comments
  public var favFeedbacks: [Feedback]? {
    value(forKey: FetchedProperty.favFeedbacks) as? [Feedback]
  }
}

// MARK: - V2

// Author:
// - siteURL is removed

@objc(WriterV2)
public class WriterV2: NSManagedObject {
  @NSManaged public var age: Int16
}

@objc(AuthorV2)
public class AuthorV2: WriterV2 {
  @NSManaged public var alias: String  // unique
  @NSManaged public var books: NSSet  // of Books
}

extension AuthorV2 {
  public enum FetchedProperty {
    static let feedbacks = "feedbacks"
    static let favFeedbacks = "favFeedbacks"
  }

  // Xcode doesn't generate the accessor for fetched properties (if you are using Xcode code gen).

  // feedbacks ordered by rating ASC
  public var feedbacks: [FeedbackV2]? {  // it should probably be a NSArray to avoid prefetching all the objects
    value(forKey: FetchedProperty.feedbacks) as? [FeedbackV2]
  }

  // feedbacks with the "great" word in their comments
  public var favFeedbacks: [FeedbackV2]? {
    value(forKey: FetchedProperty.favFeedbacks) as? [FeedbackV2]
  }
}

// MARK: - V3

// Author:
// - socialURL is added

@objc(WriterV3)
public class WriterV3: NSManagedObject {
  @NSManaged public var age: Int16
}

@objc(AuthorV3)
public class AuthorV3: WriterV3 {
  @NSManaged public var alias: String  // unique
  @NSManaged public var socialURL: URL?
  @NSManaged public var books: NSSet  // of Books
}

extension AuthorV3 {
  public enum FetchedProperty {
    static let feedbacks = "feedbacks"
    static let favFeedbacks = "favFeedbacks"
  }

  // Xcode doesn't generate the accessor for fetched properties (if you are using Xcode code gen).

  // feedbacks ordered by rating ASC
  public var feedbacks: [FeedbackV3]? {  // it should probably be a NSArray to avoid prefetching all the objects
    value(forKey: FetchedProperty.feedbacks) as? [FeedbackV3]
  }

  // feedbacks with the "great" word in their comments
  public var favFeedbacks: [FeedbackV3]? {
    value(forKey: FetchedProperty.favFeedbacks) as? [FeedbackV3]
  }
}
