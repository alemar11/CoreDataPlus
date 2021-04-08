// CoreDataPlus

import CoreData
import Foundation

/// Generic transformer to implement *Transformable* attributes.
///
/// - Note: Core Data requires the transformer be NSSecureUnarchiveFromData or its subclass,
/// and that its transformedValue(_:) method converts a Data object to an instance of the custom class specified in Data Model Inspector and that reverseTransformedValue(_:)
/// does the opposite – converts an instance of the custom class to a Data object.
public final class Transformer<T: NSObject & NSSecureCoding>: NSSecureUnarchiveFromDataTransformer {
  /// The name of the transformer. It's used when registering the transformer using `DataTransformer.register()`.
  /// It's composed combining the T class name and the suffix "Transformer" (i.e. if T is Object, the transformer name is *ObjectTransformer*).
  public static var transformerName: NSValueTransformerName {
    let transformerName = "\(T.self.classForCoder())" + "Transformer"
    return NSValueTransformerName(transformerName)
  }

  /// Registers the provided value transformer.
  public static func register() {
    let transformer = Transformer<T>()
    Foundation.ValueTransformer.setValueTransformer(transformer, forName: Self.transformerName)
  }

  /// Unregisters the provided value transformer.
  public static func unregister() {
    if Foundation.ValueTransformer.valueTransformerNames().contains(Self.transformerName) {
      Foundation.ValueTransformer.setValueTransformer(nil, forName: Self.transformerName)
    }
  }

  public override static func transformedValueClass() -> AnyClass { T.self }

  public override class func allowsReverseTransformation() -> Bool { true }

  public class override var allowedTopLevelClasses: [AnyClass] { [T.self] }

  public override func transformedValue(_ value: Any?) -> Any? {
    guard let data = value as? Data else {
      return nil
      // fatalError("Wrong data type: value must be a Data object; received \(String(describing: value.self)).")
    }
    return super.transformedValue(data)
  }

  public override func reverseTransformedValue(_ value: Any?) -> Any? {
    guard let receivedValue = value as? T else {
      return nil
      // fatalError("Wrong data type: value must be a \(T.self) object; received \(String(describing: value.self)).")
    }
    return super.reverseTransformedValue(receivedValue)
  }

}

// Alternative Transformer implementation without conforming to NSSecureUnarchiveFromDataTransformer.
//
//public final class Transformer<T: NSObject & NSSecureCoding>: ValueTransformer {
//  public static var transformerName: NSValueTransformerName {
//    let transformerName = "\(T.self.classForCoder())" + "Transformer"
//    return NSValueTransformerName(transformerName)
//  }
//
//  public static func register() {
//    let transformer = Transformer<T>()
//    Foundation.ValueTransformer.setValueTransformer(transformer, forName: Self.transformerName)
//  }
//
//  public static func unregister() {
//    if Foundation.ValueTransformer.valueTransformerNames().contains(Self.transformerName) {
//      Foundation.ValueTransformer.setValueTransformer(nil, forName: Self.transformerName)
//    }
//  }
//
//  public override static func transformedValueClass() -> AnyClass { T.self }
//
//  public override class func allowsReverseTransformation() -> Bool { true }
//
//  public override func transformedValue(_ value: Any?) -> Any? {
//    guard let value = value as? T else {
//      return nil
//      // fatalError("Wrong data type: value must be a Data object; received \(String(describing: value.self)).")
//    }
//
//    let data = try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true)
//    return data
//  }
//
//  public override func reverseTransformedValue(_ value: Any?) -> Any? {
//    guard let data = value as? NSData else {
//      return nil
//      // fatalError("Wrong data type: value must be a \(T.self) object; received \(String(describing: value.self)).")
//    }
//
//    let result = try? NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: data as Data)
//    return result
//  }
//}
