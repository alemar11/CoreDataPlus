import Foundation
import CoreData
import CoreDataPlus

@objc(Car)
public class Car: NSManagedObject {
  @NSManaged public var maker: String?
  @NSManaged public var model: String?
  @NSManaged public var numberPlate: String!
  @NSManaged public var owner: Person?
}

extension Car: DelayedDeletable {
  @NSManaged public var markedForDeletionAsOf: Date?
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
