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

class EntityObserverTests: XCTestCase {

  func testObservers() {
    let stack = CoreDataStack.stack()
    let context = stack.mainContext
    let delegate = AnyEntityObserverDelegate(DummyCarEntityObserverDelegate())
    let entityObserver = EntityObserver<Car>(context: context, frequency: .all)
    entityObserver.delegate = delegate

    let sportCar = Car(context: context)
    sportCar.maker = "McLaren"
    sportCar.model = "570GT"
    sportCar.numberPlate = "203"
    
  }


  fileprivate class DummyCarEntityObserverDelegate : EntityObserverDelegate {


    func entityObserver(_ observer: EntityObserver<Car>, inserted: Set<Car>) {

    }

    func entityObserver(_ observer: EntityObserver<Car>, deleted: Set<Car>) {

    }

    func entityObserver(_ observer: EntityObserver<Car>, updated: Set<Car>) {

    }

    func entityObserver(_ observer: EntityObserver<Car>, refreshed: Set<Car>) {

    }

    func entityObserver(_ observer: EntityObserver<Car>, invalidated: Set<Car>) {

    }
  }

}
