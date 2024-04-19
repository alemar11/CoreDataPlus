// CoreDataPlus

import CoreData

// Solution 1
// Define a NSMigrationManager subclass and use it at the right time during the migration steps

@objc
class FeedbackMigrationManager: NSMigrationManager {
  @objc(customfetchRequestForSourceEntityNamed:predicateString:)
  func customFetchRequest(forSourceEntityNamed entityName: String, predicateString: String) -> NSFetchRequest<
    NSFetchRequestResult
  > {
    // 🚩 Investigating how to implement and call custom methods in the manager
    // see testMigrationFromV1toV3 and makeFeedbackMappingPartOne()
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
    request.predicate = NSPredicate(format: predicateString)
    return request
  }
}

// Solution 2
// Define a NSMigrationManager extension without having to subclass NSMigrationManager itself

//extension NSMigrationManager {
//  @objc(customfetchRequestForSourceEntityNamed:predicateString:)
//  func customFetchRequest(forSourceEntityNamed entityName:String, predicateString: String) -> NSFetchRequest<NSFetchRequestResult> {
//    // 🚩 Investigating how to implement and call custom methods in the manager
//    // see testMigrationFromV1toV3 and makeFeedbackMappingPartOne()
//    let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
//    request.predicate = NSPredicate(format: predicateString)
//    return request
//  }
//}
