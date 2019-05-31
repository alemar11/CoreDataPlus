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

import Foundation

/// **CoreDataPlus**
///
/// `OptionSet` with all the observable NSMAnagedObjectContext events.
public struct ObservedEvent: OptionSet {
  public let rawValue: UInt

  public init(rawValue: UInt) {
    self.rawValue = rawValue
  }

  /// **CoreDataPlus**
  ///
  /// Notifications will be sent upon `NSManagedObjectContext` being changed.
  public static let change = ObservedEvent(rawValue: 1 << 0)

  /// **CoreDataPlus**
  ///
  /// Notifications will be sent upon `NSManagedObjectContext` being saved.
  public static let save = ObservedEvent(rawValue: 1 << 1)

  /// **CoreDataPlus**
  ///
  /// Notifications will be sent upon `NSManagedObjectContext` being saved or changed.
  public static let all: ObservedEvent = [.change, .save]
}
