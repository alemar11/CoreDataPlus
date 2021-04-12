// CoreDataPlus

import CoreData

@objc(Page)
public class Page: NSManagedObject {
  @NSManaged public var number: Int32
  @NSManaged public var isBookmarked: Bool
  @NSManaged public var content: Content?
  @NSManaged public var book: Book

  var isEmpty: Bool { content == .none }
}

public class Content: NSObject, NSSecureCoding {
  public static var supportsSecureCoding: Bool { true }
  @objc public let text: String

  public init(text: String) {
    self.text = text
  }

  public func encode(with coder: NSCoder) {
    coder.encode(text, forKey: #keyPath(Content.text))
  }

  public required init?(coder decoder: NSCoder) {
    guard let text = decoder.decodeObject(of: [NSString.self], forKey: #keyPath(Content.text)) as? String else { return nil }
    self.text = text
  }
}
