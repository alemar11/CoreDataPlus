// CoreDataPlus

import CoreData

extension NSFetchedPropertyDescription {
  /// Fetched properties allow to specify related objects through a "weakly" resolved property, so there is no actual join necessary.
  /// As part of the predicate for a fetched property, you can use the two variables **$FETCH_SOURCE** (which is the managed object fetching the property) and **$FETCHED_PROPERTY**
  /// (which is the NSFetchedPropertyDescription instance).
  ///
  /// - Parameters:
  ///   - name: The name of the attribute.
  ///   - destinationEntity: the fetched propery destination entity.
  ///   - configuration: A close to configure the underlying NSFetchRequest.
  ///
  /// There are two special variables you can use in the predicate of a fetched property: **$FETCH_SOURCE** and **$FETCHED_PROPERTY**.
  ///
  /// The source refers to the specific managed object that has this property, and you can create key-paths that originate with this,
  /// for example *university.name LIKE [c] $FETCH_SOURCE.searchTerm*.
  /// The **$FETCHED_PROPERTY** is the entity's fetched property description.
  ///
  /// The property description has a userInfo dictionary that you can populate with whatever key-value pairs you want.
  /// You can therefore change some expressions within a fetched property's predicate or (via key-paths) any object to which that object is related.
  ///
  /// - Note: The effect of a fetched property is similar to executing a fetch request yourself and placing the results in a transient attribute, although with the framework managing the details.
  /// In particular, a fetched property is not fetched until it is requested, and the results are then cached until the object is turned into a fault.
  ///
  /// You use `refresh(_:mergeChanges:)` (NSManagedObjectContext) to manually refresh the properties;
  /// this causes the fetch request associated with this property to be executed again when the object fault is next fired.
  ///
  /// Unlike other relationships, which are all sets, fetched properties are represented by an ordered NSArray object just as if you executed the fetch request yourself.
  public convenience init(
    name: String, destinationEntity: NSEntityDescription, configuration: (NSFetchRequest<NSFetchRequestResult>) -> Void
  ) {
    self.init()
    let request = NSFetchRequest<NSFetchRequestResult>(entity: destinationEntity)
    request.resultType = .managedObjectResultType
    configuration(request)
    assert(
      request.resultType == .managedObjectResultType,
      "NSFetchedPropertyDescription supports only NSFetchRequest with resultType set to managedObjectResultType.")
    self.name = name
    self.fetchRequest = request
  }
}
