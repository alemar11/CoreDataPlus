// CoreDataPlus

import CoreData

// V3
@objc(Maker)
final public class Maker: NSManagedObject {
  @NSManaged public var name: String
  @NSManaged public var cars: NSSet? // This is why it must be a NSSet https://twitter.com/an0/status/1157072652290445314 and https://developer.apple.com/forums/thread/651325

  public var _cars: Set<Car>? {
    get {
      return cars as? Set<Car>
    }
    set {
      if let newCars = newValue {
        self.cars = NSSet(set: newCars)
      } else {
        self.cars = nil
      }
    }
  }
}
