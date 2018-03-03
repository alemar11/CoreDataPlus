// 
// CoreDataPlus
//
// Copyright © 2016-2018 Tinrobots.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import XCTest
import CoreData
@testable import CoreDataPlus

class ManagedObjectObserverTests: XCTestCase {

//    func testMemoryLeak() throws {
//      let stack = CoreDataStack.stack()
//      let context = stack.mainContext
//
//      let car = Car(context: context)
//      car.maker = "FIAT"
//      car.model = "Panda"
//      car.numberPlate = "1"
//
//      let expectation1 = expectation(description: "\(#function)\(#line)")
//      var observer = ManagedObjectObserver(object: car, event: .onChange) { (change, event) in
//        expectation1.fulfill()
//      }
//      weak var weakObserver = observer
//
//      car.numberPlate = "111"
//
//      waitForExpectations(timeout: 2)
//      XCTAssertNotNil(weakObserver)
//      observer = ManagedObjectObserver(object: car, event: .all) { (change, event) in }
//      XCTAssertNil(weakObserver)
//    }

}
