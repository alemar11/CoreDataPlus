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
/// `CoreDataPlusError` is the error type returned by CoreDataPlus when something bad happens.
public struct CoreDataPlusError: Error {
  public private(set) var errorCode: Int
  public private(set) var message: String
  public private(set) var underlyingError: Error?
  public private(set) var file: StaticString
  public private(set) var line: Int
  public private(set) var function: StaticString

  enum ErrorCode: Int {
    case executionFailed
    case fetchCountNotFound
    case fetchExpectingOneObjectFailed
    case fetchFailed
    case persistentStoreCoordinatorNotFound
    case saveFailed
    case migrationFailed
  }
}

extension CoreDataPlusError: LocalizedError {
  public var errorDescription: String? {
    return message
  }
}

extension CoreDataPlusError {
  /// A context execution failed.
  static func executionFailed(underlyingError: Error, file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> CoreDataPlusError {
    let description = "\(underlyingError.localizedDescription)"
    return .init(errorCode: ErrorCode.executionFailed.rawValue,
                 message: description,
                 underlyingError: underlyingError,
                 file: file,
                 line: line,
                 function: function)
  }

  /// A count fetch operation failed.
  static func fetchCountNotFound(file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> CoreDataPlusError {
    return .init(errorCode: ErrorCode.fetchCountNotFound.rawValue,
                 message: "The fetch count responded with NSNotFound.",
                 underlyingError: nil,
                 file: file,
                 line: line,
                 function: function)
  }

  /// A fetch operation expecting only one object failed.
  static func fetchExpectingOneObjectFailed(file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> CoreDataPlusError {
    return .init(errorCode: ErrorCode.fetchExpectingOneObjectFailed.rawValue,
                 message: "Returned multiple objects, expected max 1.",
                 underlyingError: nil,
                 file: file,
                 line: line,
                 function: function)
  }

  /// A fetch operation failed with an underlying system error.
  static func fetchFailed(underlyingError: Error, file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> CoreDataPlusError {
    return .init(errorCode: ErrorCode.fetchFailed.rawValue,
                 message: "The fetch could not be completed because of an underlyingError error.",
                 underlyingError: underlyingError,
                 file: file,
                 line: line,
                 function:function)
  }

  /// The NSPersistentStoreCoordinator is missing.
  static func persistentStoreCoordinatorNotFound(context: NSManagedObjectContext, file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> CoreDataPlusError {
    return .init(errorCode: ErrorCode.persistentStoreCoordinatorNotFound.rawValue,
                 message: "\(context.description) doesn't have a NSPersistentStoreCoordinator.",
      underlyingError: nil, file: file, line: line, function: function)
  }

  /// A save oepration failed with an underlying system error.
  static func saveFailed(underlyingError: Error, file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> CoreDataPlusError {
    return CoreDataPlusError(errorCode: ErrorCode.saveFailed.rawValue,
                             message: "The save operation could not be completed because of an underlyingError error.",
                             underlyingError: underlyingError, file: file, line: line, function: function)
  }

  /// A migration operation failed.
  static func migrationFailed(underlyingError: Error, file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> CoreDataPlusError {
    return .init(errorCode: ErrorCode.migrationFailed.rawValue, message: "The migration could not be completed because of an underlyingError error.",
                 underlyingError: underlyingError,
                 file: file,
                 line: line,
                 function: function)
  }
}
