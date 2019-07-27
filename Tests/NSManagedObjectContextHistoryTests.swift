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

class NSManagedObjectContextHistoryTests: XCTestCase {
  func testMergeHistoryAfterDate() throws {
    let id = UUID()
    let container1 = OnDiskPersistentContainer.makeNew(id: id)
    let container2 = OnDiskPersistentContainer.makeNew(id: id)
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let viewContext1 = container1.viewContext
    let viewContext2 = container2.viewContext

    viewContext1.fillWithSampleData()

    try viewContext1.save()

    XCTAssertFalse(viewContext1.registeredObjects.isEmpty)
    XCTAssertTrue(viewContext2.registeredObjects.isEmpty)

    let token = viewContext2.addManagedObjectContextObjectsDidChangeNotificationObserver { notification in
      XCTAssertEqual(notification.insertedObjects.count, 145)
      expectation1.fulfill()
    }

    let date = try viewContext2.mergeHistory(after: .distantPast)
    XCTAssertNotNil(date)
    XCTAssertTrue(viewContext2.registeredObjects.isEmpty)

    waitForExpectations(timeout: 5, handler: nil)
    NotificationCenter.default.removeObserver(token)
    let status = try viewContext2.deleteHistory(before: date!)
    XCTAssertTrue(status)
  }
}
