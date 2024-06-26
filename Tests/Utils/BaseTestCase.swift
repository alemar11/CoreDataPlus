// CoreDataPlus

import CoreData
import XCTest

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

// TODO: Xcode 15 bug
//
// No NSValueTransformer with class name XXX was found for attribute YYY on entity ZZZ for custom `NSSecureUnarchiveFromDataTransformer`
// https://forums.developer.apple.com/forums/thread/740492
// https://stackoverflow.com/questions/77340664/core-data-no-nsvaluetransformer-with-class-name-xxx-was-found-for-attribute-yy/77623593#77623593
