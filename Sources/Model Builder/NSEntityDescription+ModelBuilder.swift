// CoreDataPlus

import CoreData

extension NSEntityDescription {
  /// Creates a new NSEntityDescription instance.
  /// - Parameters:
  ///   - aClass: The class that represents the entity.
  ///   - name: The entity name (defaults to the class name).
  public convenience init<T: NSManagedObject>(for aClass: T.Type, withName name: String? = .none) {
    self.init()
    self.managedObjectClassName = String(describing: aClass.self)
    // unless specified otherwise the entity name is equal to the class name
    self.name = (name == nil) ? String(describing: T.self) : name
    self.isAbstract = false
    self.subentities = []
  }

  /// Adds a property description
  public func add(_ property: NSPropertyDescription) {
    properties.append(property)
  }
}
