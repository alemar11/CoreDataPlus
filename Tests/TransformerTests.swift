// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

class TransformerTests: CoreDataPlusOnDiskTestCase {
    
  func testExample() throws {
    let context = container.viewContext
    context.fillWithSampleData()
    try context.save()
    let cars =  try Car.fetch(in: context)
    print("\(cars.count)")
  }
  // TODO: to create a sqlite for migrations disable NSPersistentHistoryTrackingKey
  // TODO: create a base XCTestCase to register (maybe unregister) transformers
}
