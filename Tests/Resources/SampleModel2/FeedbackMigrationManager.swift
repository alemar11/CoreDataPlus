// CoreDataPlus

import CoreData

@objc
class FeedbackMigrationManager: NSMigrationManager {
  @objc(customfetchRequestForSourceEntityNamed:predicateString:)
  func customFetchRequest(forSourceEntityNamed entityName:String, predicateString: String) -> NSFetchRequest<NSFetchRequestResult> {
    // 🚩 Investigating how to implement and call custom methods in the manager
    // see testMigrationFromV1toV3 and makeFeedbackMappingPartOne()
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
    request.predicate = NSPredicate(format: predicateString)
    return request
  }
}
