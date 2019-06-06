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

import CoreData

/// **CoreDataPlus**
///
/// Contains all the changes taking place in a `NSManagedObjectContext` for each notification.
public struct ManagedObjectContextChanges<T: NSManagedObject> {
  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were inserted into the context.
  public let inserted: Set<T>

  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were updated into the context.
  public let updated: Set<T>

  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were deleted into the context.
  public let deleted: Set<T>

  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were refreshed into the context.
  public let refreshed: Set<T>

  /// **CoreDataPlus**
  ///
  /// Returns a `Set` of objects that were invalidated into the context.
  public let invalidated: Set<T>

  /// **CoreDataPlus**
  ///
  /// When all the object in the context have been invalidated, returns a `Set` containing all the invalidated objects' NSManagedObjectID.
  public let invalidatedAll: Set<NSManagedObjectID>

  /// **CoreDataPlus**
  ///
  /// Returns `true` if there aren't any kind of changes.
  public var isEmpty: Bool {
    return inserted.isEmpty && updated.isEmpty && deleted.isEmpty && refreshed.isEmpty && invalidated.isEmpty && invalidatedAll.isEmpty
  }
}
