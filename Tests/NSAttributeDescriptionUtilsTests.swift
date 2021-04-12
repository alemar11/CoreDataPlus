// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

final class NSAttributeDescriptionUtilsTests: XCTestCase {
  func testInt16() {
    let attribute = NSAttributeDescription.int16(name: "test16", defaultValue: 1, isOptional: false)
    XCTAssertEqual(attribute.name, "test16")
    XCTAssertEqual(attribute.defaultValue as? Int16, 1)
    XCTAssertFalse(attribute.isOptional)
  }

  func testInt32() {
    let attribute = NSAttributeDescription.int16(name: "test32", defaultValue: 11, isOptional: true)
    XCTAssertEqual(attribute.name, "test32")
    XCTAssertEqual(attribute.defaultValue as? Int32, 11)
    XCTAssertTrue(attribute.isOptional)
  }

  func testInt64() {
    let attribute = NSAttributeDescription.int16(name: "test64", defaultValue: nil, isOptional: true)
    XCTAssertEqual(attribute.name, "test64")
    XCTAssertNil(attribute.defaultValue)
    XCTAssertTrue(attribute.isOptional)
  }

  func testDecimal() {
    let attribute = NSAttributeDescription.decimal(name: "testDecimal", defaultValue: 1.11111, isOptional: true)
    XCTAssertEqual(attribute.name, "testDecimal")
    XCTAssertEqual(attribute.defaultValue as? NSDecimalNumber, NSDecimalNumber(decimal: 1.11111))
    XCTAssertTrue(attribute.isOptional)
  }

  func testFloat() {
    let attribute = NSAttributeDescription.float(name: "testFloat", defaultValue: 1.11111, isOptional: true)
    XCTAssertEqual(attribute.name, "testFloat")
    XCTAssertEqual(attribute.defaultValue as? Float, 1.11111)
    XCTAssertTrue(attribute.isOptional)
  }

  func testDouble() {
    let attribute = NSAttributeDescription.double(name: "testDouble", defaultValue: 1.11111, isOptional: false)
    XCTAssertEqual(attribute.name, "testDouble")
    XCTAssertEqual(attribute.defaultValue as? Double, 1.11111)
    XCTAssertFalse(attribute.isOptional)
  }

  func testString() {
    let attribute = NSAttributeDescription.string(name: "testString", defaultValue: "hello world", isOptional: false)
    XCTAssertEqual(attribute.name, "testString")
    XCTAssertEqual(attribute.defaultValue as? String, "hello world")
    XCTAssertFalse(attribute.isOptional)
  }

  func testBool() {
    let attribute = NSAttributeDescription.bool(name: "testBool", defaultValue: false, isOptional: false)
    XCTAssertEqual(attribute.name, "testBool")
    XCTAssertEqual(attribute.defaultValue as? Bool, false)
    XCTAssertFalse(attribute.isOptional)
  }

  func testDate() {
    let date = Date()
    let attribute = NSAttributeDescription.date(name: "testDate", defaultValue: date, isOptional: true)
    XCTAssertEqual(attribute.name, "testDate")
    XCTAssertEqual(attribute.defaultValue as? Date, date)
    XCTAssertTrue(attribute.isOptional)
  }

  func testUUID() {
    let uuid = UUID()
    let attribute = NSAttributeDescription.uuid(name: "testUUID", defaultValue: uuid, isOptional: true)
    XCTAssertEqual(attribute.name, "testUUID")
    XCTAssertEqual(attribute.defaultValue as? UUID, uuid)
    XCTAssertTrue(attribute.isOptional)
  }

  func testURI() {
    let url = URL(string: "http://www.alessandromarzoli.com/CoreDataPlus/")!
    let attribute = NSAttributeDescription.uri(name: "testURL", defaultValue: url, isOptional: false)
    XCTAssertEqual(attribute.name, "testURL")
    XCTAssertEqual(attribute.defaultValue as? URL, url)
    XCTAssertFalse(attribute.isOptional)
  }
  
  func testBinaryData() {
    let data = "Test".data(using: .utf8)
    let attribute = NSAttributeDescription.binaryData(name: "testBinaryData",
                                                      defaultValue: data,
                                                      isOptional: false,
                                                      allowsExternalBinaryDataStorage: true)
    XCTAssertEqual(attribute.name, "testBinaryData")
    XCTAssertEqual(attribute.defaultValue as? Data, data)
    XCTAssertFalse(attribute.isOptional)
    XCTAssertTrue(attribute.allowsExternalBinaryDataStorage)
  }

  func testTransformable() {

  }
}
