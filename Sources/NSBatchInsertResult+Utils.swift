//
// CoreDataPlus
//
// Copyright © 2016-2020 Tinrobots.
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

@available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
extension NSBatchInsertResult {
  /// **CoreDataPlus**
  ///
  /// Returns a dictionary containig all the inserted `NSManagedObjectID` instances ready to be passed to `NSManagedObjectContext.mergeChanges(fromRemoteContextSave:into:)`.
  public var changes: [String: [NSManagedObjectID]]? {
    guard let inserts = inserts else { return nil }

    return [NSInsertedObjectsKey: inserts]
  }

  /// **CoreDataPlus**
  ///
  /// Returns all the inserted objects `NSManagedObjectID`.
  /// - Note: Make sure the resultType of the `NSBatchInsertResult` is set to `NSBatchInsertRequestResultType.objectIDs` before the request is executed otherwise the value is nil.
  public var inserts: [NSManagedObjectID]? {
    switch resultType {
    case .count, .statusOnly:
      return nil

    case .objectIDs:
      guard let objectIDs = result as? [NSManagedObjectID] else { return nil }
      let changes = objectIDs
      return changes

    @unknown default:
      return nil
    }
  }

  /// **CoreDataPlus**
  ///
  /// Returns the number of inserted objcts.
  /// - Note: Make sure the resultType of the `NSBatchInsertResult` is set to `NSBatchInsertRequestResultType.count` before the request is executed otherwise the value is nil.
  public var count: Int? {
    switch resultType {
    case .statusOnly, .objectIDs:
      return nil

    case .count:
      return result as? Int

    @unknown default:
      return nil
    }
  }

  /// **CoreDataPlus**
  ///
  /// Returns `true` if the batch insert operation has been completed successfully.
  /// - Note: Make sure the resultType of the `NSBatchInsertResult` is set to `NSBatchInsertRequestResultType.statusOnly` before the request is executed otherwise the value is nil.
  public var status: Bool? {
    switch resultType {
    case .count, .objectIDs:
      return nil

    case .statusOnly:
      return result as? Bool

    @unknown default:
      return nil
    }
  }
}
