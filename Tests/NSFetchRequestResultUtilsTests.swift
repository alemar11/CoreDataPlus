// 
// CoreDataPlus
//
// Copyright © 2016-2017 Tinrobots.
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

class NSFetchRequestResultUtilsTests: XCTestCase {
    
  func fill(context: NSManagedObjectContext) {

    let person1 = Person(context: context)
    person1.firstName = ""
    person1.lastName = ""

    let person2 = Person(context: context)
    person2.firstName = ""
    person2.lastName = ""

    let person3 = Person(context: context)
    person3.firstName = ""
    person3.lastName = ""

    let person4 = Person(context: context)
    person4.firstName = ""
    person4.lastName = ""

    let person5 = Person(context: context)
    person5.firstName = ""
    person5.lastName = ""

    let person6 = Person(context: context)
    person6.firstName = ""
    person6.lastName = ""

    let person7 = Person(context: context)
    person7.firstName = ""
    person7.lastName = ""

    let person8 = Person(context: context)
    person8.firstName = ""
    person8.lastName = ""

    let person9 = Person(context: context)
    person9.firstName = ""
    person9.lastName = ""

    let person10 = Person(context: context)
    person10.firstName = ""
    person10.lastName = ""

    let person11 = Person(context: context)
    person11.firstName = ""
    person11.lastName = ""

    let person12 = Person(context: context)
    person12.firstName = ""
    person12.lastName = ""

    let person13 = Person(context: context)
    person13.firstName = ""
    person13.lastName = ""

    let person14 = Person(context: context)
    person14.firstName = ""
    person14.lastName = ""

    let person15 = Person(context: context)
    person15.firstName = ""
    person15.lastName = ""

    let person16 = Person(context: context)
    person16.firstName = ""
    person16.lastName = ""

    let person17 = Person(context: context)
    person17.firstName = ""
    person17.lastName = ""

    let person18 = Person(context: context)
    person18.firstName = ""
    person18.lastName = ""

    let person19 = Person(context: context)
    person19.firstName = ""
    person19.lastName = ""

    let person20 = Person(context: context)
    person20.firstName = ""
    person20.lastName = ""

    let car1 = Car(context: context)
    car1.maker = ""
    car1.model = ""
    car1.numberPlate = "!"
    car1.owner = nil

    let car2 = Car(context: context)
    car2.maker = ""
    car2.model = ""
    car2.numberPlate = "!"
    car2.owner = nil

    let car3 = Car(context: context)
    car3.maker = ""
    car3.model = ""
    car3.numberPlate = "!"
    car3.owner = nil

    let car4 = Car(context: context)
    car4.maker = ""
    car4.model = ""
    car4.numberPlate = "!"
    car4.owner = nil

    let car5 = Car(context: context)
    car5.maker = ""
    car5.model = ""
    car5.numberPlate = "!"
    car5.owner = nil

    let car6 = Car(context: context)
    car6.maker = ""
    car6.model = ""
    car6.numberPlate = "!"
    car6.owner = nil

    let car7 = Car(context: context)
    car7.maker = ""
    car7.model = ""
    car7.numberPlate = "!"
    car7.owner = nil

    let car8 = Car(context: context)
    car8.maker = ""
    car8.model = ""
    car8.numberPlate = "!"
    car8.owner = nil

    let car9 = Car(context: context)
    car9.maker = ""
    car9.model = ""
    car9.numberPlate = "!"
    car9.owner = nil

    let car10 = Car(context: context)
    car10.maker = ""
    car10.model = ""
    car10.numberPlate = "!"
    car10.owner = nil

    let car11 = Car(context: context)
    car11.maker = ""
    car11.model = ""
    car11.numberPlate = "!"
    car11.owner = nil

    let car12 = Car(context: context)
    car12.maker = ""
    car12.model = ""
    car12.numberPlate = "!"
    car12.owner = nil

    let car13 = Car(context: context)
    car13.maker = ""
    car13.model = ""
    car13.numberPlate = "!"
    car13.owner = nil

    let car14 = Car(context: context)
    car14.maker = ""
    car14.model = ""
    car14.numberPlate = "!"
    car14.owner = nil

    let car15 = Car(context: context)
    car15.maker = ""
    car15.model = ""
    car15.numberPlate = "!"
    car15.owner = nil

    let supercar1 = Car(context: context)
    supercar1.maker = ""
    supercar1.model = ""
    supercar1.numberPlate = "!"
    supercar1.owner = nil

    let supercar2 = Car(context: context)
    supercar2.maker = ""
    supercar2.model = ""
    supercar2.numberPlate = "!"
    supercar2.owner = nil

    let supercar3 = Car(context: context)
    supercar3.maker = ""
    supercar3.model = ""
    supercar3.numberPlate = "!"
    supercar3.owner = nil

    let supercar4 = Car(context: context)
    supercar4.maker = ""
    supercar4.model = ""
    supercar4.numberPlate = "!"
    supercar4.owner = nil

    let supercar5 = Car(context: context)
    supercar5.maker = ""
    supercar5.model = ""
    supercar5.numberPlate = "!"
    supercar5.owner = nil
  }

    
}
