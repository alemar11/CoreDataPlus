// CoreDataPlus

import CoreData
import Foundation

final class Transformer<A: AnyObject, B: AnyObject>: ValueTransformer {
  public typealias Transform = (A?) -> B?
  public typealias ReverseTransform = (B?) -> A?

  private let transform: Transform
  private let reverseTransform: ReverseTransform

  init(transform: @escaping Transform, reverseTransform: @escaping ReverseTransform) {
    self.transform = transform
    self.reverseTransform = reverseTransform
    super.init()
  }

  public static func registerTransformer(withName name: String, transform: @escaping Transform, reverseTransform: @escaping ReverseTransform) {
    let transformer = Transformer(transform: transform, reverseTransform: reverseTransform)
    Foundation.ValueTransformer.setValueTransformer(transformer, forName: NSValueTransformerName(rawValue: name))
  }

  public override static func transformedValueClass() -> AnyClass { B.self }

  public override class func allowsReverseTransformation() -> Bool { true }

  public override func transformedValue(_ value: Any?) -> Any? {
    return transform(value as? A)
  }

  public override func reverseTransformedValue(_ value: Any?) -> Any? {
    reverseTransform(value as? B)
  }
}

//Core Data requires the transformer be NSSecureUnarchiveFromData or its subclass, and that its transformedValue(_:) method converts a Data object to an instance of the custom class specified in Data Model Inspector and that reverseTransformedValue(_:) does the opposite – converts an instance of the custom class to a Data object.
final class DataTransformer<A: AnyObject & NSSecureCoding>: NSSecureUnarchiveFromDataTransformer {
  public static func registerTransformer(withName name: String) {
    let transformer = DataTransformer<A>()
    Foundation.ValueTransformer.setValueTransformer(transformer, forName: NSValueTransformerName(rawValue: name))
  }
  
  public override static func transformedValueClass() -> AnyClass { A.self }
  
  public override class func allowsReverseTransformation() -> Bool { true }
  
  public override func transformedValue(_ value: Any?) -> Any? {
    guard let data = value as? Data else {
      return nil
      fatalError("Wrong data type: value must be a Data object; received \(type(of: value)).")
    }
    return super.transformedValue(data)
  }
  
  public override func reverseTransformedValue(_ value: Any?) -> Any? {
    guard let receivedValue = value as? A else {
      return nil
      fatalError("Wrong data type: value must be a \(A.self) object; received \(type(of: value)).")
    }
    return super.reverseTransformedValue(receivedValue)
  }
  
  public class override var allowedTopLevelClasses: [AnyClass] { [A.self] }
}
