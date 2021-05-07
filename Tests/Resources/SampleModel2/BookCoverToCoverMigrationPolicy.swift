// CoreDataPlus
//
// More on migrations:
// https://stackoverflow.com/questions/11190385/custom-nsentitymigrationpolicy-relation

import CoreData

@objc(BookCoverToCoverMigrationPolicy)
class BookCoverToCoverMigrationPolicy: NSEntityMigrationPolicy {
  override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
    // This method is invoked by the migration manager on each source instance (as specified by the sourceExpression in the mapping)
    // to create the corresponding destination instance(s).
    // It also associates the source and destination instances by calling NSMigrationManager’s associate(sourceInstance:withDestinationInstance:for:) method.
    try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)

    // If we don't call the super implementation we need to do the association programmatically like so:
    // Note: since you already have a destinationInstance, you won't need to call anymore manager.destinationInstances(forEntityMappingName:sourceInstances:)
//    let destinationInstance = NSEntityDescription.insertNewObject(forEntityName: mapping.destinationEntityName!, into: manager.destinationContext)
//    let destinationInstanceKeys = destinationInstance.entity.attributesByName.keys // relationship keys aren't defined here (which is fine)
//    destinationInstanceKeys.forEach { (key) in
//      if let value = sInstance.value(forKey: key) {
//        if let nsobject = value as? NSObject, nsobject.isEqual(NSNull()) {
//          return
//        }
//        destinationInstance.setValue(value, forKey: key)
//      }
//    }
//    manager.associate(sourceInstance: sInstance, withDestinationInstance: destinationInstance, for: mapping)


    // This is how we can use the NSEntityMapping userInfo to pass additional data to the policy.
    // This way we can, for instance, re-use the same policy for different migrations and change its loginc
    // depending on the data passed in the userInfo dictionary.
    guard let version = mapping.userInfo?["modelVersion"] as? String, version == "V3" else {
      fatalError("Missing model version .")
    }

    guard let frontCover = sInstance.value(forKey: #keyPath(BookV2.frontCover)) as? Cover else {
      return
    }

    guard let book = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance]).first else {
      fatalError("must return book")
    }

    guard let context = book.managedObjectContext else {
      fatalError("must have context")
    }

    // ⚠️
//    let sBooks = sInstance.value(forKey: "pages") as? Set<NSManagedObject> ?? Set()
//    let dBooks = manager.destinationInstances(forEntityMappingName: "PageToPage", sourceInstances: Array(sBooks))
//    book.setValue(Set(dBooks), forKey: "pages")

    let cover = NSEntityDescription.insertNewObject(forEntityName: "Cover", into: context)
    cover.setValue(frontCover.text.data(using: .utf8), forKey: #keyPath(CoverV3.data))
    cover.setValue(book, forKey: #keyPath(CoverV3.book))
  }

  override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
    // In a properly designed data model, this method will rarely, if ever, be needed.
    // The intention of this method (which is called in the second pass) is to build any relationships for the new destination entity
    // that was created in the previous method. However, if all the relationships in the model are double-sided, this method is not necessary
    // because we already set up one side of them.
  }

//  override func performCustomValidation(forMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
//    try super.performCustomValidation(forMapping: mapping, manager: manager)
//  }
  
  //@objc(destinationTitleForSourceBookTitle:manager:)
  @objc
  func destinationTitle(forSourceBookTitle sTitle: String, manager: NSMigrationManager) -> String {
    // https://horseshoe7.wordpress.com/2017/09/13/manual-core-data-migrations-lessons-learned/
    // see makeBookMapping() method on how to call custom methods in a policy
    return sTitle
  }
}
