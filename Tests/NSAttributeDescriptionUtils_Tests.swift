// CoreDataPlus

import CoreData
import XCTest

@testable import CoreDataPlus

final class NSAttributeDescriptionUtils_Tests: XCTestCase {
  func test_Int16() {
    let attribute = NSAttributeDescription.int16(name: #function, defaultValue: 1)
    XCTAssertEqual(attribute.name, #function)
    XCTAssertEqual(attribute.defaultValue as? Int16, 1)
  }

  func test_Int32() {
    let attribute = NSAttributeDescription.int32(name: #function, defaultValue: 11)
    XCTAssertEqual(attribute.name, #function)
    XCTAssertEqual(attribute.defaultValue as? Int32, 11)
  }

  func test_Int64() {
    let attribute = NSAttributeDescription.int64(name: #function, defaultValue: nil)
    XCTAssertEqual(attribute.name, #function)
    XCTAssertNil(attribute.defaultValue)
  }

  func test_Decimal() {
    let attribute = NSAttributeDescription.decimal(name: #function, defaultValue: 1.11111)
    XCTAssertEqual(attribute.name, #function)
    XCTAssertEqual(attribute.defaultValue as? NSDecimalNumber, NSDecimalNumber(decimal: 1.11111))
  }

  func test_Float() {
    let attribute = NSAttributeDescription.float(name: #function, defaultValue: 1.11111)
    XCTAssertEqual(attribute.name, #function)
    XCTAssertEqual(attribute.defaultValue as? Float, 1.11111)
  }

  func test_Double() {
    let attribute = NSAttributeDescription.double(name: #function, defaultValue: 1.11111)
    XCTAssertEqual(attribute.name, #function)
    XCTAssertEqual(attribute.defaultValue as? Double, 1.11111)
  }

  func test_String() {
    let string = "hello world"
    let attribute = NSAttributeDescription.string(name: #function, defaultValue: string)
    XCTAssertEqual(attribute.name, #function)
    XCTAssertEqual(attribute.defaultValue as? String, string)
  }

  func test_Bool() {
    let attribute = NSAttributeDescription.bool(name: #function, defaultValue: false)
    XCTAssertEqual(attribute.name, #function)
    XCTAssertEqual(attribute.defaultValue as? Bool, false)
  }

  func test_Date() {
    let date = Date()
    let attribute = NSAttributeDescription.date(name: #function, defaultValue: date)
    XCTAssertEqual(attribute.name, #function)
    XCTAssertEqual(attribute.defaultValue as? Date, date)
  }

  func test_UUID() {
    let uuid = UUID()
    let attribute = NSAttributeDescription.uuid(name: #function, defaultValue: uuid)
    XCTAssertEqual(attribute.name, #function)
    XCTAssertEqual(attribute.defaultValue as? UUID, uuid)
  }

  func test_URI() {
    let url = URL(string: "http://www.alessandromarzoli.com/CoreDataPlus/")!
    let attribute = NSAttributeDescription.uri(name: #function, defaultValue: url)
    XCTAssertEqual(attribute.name, #function)
    XCTAssertEqual(attribute.defaultValue as? URL, url)
  }

  func test_BinaryData() {
    let data = "Test".data(using: .utf8)
    let attribute = NSAttributeDescription.binaryData(
      name: #function,
      defaultValue: data,
      allowsExternalBinaryDataStorage: true)
    XCTAssertEqual(attribute.name, #function)
    XCTAssertEqual(attribute.defaultValue as? Data, data)
    XCTAssertTrue(attribute.allowsExternalBinaryDataStorage)
  }

  func test_CustomTransformable() {
    let color = Color(name: "color")
    let attribute = NSAttributeDescription.customTransformable(for: Color.self, name: #function, defaultValue: color) {
      _ in
      nil
    } reverse: { _ in
      nil
    }
    XCTAssertEqual(attribute.name, #function)
    XCTAssertEqual(attribute.defaultValue as? Color, color)
  }

  func test_Transformable() {
    let color = Color(name: "color")
    let attribute = NSAttributeDescription.transformable(for: Color.self, name: #function, defaultValue: color)
    XCTAssertEqual(attribute.name, #function)
    XCTAssertEqual(attribute.defaultValue as? Color, color)
  }
}
