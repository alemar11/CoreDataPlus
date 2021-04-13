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

extension Author {
  enum FetchedProperty {
    static let feedbacks = "feedbacks"
    static let favFeedbacks = "favFeedbacks"
  }

  // Xcode doesn't generate the accessor for fetched properties (if you are using Xcode code gen).

  // feedbacks ordered by rating ASC
  var feedbacks: [Feedback]? { // it should probably be a NSArray to avoid prefetching all the objects
    return value(forKey: FetchedProperty.feedbacks) as? [Feedback]
  }

  // feedbacks with the "great" word in their comments
  var favFeedbacks: [Feedback]? {
    return value(forKey: FetchedProperty.favFeedbacks) as? [Feedback]
  }
}
