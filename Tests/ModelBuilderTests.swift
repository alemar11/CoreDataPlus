// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

final class ModelBuilderTests: XCTestCase {
  func test_1() throws {
    let model = SampleModel2.makeManagedObjectModel()
    let container = NSPersistentContainer(name: "SampleModel2", managedObjectModel: model)
    let description = NSPersistentStoreDescription()
    // addPersistentStore-time behaviours
    description.url = URL.newDatabaseURL(withID: UUID())
    description.shouldAddStoreAsynchronously = false
    description.shouldMigrateStoreAutomatically = false
    description.shouldInferMappingModelAutomatically = false
    container.persistentStoreDescriptions = [description]
    container.loadPersistentStores { (description, error) in
      XCTAssertNil(error)
    }
    print(description.url)
    let context = container.viewContext
    try SampleModel2.fillWithSampleData(context: context)
    do {
    try context.save()
    } catch {
      print("--- catch ----")
      let e = error as NSError
      //print(e.userInfo)
      //print(e.debugDescription)
      print(e.localizedDescription)
    }
  }
}
