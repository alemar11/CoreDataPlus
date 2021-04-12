// CoreDataPlus
// https://developer.apple.com/documentation/coredata/nsattributetype

// About the NSAttributeDescription isOptional property:
//
// The underlying SQLite database has the is_nullable value always set to TRUE for every table's column.
// So, it seems that the isOptional is evaluated only at runtime (like probably many other CoreData properties, i.e. uniquenessConstraints)
//
// This can be verified easily if during a save we set not optional values to nil through their primitive values; the save will succeed.
//
//  public override func willSave() {
//    setPrimitiveValue(nil, forKey: MY_KEY)
//  }

import CoreData

extension NSAttributeDescription {
  /// - Parameters:
  ///   - name: The name of the attribute.
  ///   - defaultValue: The default value of the attribute.
  /// - Returns: Returns a *Int16* attribute description.
  public static func int16(name: String, defaultValue: Int16? = nil) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .integer16AttributeType)
    attributes.defaultValue = defaultValue.map { NSNumber(value: $0) }
    return attributes
  }

  public static func int32(name: String, defaultValue: Int32? = nil) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .integer32AttributeType)
    attributes.defaultValue = defaultValue.map { NSNumber(value: $0) }
    return attributes
  }

  public static func int64(name: String, defaultValue: Int64? = nil) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .integer64AttributeType)
    attributes.defaultValue = defaultValue.map { NSNumber(value: $0) }
    return attributes
  }

  public static func decimal(name: String, defaultValue: Decimal? = nil) -> NSAttributeDescription {
    // https://stackoverflow.com/questions/2376853/core-data-decimal-type-for-currency
    let attributes = NSAttributeDescription(name: name, type: .decimalAttributeType)
    attributes.defaultValue = defaultValue.map { NSDecimalNumber(decimal: $0) }
    return attributes
  }

  // TODO: which type of float?
  public static func float(name: String, defaultValue: Float? = nil) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .floatAttributeType)
    attributes.defaultValue = defaultValue.map { NSNumber(value: $0) }
    return attributes
  }

  public static func double(name: String, defaultValue: Double? = nil) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .doubleAttributeType)
    attributes.defaultValue = defaultValue.map { NSNumber(value: $0) }
    return attributes
  }

  public static func string(name: String, defaultValue: String? = nil) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .stringAttributeType)
    attributes.defaultValue = defaultValue
    return attributes
  }

  public static func bool(name: String, defaultValue: Bool? = nil) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .booleanAttributeType)
    attributes.defaultValue = defaultValue.map { NSNumber(value: $0) }
    return attributes
  }

  public static func date(name: String, defaultValue: Date? = nil) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .dateAttributeType)
    attributes.defaultValue = defaultValue
    return attributes
  }

  public static func uuid(name: String, defaultValue: UUID? = nil) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .UUIDAttributeType)
    attributes.defaultValue = defaultValue
    return attributes
  }

  public static func uri(name: String, defaultValue: URL? = nil) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .URIAttributeType)
    attributes.defaultValue = defaultValue
    return attributes
  }

  public static func binaryData(name: String, defaultValue: Data? = nil, allowsExternalBinaryDataStorage: Bool = false) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .binaryDataAttributeType)
    attributes.defaultValue = defaultValue
    attributes.allowsExternalBinaryDataStorage = allowsExternalBinaryDataStorage
    return attributes
  }

  // transformerName needs to be unique
  public static func transformable<T: NSObject & NSSecureCoding>(for aClass: T.Type,
                                                                 name: String,
                                                                 defaultValue: T? = nil,
                                                                 valueTransformerName: String) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .transformableAttributeType)
    attributes.defaultValue = defaultValue
    attributes.attributeValueClassName = "\(T.self.classForCoder())"
    attributes.valueTransformerName =  valueTransformerName
    return attributes
  }

  public static func transformable<T: NSObject & NSSecureCoding>(for aClass: T.Type,
                                                                 name: String,
                                                                 defaultValue: T? = nil,
                                                                 transform: @escaping DataTransformer<T>.Transform,
                                                                 reverse: @escaping DataTransformer<T>.ReverseTransform) -> NSAttributeDescription {
    DataTransformer<T>.register(transform: transform, reverseTransform: reverse)

    let attributes = NSAttributeDescription.transformable(for: T.self,
                                                          name: name,
                                                          defaultValue: defaultValue,
                                                          valueTransformerName: DataTransformer<T>.transformerName.rawValue)
    return attributes
  }

  public static func transformable<T: NSObject & NSSecureCoding>(of aClass: T.Type,
                                                                 name: String,
                                                                 defaultValue: T? = nil) -> NSAttributeDescription {
    Transformer<T>.register()

    let attributes = NSAttributeDescription.transformable(for: T.self,
                                                          name: name,
                                                          defaultValue: defaultValue,
                                                          valueTransformerName: Transformer<T>.transformerName.rawValue)
    return attributes
  }

  private convenience init(name: String, type: NSAttributeType) {
    self.init()
    self.name = name
    self.attributeType = type
  }
}



//case objectIDAttributeType = 2000
// https://developer.apple.com/documentation/coredata/modeling_data/configuring_attributes?language=objc

//https://developer.apple.com/documentation/coredata/modeling_data/configuring_attributes

//https://hub.packtpub.com/core-data-ios-designing-data-model-and-building-data-objects/
// Decimal, Double, and Float data types are for storing fractional numbers.
// The Double data type uses 64 bits to store a value while the Float data type uses 32 bits for storing a value.
// The only limitation with these two data types is that they round off the values.
// To avoid any rounding of values, the Decimal data type is preferred. The Decimal type uses fixed point numbers for storing values, so the numerical value stored in it is not rounded of

/**
 "Optional" means something different to Core Data than it does to Swift.

 If a Core Data attribute is not optional, it must have a non-nil value when you save changes. At other times Core Data doesn't care if the attribute is nil.
 If a Swift property is not optional, it must have a non-nil value at all times after initialization is complete.
 */
