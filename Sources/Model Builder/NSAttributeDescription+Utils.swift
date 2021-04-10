// CoreDataPlus
// https://developer.apple.com/documentation/coredata/nsattributetype

import CoreData

extension NSAttributeDescription {
  public static func int16(name: String, defaultValue: Int16? = nil, isOptional: Bool = false) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .integer16AttributeType)
    attributes.isOptional = isOptional
    attributes.defaultValue = defaultValue.map { NSNumber(value: $0) }
    return attributes
  }

  public static func int32(name: String, defaultValue: Int32? = nil, isOptional: Bool = false) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .integer32AttributeType)
    attributes.isOptional = isOptional
    attributes.defaultValue = defaultValue.map { NSNumber(value: $0) }
    return attributes
  }

  public static func int64(name: String, defaultValue: Int64? = nil, isOptional: Bool = false) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .integer64AttributeType)
    attributes.isOptional = isOptional
    attributes.defaultValue = defaultValue.map { NSNumber(value: $0) }
    return attributes
  }

  public static func decimal(name: String, defaultValue: Decimal? = nil, isOptional: Bool = false) -> NSAttributeDescription {
    // https://stackoverflow.com/questions/2376853/core-data-decimal-type-for-currency
    let attributes = NSAttributeDescription(name: name, type: .decimalAttributeType)
    attributes.isOptional = isOptional
    attributes.defaultValue = defaultValue.map { NSDecimalNumber(decimal: $0) }
    return attributes
  }

  // TODO: which type of float?
  public static func float(name: String, defaultValue: Float? = nil, isOptional: Bool = false) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .floatAttributeType)
    attributes.isOptional = isOptional
    attributes.defaultValue = defaultValue.map { NSNumber(value: $0) }
    return attributes
  }

  public static func double(name: String, defaultValue: Double? = nil, isOptional: Bool = false) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .doubleAttributeType)
    attributes.isOptional = isOptional
    attributes.defaultValue = defaultValue.map { NSNumber(value: $0) }
    return attributes
  }

  public static func string(name: String, defaultValue: String? = nil, isOptional: Bool = false) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .stringAttributeType)
    attributes.isOptional = isOptional
    attributes.defaultValue = defaultValue
    return attributes
  }

  public static func bool(name: String, defaultValue: Bool? = nil, isOptional: Bool = false) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .booleanAttributeType)
    attributes.isOptional = isOptional
    attributes.defaultValue = defaultValue.map { NSNumber(value: $0) }
    return attributes
  }

  public static func date(name: String, defaultValue: NSDate? = nil, isOptional: Bool = false) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .dateAttributeType)
    attributes.isOptional = isOptional
    attributes.defaultValue = defaultValue
    return attributes
  }

  public static func uuid(name: String, defaultValue: UUID? = nil, isOptional: Bool = false) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .UUIDAttributeType)
    attributes.isOptional = isOptional
    attributes.defaultValue = defaultValue
    return attributes
  }

  public static func uri(name: String, defaultValue: URL? = nil, isOptional: Bool = false) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .URIAttributeType)
    attributes.isOptional = isOptional
    attributes.defaultValue = defaultValue
    return attributes
  }

  public static func binaryData(name: String, defaultValue: NSData? = nil, isOptional: Bool = false, allowsExternalBinaryDataStorage: Bool = false) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .binaryDataAttributeType)
    attributes.isOptional = isOptional
    attributes.defaultValue = defaultValue
    attributes.allowsExternalBinaryDataStorage = allowsExternalBinaryDataStorage
    return attributes
  }

  // transformerName needs to be unique
  public static func transformable<A: NSObject & NSSecureCoding>(name: String,
                                                                 isOptional: Bool = false,
                                                                 transform: @escaping DataTransformer<A>.Transform,
                                                                 reverse: @escaping DataTransformer<A>.ReverseTransform) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .transformableAttributeType)
    attributes.isOptional = isOptional
    attributes.defaultValue = nil

//    let t = { (a: A?) -> NSData? in
//      a.flatMap { transform.forward($0) }
//    }
//    let r = { Optional<A>.some(transform.reverse($0)) }

    // If your attribute is of NSTransformableAttributeType, the attributeValueClassName must be set or attribute value class must implement NSCopying.

    DataTransformer<A>.register(transform: transform, reverseTransform: reverse)
    attributes.valueTransformerName =  DataTransformer<A>.transformerName.rawValue
    return attributes
  }

  public static func transformable<A: NSObject & NSSecureCoding>(name: String,
                                                                 isOptional: Bool = false,
                                                                 type: A.Type) -> NSAttributeDescription {
    let attributes = NSAttributeDescription(name: name, type: .transformableAttributeType)
    attributes.isOptional = isOptional
    attributes.defaultValue = nil
    Transformer<A>.register()
    attributes.valueTransformerName = Transformer<A>.transformerName.rawValue
    return attributes
  }

  private convenience init(name: String, type: NSAttributeType) {
    self.init()
    self.name = name
    self.attributeType = type
  }
}



//case objectIDAttributeType = 2000
//https://developer.apple.com/documentation/coredata/modeling_data/configuring_attributes?language=objc



//https://hub.packtpub.com/core-data-ios-designing-data-model-and-building-data-objects/
//Decimal, Double, and Float data types are for storing fractional numbers. The Double data type uses 64 bits to store a value while the Float data type uses 32 bits for storing a value. The only limitation with these two data types is that they round off the values. To avoid any rounding of values, the Decimal data type is preferred. The Decimal type uses fixed point numbers for storing values, so the numerical value stored in it is not rounded of
