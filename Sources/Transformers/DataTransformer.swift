// CoreDataPlus

import CoreData
import Foundation

/// A generic `ValueTransformer` subclass to implement CoreData *Transformable* attributes.
/// - Note: CoreData *Transformable* attributes are converted to and from the `Data` type.
public final class DataTransformer<T: NSObject & NSSecureCoding>: ValueTransformer {
  public typealias Transform = (T?) -> Data?
  public typealias ReverseTransform = (Data?) -> T?

  /// The name of the transformer. It's used when registering the transformer using `DataTransformer.register(transform:reverseTransform:)`.
  /// It's composed combining the T class name and the suffix "Transformer" (i.e. if T is Object, the transformer name is *ObjectTransformer*).
  public static var transformerName: NSValueTransformerName {
    let transformerName = "\(T.self.classForCoder())" + "Transformer"
    return NSValueTransformerName(transformerName)
  }

  /// Creates and registers an instance of a `DataTransformer`.
  /// - Parameters:
  ///   - transform: Closure to transform an instance of T into a Data object.
  ///   - reverseTransform: Closure to transform a Data object into an instance of T.
  public static func register(transform: @escaping Transform, reverseTransform: @escaping ReverseTransform) {
    let transformer = DataTransformer(transform: transform, reverseTransform: reverseTransform)
    Foundation.ValueTransformer.setValueTransformer(transformer, forName: Self.transformerName)
  }

  /// Unregisters the value transformer.
  public static func unregister() {
    if Foundation.ValueTransformer.valueTransformerNames().contains(Self.transformerName) {
      Foundation.ValueTransformer.setValueTransformer(nil, forName: Self.transformerName)
    }
  }

  private let transform: Transform
  private let reverseTransform: ReverseTransform

  /// Creates a new `DataTransformer` instance.
  /// - Parameters:
  ///   - transform: Closure to transform an instance of T into a Data object.
  ///   - reverseTransform: Closure to transform a Data object into an instance of T.
  public init(transform: @escaping Transform, reverseTransform: @escaping ReverseTransform) {
    self.transform = transform
    self.reverseTransform = reverseTransform
    super.init()
  }

  public override static func transformedValueClass() -> AnyClass { T.self }

  public override class func allowsReverseTransformation() -> Bool { true }

  public override func transformedValue(_ value: Any?) -> Any? {
    // T -> Data
    // CoreData calls this method during fetches (read).
    transform(value as? T)
  }

  public override func reverseTransformedValue(_ value: Any?) -> Any? {
    // Data -> T
    // CoreData calls this method during saves (write)
    // transformedValue(_:) and reverseTransformedValue(_:) methods for NSSecureUnarchiveFromDataTransformer subclasses are called
    // in the opposite way than on ValuteTransformer subclasses
    reverseTransform(value as? Data)
  }
}
