// CoreDataPlus

import CoreData

@available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, visionOS 1.0, iOSApplicationExtension 17.0, *)
extension NSCompositeAttributeDescription {
  /// Creates a new `NSCompositeAttributeDescription` instance.
  /// - Parameters:
  ///   - name: The name of the composite attribute.
  ///   - elements: The composed attribute descriptions.
  /// - Warning: Composite attributes are available only to persistent stores that you configure with the **sqlite** store type.
  public convenience init(name: String, elements: [NSAttributeDescription]) {
    self.init()
    self.name = name
    self.elements = elements
  }
}
