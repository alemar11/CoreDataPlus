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

import CoreData

extension NSBatchDeleteResult {

  /// **CoreDataPlus**
  ///
  /// Returns a dictionary containig all the deleted `NSManagedObjectID` instances.
  /// - Note: Make sure the resultType of the `NSBatchDeleteRequest` is set to `NSBatchDeleteRequestResultType.resultTypeObjectIDs` before the request is executed otherwise the value is nil.
  public var changes: [String: [NSManagedObjectID]]? {

    switch resultType {
    case .resultTypeStatusOnly, .resultTypeCount:
      return nil

    case .resultTypeObjectIDs:
      guard let objectIDs = result as? [NSManagedObjectID] else { return nil }
      let changes = [NSDeletedObjectsKey: objectIDs]
      return changes
    }

  }

  /// **CoreDataPlus**
  ///
  /// Returns the number of deleted objcts.
  /// - Note: Make sure the resultType of the `NSBatchDeleteRequest` is set to `NSBatchDeleteRequestResultType.resultTypeCount` before the request is executed otherwise the value is nil.
  public var count: Int? {

    switch resultType {
    case .resultTypeStatusOnly, .resultTypeObjectIDs:
      return nil

    case .resultTypeCount:
      return result as? Int
    }
  }

  /// **CoreDataPlus**
  ///
  /// Returns `true` if the batc delete operation has been completed successfully.
  /// - Note: Make sure the resultType of the `NSBatchDeleteRequest` is set to `NSBatchDeleteRequestResultType.resultTypeStatusOnly` before the request is executed otherwise the value is nil.
  public var status: Bool? {

    switch resultType {
    case .resultTypeCount, .resultTypeObjectIDs:
      return nil

    case .resultTypeStatusOnly:
      return result as? Bool
    }
  }

}
