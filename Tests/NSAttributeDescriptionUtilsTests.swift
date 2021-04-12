// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

final class NSAttributeDescriptionUtilsTests: XCTestCase {
  func testInt16() {
    let attribute = NSAttributeDescription.int16(name: "test16", defaultValue: 1)
    XCTAssertEqual(attribute.name, "test16")
    XCTAssertEqual(attribute.defaultValue as? Int16, 1)
  }

  func testInt32() {
    let attribute = NSAttributeDescription.int32(name: "test32", defaultValue: 11)
    XCTAssertEqual(attribute.name, "test32")
    XCTAssertEqual(attribute.defaultValue as? Int32, 11)
  }

  func testInt64() {
    let attribute = NSAttributeDescription.int64(name: "test64", defaultValue: nil)
    XCTAssertEqual(attribute.name, "test64")
    XCTAssertNil(attribute.defaultValue)
  }

  func testDecimal() {
    let attribute = NSAttributeDescription.decimal(name: "testDecimal", defaultValue: 1.11111)
    XCTAssertEqual(attribute.name, "testDecimal")
    XCTAssertEqual(attribute.defaultValue as? NSDecimalNumber, NSDecimalNumber(decimal: 1.11111))
  }

  func testFloat() {
    let attribute = NSAttributeDescription.float(name: "testFloat", defaultValue: 1.11111)
    XCTAssertEqual(attribute.name, "testFloat")
    XCTAssertEqual(attribute.defaultValue as? Float, 1.11111)
  }

  func testDouble() {
    let attribute = NSAttributeDescription.double(name: "testDouble", defaultValue: 1.11111)
    XCTAssertEqual(attribute.name, "testDouble")
    XCTAssertEqual(attribute.defaultValue as? Double, 1.11111)
  }

  func testString() {
    let attribute = NSAttributeDescription.string(name: "testString", defaultValue: "hello world")
    XCTAssertEqual(attribute.name, "testString")
    XCTAssertEqual(attribute.defaultValue as? String, "hello world")
  }

  func testBool() {
    let attribute = NSAttributeDescription.bool(name: "testBool", defaultValue: false)
    XCTAssertEqual(attribute.name, "testBool")
    XCTAssertEqual(attribute.defaultValue as? Bool, false)
  }

  func testDate() {
    let date = Date()
    let attribute = NSAttributeDescription.date(name: "testDate", defaultValue: date)
    XCTAssertEqual(attribute.name, "testDate")
    XCTAssertEqual(attribute.defaultValue as? Date, date)
  }

  func testUUID() {
    let uuid = UUID()
    let attribute = NSAttributeDescription.uuid(name: "testUUID", defaultValue: uuid)
    XCTAssertEqual(attribute.name, "testUUID")
    XCTAssertEqual(attribute.defaultValue as? UUID, uuid)
  }

  func testURI() {
    let url = URL(string: "http://www.alessandromarzoli.com/CoreDataPlus/")!
    let attribute = NSAttributeDescription.uri(name: "testURL", defaultValue: url)
    XCTAssertEqual(attribute.name, "testURL")
    XCTAssertEqual(attribute.defaultValue as? URL, url)
  }
  
  func testBinaryData() {
    let data = "Test".data(using: .utf8)
    let attribute = NSAttributeDescription.binaryData(name: "testBinaryData",
                                                      defaultValue: data,
                                                      allowsExternalBinaryDataStorage: true)
    XCTAssertEqual(attribute.name, "testBinaryData")
    XCTAssertEqual(attribute.defaultValue as? Data, data)
    XCTAssertTrue(attribute.allowsExternalBinaryDataStorage)
  }

  func testCustomTransformable() {
    let color = Color(name: "color")
    let attribute = NSAttributeDescription.customTransformable(for: Color.self, name: "testTransformable", defaultValue: color) { _ in
      return nil
    } reverse: { _ in
      return nil
    }
    XCTAssertEqual(attribute.name, "testTransformable")
    XCTAssertEqual(attribute.defaultValue as? Color, color)
  }

  func testTransformable() {
    let color = Color(name: "color")
    let attribute = NSAttributeDescription.transformable(for: Color.self, name: "testTransformable", defaultValue: color)
    XCTAssertEqual(attribute.name, "testTransformable")
    XCTAssertEqual(attribute.defaultValue as? Color, color)
  }
}
