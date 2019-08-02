//
// CoreDataPlus
//
// Copyright © 2016-2019 Tinrobots.
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

// MARK: - In Memory

class CoreDataPlusTestCase: XCTestCase {
  var container: PersistentContainerHackable!
  
  override func setUp() {
    super.setUp()
    container = InMemoryPersistentContainer.makeNew()
  }
  
  override func tearDown() {
    do {
      try container.destroy()
    } catch {
      XCTFail("The persistent container couldn't be deostryed.")
    }
    container = nil
    super.tearDown()
  }
}

// MARK: - On Disk

class CoreDataPlusOnDiskTestCase: XCTestCase {
  var container: PersistentContainerHackable!
  
  override func setUp() {
    super.setUp()
    container = OnDiskPersistentContainer.makeNew()
  }
  
  override func tearDown() {
    do {
      try container.destroy()
    } catch {
      XCTFail("The persistent container couldn't be deostryed.")
    }
    container = nil
    super.tearDown()
  }
}
