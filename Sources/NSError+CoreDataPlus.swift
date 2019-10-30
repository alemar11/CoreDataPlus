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
//
// https://developer.apple.com/documentation/foundation/userinfokey

import CoreData

extension NSError {
  /// The Underlying error (if any).
  /// - Note: Used for tests only.
  var underlyingError: NSError? {
    return userInfo[NSUnderlyingErrorKey] as? NSError
  }
  
  /// Debug message.
  /// - Note: Used for tests only.
  var debugMessage: String? {
    return userInfo[NSDebugDescriptionErrorKey] as? String
  }
  
  /// CoreDataPlus error codes.
  enum ErrorCode: Int {
    case persistentStoreCoordinatorNotFound = 1
    case saveFailed = 2
    case migrationFailed = 3
    case fetchFailed = 100
    case fetchCountFailed
    case fetchExpectingOnlyOneObjectFailed
    case batchUpdateFailed = 200
    case batchDeleteFailed
    case batchInsertFailed
  }
  
  /// Error Constants
  enum Key {
    static let file = "File"
    static let function = "Function"
    static let line = "Line"
    static let domain = "\(bundleIdentifier)"
  }
  
  /// A batch update operation failed.
  static func batchUpdateFailed(underlyingError: Error, file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> NSError {
    let description = "The batch update operation failed. Check the underlying error."
    let error = NSError(domain: Key.domain,
                        code: ErrorCode.batchUpdateFailed.rawValue,
                        userInfo: [NSUnderlyingErrorKey: underlyingError,
                                   NSDebugDescriptionErrorKey: description,
                                   Key.file: file,
                                   Key.function : function,
                                   Key.line : line])
    return error
  }
  
  /// A batch delete operation failed.
  static func batchDeleteFailed(underlyingError: Error, file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> NSError {
    let description = "The batch delete operation failed. Check the underlying error."
    let error = NSError(domain: Key.domain,
                        code: ErrorCode.batchDeleteFailed.rawValue,
                        userInfo: [NSUnderlyingErrorKey: underlyingError,
                                   NSDebugDescriptionErrorKey: description,
                                   Key.file: file,
                                   Key.function : function,
                                   Key.line : line])
    return error
  }
  
  /// A batch insert operation failed.
  static func batchInsertFailed(underlyingError: Error, file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> NSError {
    let description = "The batch insert operation failed. Check the underlying error."
    let error = NSError(domain: Key.domain,
                        code: ErrorCode.batchInsertFailed.rawValue,
                        userInfo: [NSUnderlyingErrorKey: underlyingError,
                                   NSDebugDescriptionErrorKey: description,
                                   Key.file: file,
                                   Key.function : function,
                                   Key.line : line])
    return error
  }
  
  /// A count fetch operation failed.
  static func fetchCountFailed(file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> NSError {
    let description = "The fetch count responded with NSNotFound."
    let error = NSError(domain: Key.domain,
                        code: ErrorCode.fetchCountFailed.rawValue,
                        userInfo: [NSDebugDescriptionErrorKey: description,
                                   Key.file: file,
                                   Key.function : function,
                                   Key.line : line])
    return error
  }
  
  /// A fetch operation expecting only one object failed.
  static func fetchExpectingOnlyOneObjectFailed(file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> NSError {
    let description = "Returned multiple objects, expected max 1."
    let error = NSError(domain: Key.domain,
                        code: ErrorCode.fetchExpectingOnlyOneObjectFailed.rawValue,
                        userInfo: [NSDebugDescriptionErrorKey: description,
                                   Key.file: file,
                                   Key.function : function,
                                   Key.line : line])
    return error
  }
  
  /// A fetch operation failed with an underlying system error.
  static func fetchFailed(underlyingError: Error, file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> NSError {
    let description = "The fetch could not be completed. Check the underlying error."
    let error = NSError(domain: Key.domain,
                        code: ErrorCode.fetchFailed.rawValue,
                        userInfo: [NSUnderlyingErrorKey: underlyingError,
                                   NSDebugDescriptionErrorKey: description,
                                   Key.file: file,
                                   Key.function : function,
                                   Key.line : line])
    return error
  }

  /// An async fetch operation failed with an undefined behaviour and not underlying errors.
  static func asyncFetchFailed(file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> NSError {
    let description = "The async fetch could not be completed. Both finalResult and operationError are nil."
    let error = NSError(domain: Key.domain,
                        code: ErrorCode.fetchFailed.rawValue,
                        userInfo: [NSDebugDescriptionErrorKey: description,
                                   Key.file: file,
                                   Key.function : function,
                                   Key.line : line])
    return error
  }
  
  /// The NSPersistentStoreCoordinator is missing.
  static func persistentStoreCoordinatorNotFound(context: NSManagedObjectContext, file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> NSError {
    let description = "\(context.description) doesn't have a NSPersistentStoreCoordinator."
    let error = NSError(domain: Key.domain,
                        code: ErrorCode.persistentStoreCoordinatorNotFound.rawValue,
                        userInfo: [NSDebugDescriptionErrorKey: description,
                                   Key.file: file,
                                   Key.function : function,
                                   Key.line : line])
    return error
  }
  
  /// A save oepration failed with an underlying system error.
  static func saveFailed(underlyingError: Error, file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> NSError {
    let description = "The save operation could not be completed. Check the underlying error."
    let error = NSError(domain: Key.domain,
                        code: ErrorCode.saveFailed.rawValue,
                        userInfo: [NSUnderlyingErrorKey: underlyingError,
                                   NSDebugDescriptionErrorKey: description,
                                   Key.file: file,
                                   Key.function : function,
                                   Key.line : line])
    return error
  }
  
  /// A migration operation failed.
  static func migrationFailed(underlyingError: Error, file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> NSError {
    let description = "The migration could not be completed. Check the underlying error."
    let error = NSError(domain: Key.domain,
                        code: ErrorCode.migrationFailed.rawValue,
                        userInfo: [NSUnderlyingErrorKey: underlyingError,
                                   NSDebugDescriptionErrorKey: description,
                                   Key.file: file,
                                   Key.function : function,
                                   Key.line : line])
    return error
  }
}
