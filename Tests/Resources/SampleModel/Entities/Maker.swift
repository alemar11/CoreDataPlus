// CoreDataPlus

import CoreData

// V3
@objc(Maker)
final public class Maker: NSManagedObject {
  @NSManaged public var name: String
  // This is why it must be a NSSet https://twitter.com/an0/status/1157072652290445314 and https://developer.apple.com/forums/thread/651325
  // "The problem is that bridging will cause all the managed objects to be faulted into memory, which can become a serious performance problem when you have more than a thousand (or so) related objects. The generated subclasses have to work for everyone, so we can’t ship that."
  @NSManaged public var cars: NSSet?

  public var _cars: Set<Car>? {
    get {
      cars as? Set<Car>
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
