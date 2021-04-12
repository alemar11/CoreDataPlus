// CoreDataPlus
// Fetched properties allow to specify related objects through a "weakly" resolved property, so there is no actual join necessary.
// As part of the predicate for a fetched property, you can use the two variables $FETCH_SOURCE (which is the managed object fetching the property) and $FETCHED_PROPERTY (which is the NSFetchedPropertyDescription instance).

import CoreData

/*
 An example might be a iTunes playlist, if expressed as a property of a containing object. Songs don’t belong to a particular playlist, especially in the case that they’re on a remote server. The playlist may remain even after the songs have been deleted, or the remote server has become inaccessible. Note, however, that unlike a playlist a fetched property is static—it does not dynamically update itself as objects in the destination entity change.
 The effect of a fetched property is similar to executing a fetch request yourself and placing the results in a transient attribute, although with the framework managing the details. In particular, a fetched property is not fetched until it is requested, and the results are then cached until the object is turned into a fault. You use refresh(_:mergeChanges:) (NSManagedObjectContext) to manually refresh the properties—this causes the fetch request associated with this property to be executed again when the object fault is next fired.
 Unlike other relationships, which are all sets, fetched properties are represented by an ordered NSArray object just as if you executed the fetch request yourself. The fetch request associated with the property can have a sort ordering. The value for a fetched property of a managed object does not support mutableArrayValueForKey:.
 */

extension NSFetchedPropertyDescription {
  public convenience init<T: NSManagedObject>(name: String, fetchRequest: NSFetchRequest<T>) {
    self.init()
    // swiftlint:disable:next force_cast

    //A fetched property is represented by an array, not a set. The fetch request associated with the property can have a sort ordering, and thus the fetched property may be ordered.
    //let type = NSFetchRequestResultType.managedObjectResultType // always an array
    self.fetchRequest = (fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
  }
}

//In some respects you can think of a fetched property as being similar to a smart playlist, but with the important constraint that it is not dynamic. If objects in the destination entity are changed, you must reevaluate the fetched property to ensure it is up-to-date. You use refreshObject:mergeChanges: to manually refresh the properties—this causes the fetch request associated with this property to be executed again when the object fault is next fired.

//There are two special variables you can use in the predicate of a fetched property—$FETCH_SOURCE and $FETCHED_PROPERTY. The source refers to the specific managed object that has this property, and you can create key-paths that originate with this, for example university.name LIKE [c] $FETCH_SOURCE.searchTerm. The $FETCHED_PROPERTY is the entity's fetched property description. The property description has a userInfo dictionary that you can populate with whatever key-value pairs you want. You can therefore change some expressions within a fetched property's predicate or (via key-paths) any object to which that object is related.

//To understand how the variables work, consider a fetched property with a destination entity Author and a predicate of the form, (university.name LIKE [c] $FETCH_SOURCE.searchTerm) AND (favoriteColor LIKE [c] $FETCHED_PROPERTY.userInfo.color).
// If the source object had an attribute searchTerm equal to "Cambridge", and the fetched property had a user info dictionary with a key "color" and value "Green", then the resulting predicate would be (university.name LIKE [c] "Cambridge") AND (favoriteColor LIKE [c] "Green").
// This would match any Authors at Cambridge whose favorite color is green. If you changed the value of searchTerm in the source object to, say, "Durham", then the predicate would be (university.name LIKE [c] "Durham") AND (favoriteColor LIKE [c] "Green").


/*
 feedbackList = "(<NSFetchedPropertyDescription: 0x600000b0caf0>), name feedbackList, isOptional 1, isTransient 1, entity Book, renamingIdentifier feedbackList, validation predicates (\n), warnings (\n), versionHashModifier (null)\n userInfo {\n}, fetchRequest <NSFetchRequest: 0x600000b0d650> (entity: Feedback; predicate: (bookUUID == $FETCH_SOURCE.uuid); sortDescriptors: ((null)); type: NSManagedObjectResultType; )";
 */
