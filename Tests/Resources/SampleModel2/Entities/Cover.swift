// CoreDataPlus

import Foundation

public class Cover: NSObject, NSSecureCoding {
  public static var supportsSecureCoding: Bool { true }
  public let text: String

  public init(text: String) {
    self.text = text
  }

  public func encode(with coder: NSCoder) {
    coder.encode(text, forKey: "text")
  }

  public required init?(coder decoder: NSCoder) {
    guard let text = decoder.decodeObject(of: [NSString.self], forKey: "text") as? String else { return nil }
    self.text = text
  }
}
