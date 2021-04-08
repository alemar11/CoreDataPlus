// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

class BaseTestCase: XCTestCase {
  class override func setUp() {
    Transformer<Color>.register()
  }

  open override class func tearDown() {
    Transformer<Color>.unregister()
  }
}
