// CoreDataPlus
// https://developer.apple.com/documentation/coredata/nsderivedattributedescription

import CoreData

extension NSDerivedAttributeDescription {
  /// Creates a new `NSDerivedAttributeDescription` instance.
  /// - Parameters:
  ///   - name: The name of the derived attribute.
  ///   - type: The type of the derived attribute.
  ///   - derivationExpression: An expression for generating derived data.
  /// - Warning: Data recomputes derived attributes when you save a context. A managed object’s property does not reflect unsaved changes until you save the context and refresh the object.
  public convenience init(name: String, type: NSAttributeDescription.AttributeType, derivationExpression: NSExpression) {
    self.init()
    self.name = name
    self.type = type
    self.derivationExpression = derivationExpression
  }
}
