// CoreDataPlus

import CoreData

extension Migration {
  /// Represents a single step during a migration process.
  public final class Step {
    public let sourceModel: NSManagedObjectModel
    public let sourceOptions: [AnyHashable: Any]?
    public let destinationModel: NSManagedObjectModel
    public let destinationOptions: [AnyHashable: Any]?
    public let mappings: [NSMappingModel]

    init(source: NSManagedObjectModel,
         sourceOptions: [AnyHashable: Any]? = nil,
         destination: NSManagedObjectModel,
         destinationOptions: [AnyHashable: Any]? = nil,
         mappings: [NSMappingModel]) {
      self.sourceModel = source
      self.sourceOptions = sourceOptions
      self.destinationModel = destination
      self.destinationOptions = destinationOptions
      self.mappings = mappings
    }
  }
}
