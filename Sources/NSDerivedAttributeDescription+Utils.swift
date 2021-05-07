// CoreDataPlus
// https://developer.apple.com/documentation/coredata/nsderivedattributedescription

import CoreData

@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
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
