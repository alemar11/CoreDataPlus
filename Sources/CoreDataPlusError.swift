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
/// `CoreDataPlusError` is the error type returned by CoreDataPlus.
///
/// - executionFailed: A context executions failed.
/// - fetchCountNotFound: A count fetch operation failed.
/// - fetchExpectingOneObjectFailed: A fetch operation expecting only one object failed.
/// - fetchFailed: A fetch operation failed with an underlying system error.
/// - persistentStoreCoordinator: The NSPersistentStoreCoordinator is missing.
/// - saveFailed: A save oepration failed with an underlying system error
public enum CoreDataPlusError: Error {

  case executionFailed(error: Error)
  case fetchCountNotFound
  case fetchExpectingOneObjectFailed
  case fetchFailed(error: Error)
  case persistentStoreCoordinatorNotFound(context: NSManagedObjectContext)
  case saveFailed(error: Error)
  case migrationFailed(error: Error)

  /// **CoreDataPlus**
  ///
  /// The `Error` returned by a system framework associated with a CoreDataPlus failure error.
  public var underlyingError: Error? {
    switch self {
    case .executionFailed(let error), .fetchFailed(let error), .saveFailed(let error), .migrationFailed(error: let error):
      return error
    default:
      return nil
    }
  }

}

// MARK: - LocalizedError

extension CoreDataPlusError: LocalizedError {

  public var errorDescription: String? {
    switch self {
    case .executionFailed(let error):
      return "\(error.localizedDescription)"

    case .fetchCountNotFound:
      return "The fetch count responded with NSNotFound."

    case .fetchExpectingOneObjectFailed:
      return "Returned multiple objects, expected max 1."

    case .fetchFailed(let error):
      return "The fetch could not be completed because of error:\n\(error)"

    case .persistentStoreCoordinatorNotFound(let context):
      return "\(context.description) doesn't have a NSPersistentStoreCoordinator."

    case .saveFailed(let error):
      return "The save operation could not be completed because of error:\n\(error)"

    case .migrationFailed(error: let error):
      return "The migration could not be completed because of error:\n\(error)"
    }
  }

}
