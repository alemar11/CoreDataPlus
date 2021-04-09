// CoreDataPlus

import XCTest
import CoreData
@testable import CoreDataPlus

class TransformerTests: CoreDataPlusOnDiskTestCase {
  @objc(Dummy)
  class Dummy: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }
    let name: String

    init(name: String) {
      self.name = name
    }

    func encode(with coder: NSCoder) {
      coder.encode(name, forKey: "name")
    }

    required init?(coder decoder: NSCoder) {
      guard let name = decoder.decodeObject(of: [NSString.self], forKey: "name") as? String else { return nil }
      self.name = name
    }
  }

  func testSaveAndFetchTransformableValue() throws {
    let context = container.viewContext
    let car = Car(context: context)
    car.maker = "FIAT"
    car.model = "Panda"
    car.numberPlate = "1"
    car.color = Color(name: "red")
    try context.save()
    context.reset()

    let firstCar = try XCTUnwrap(try Car.fetchOne(in: context, where: NSPredicate(value: true)))

    let color = try XCTUnwrap(firstCar.color)
    XCTAssertEqual(color.name, "red")
  }

  func testUnregister() {
    XCTAssertFalse(Foundation.ValueTransformer.valueTransformerNames().contains(Transformer<Dummy>.transformerName))
    Transformer<Dummy>.register()
    XCTAssertTrue(Foundation.ValueTransformer.valueTransformerNames().contains(Transformer<Dummy>.transformerName))
    Transformer<Dummy>.unregister()
    XCTAssertFalse(Foundation.ValueTransformer.valueTransformerNames().contains(Transformer<Dummy>.transformerName))
  }
  
  
}
