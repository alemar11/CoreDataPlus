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

import Foundation
import CoreData


public enum CoreDataPlusError: Error {

  // TODO: better naming?
  case contextOperationFailed(reason: ContextOperationFailureReason)
  case configurationFailed(reason: MissingParameterFailureReason)

  public var underlyingError: Error? {
    switch self {
    case .configurationFailed(let reason):
      return reason.underlyingError
    case .contextOperationFailed(let reason):
      return reason.underlyingError
    }
  }

  //TODO rename
  public enum MissingParameterFailureReason {
    case context(in: NSManagedObject)
    case entityName(entity: String)
    case persistentStoreCoordinator(context: NSManagedObjectContext)
    case predicate(in: NSFetchRequestResult)

    public var underlyingError: Error? {
      return nil
    }
  }

  // TODO: better naming?
  public enum ContextOperationFailureReason {
    case fetchCountNotFound
    case fetchExpectingOneObjectFailed
    case fetchFailed(error: Error)
    case saveFailed(error: Error)

    public var underlyingError: Error? {
      switch self {
      case .fetchFailed(let error):
        return error
      case .saveFailed(let error):
        return error
      default:
        return nil
      }
    }

  }



}

extension CoreDataPlusError : LocalizedError {

  public var errorDescription: String? {
    switch self {
    case .contextOperationFailed(let reason):
      return reason.localizedDescription
    case .configurationFailed(let reason):
      return reason.localizedDescription
    }
  }

}

extension CoreDataPlusError.ContextOperationFailureReason: LocalizedError {
  
  public var errorDescription: String? {
    switch self {
    case .fetchCountNotFound:
      return "The fetch count responded with NSNotFound."

    case .fetchExpectingOneObjectFailed:
      return "Returned multiple objects, expected max 1."

    case .fetchFailed(let error):
      return "The fetch could not be completed because of error:\n\(error.localizedDescription)"

    case .saveFailed(let error):
      return "The save operation could not be completed because of error:\n\(error.localizedDescription)"
    }
  }
  
}

extension CoreDataPlusError.MissingParameterFailureReason: LocalizedError {
  
  public var errorDescription: String? {
    switch self {
    case .context(let managedObject):
      return "\(managedObject.description) doesn't have a NSManagedObjectContext."
      
    case .entityName(let entity):
      return "\(entity) not found."
      
    case .persistentStoreCoordinator(let context):
      return "\(context.description) doesn't have a NSPersistentStoreCoordinator."
      
    case .predicate(let fetchRequestResult):
      return "\(fetchRequestResult) doesn't have a NSPredicate."
    }
  }
  
}


