// CoreDataPlus

import CoreData
import Foundation

/// A generic `NSSecureUnarchiveFromDataTransformer` subclass to implement CoreData *Transformable* attributes.
///
/// - Note: Core Data requires the transformer be NSSecureUnarchiveFromData or its subclass,
/// and that its transformedValue(_:) method converts a Data object to an instance of the custom class specified in Data Model Inspector and that reverseTransformedValue(_:)
/// does the opposite – converts an instance of the custom class to a Data object.
public final class Transformer<T: NSObject & NSSecureCoding>: NSSecureUnarchiveFromDataTransformer {
  /// The name of the transformer. It's used when registering the transformer using `Transformer.register()`.
  /// It's composed combining the T class name and the suffix "Transformer" (i.e. if T is Object, the transformer name is *ObjectTransformer*).
  public static var transformerName: NSValueTransformerName {
    let transformerName = "\(T.self.classForCoder())" + "Transformer"
    return NSValueTransformerName(transformerName)
  }

  /// Registers the value transformer.
  public static func register() {
    let transformer = Transformer<T>()
    Foundation.ValueTransformer.setValueTransformer(transformer, forName: Self.transformerName)
  }

  /// Unregisters the value transformer.
  public static func unregister() {
    if Foundation.ValueTransformer.valueTransformerNames().contains(Self.transformerName) {
      Foundation.ValueTransformer.setValueTransformer(nil, forName: Self.transformerName)
    }
  }

  public override static func transformedValueClass() -> AnyClass { T.self }

  public override class func allowsReverseTransformation() -> Bool { true }

  public class override var allowedTopLevelClasses: [AnyClass] { [T.self] }

  public override func transformedValue(_ value: Any?) -> Any? {
    // Data -> T
    // CoreData calls this method during saves (write)
    // transformedValue(_:) and reverseTransformedValue(_:) methods for NSSecureUnarchiveFromDataTransformer subclasses are called
    // in the opposite way than on ValuteTransformer subclasses
    guard let data = value as? Data else { return nil }
    return super.transformedValue(data)  // super returns an instance of T
  }

  public override func reverseTransformedValue(_ value: Any?) -> Any? {
    // T -> Data
    // CoreData calls this method during fetches (read).
    // context: this method may be called during a save
    guard let receivedValue = value as? T else { return nil }

    return super.reverseTransformedValue(receivedValue)  // super returns a Data object
  }
}
