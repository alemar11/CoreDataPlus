// CoreDataPlus
// https://developer.apple.com/documentation/coredata/nsderivedattributedescription

import CoreData

extension NSDerivedAttributeDescription {
  /// Creates a new `NSDerivedAttributeDescription` instance.
  /// - Parameters:
  ///   - name: The name of the derived attribute.
  ///   - type: The type of the derived attribute.
  ///   - derivationExpression: An expression for generating derived data.
  public convenience init(name: String, type: NSAttributeType, derivationExpression: NSExpression) {
    self.init()
    self.name = name
    self.attributeType = type
    self.derivationExpression = derivationExpression
  }
}
