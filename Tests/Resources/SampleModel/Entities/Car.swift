// CoreDataPlus

import Foundation
import CoreData
import CoreDataPlus

// Entity hierarchy vs Class hierarchy
//
// Managed object models offer the possibility to create entity hierarchies (i.e. we can specify an entity as the parent of another entity).
// This might sound good if our entities share some common attributes but it’s rarely what you would want to do.
// What happens behind the scenes is that Core Data stores all entities with the same parent entity in the same table. This quickly creates tables with a large number of attributes, slowing down performance.
// Often the purpose of creating an entity hierarchy is solely to create a class hierarchy, so that we can put code shared between multiple entities into the base class.
// This (Class hierarchy) gives us the benefit of being able to move common code into the base class without the performance overhead of storing all entities in a single table.
// ⚠️ We cannot create class hierarchies deviating from the entity hierarchy with Xcode’s managed object generator though.
public class BaseEntity: NSManagedObject, DelayedDeletable {
  @NSManaged public var markedForDeletionAsOf: Date?
}

// https://github.com/onmyway133/blog/issues/334
public class Color: NSObject, NSSecureCoding {
  public static var supportsSecureCoding: Bool { true }
  public let name: String

  public init(name: String) {
    self.name = name
  }

  public func encode(with coder: NSCoder) {
    coder.encode(name, forKey: "name")
  }

  public required init?(coder decoder: NSCoder) {
    guard let name = decoder.decodeObject(of: [NSString.self], forKey: "name") as? String else { return nil }
    self.name = name
  }
}

@objc(Car)
public class Car: BaseEntity {
  @NSManaged public var maker: String?
  @NSManaged public var model: String?
  @NSManaged public var numberPlate: String!
  @NSManaged public var owner: Person?
  @NSManaged public var currentDrivingSpeed: Int // transient property
  @NSManaged public var color: Color? // transformable property
}

@objc(SportCar)
public class SportCar: Car { }

@objc(ExpensiveSportCar)
final public class ExpensiveSportCar: SportCar {
  @NSManaged public var isLimitedEdition: Bool
}

// V2
@objc(LuxuryCar)
final public class LuxuryCar: SportCar {
  @NSManaged public var isLimitedEdition: Bool
}
