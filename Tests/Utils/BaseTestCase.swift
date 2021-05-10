// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

class BaseTestCase: XCTestCase {
  class override func setUp() {
//    CustomTransformer<Color>.register {
//      guard let color = $0 else { return nil }
//      return try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
//    } reverseTransform: {
//      guard let data = $0 else { return nil }
//      return try? NSKeyedUnarchiver.unarchivedObject(ofClass: Color.self, from: data)
//    }
    Transformer<Color>.register()
  }

  open override class func tearDown() {
    Transformer<Color>.unregister()
    //CustomTransformer<Color>.unregister()
  }
}
