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

  public enum MissingParameterFailureReason {
    case context(in: NSManagedObject)
    case entityName(entity: String)
    case persistentStoreCoordinator(context: String)
    case predicate(in: NSFetchRequestResult)
    
    //var underlyingError: Error?
  }

  public enum NotFoundFailureReason {
    case context
    case entity
    case persistentStoreCoordinator
    case predicate
  }
  
  public enum FailingFetchFailureReason {
    case countNotFound //TODO rename as wrongCount
    case expectingOneObject
    
    //var underlyingError: Error?
  }

  case failedFetch(reason: FailingFetchFailureReason)
  case missingParameter(reason: MissingParameterFailureReason)
}

extension CoreDataPlusError : LocalizedError {

  public var errorDescription: String? {
    switch self {
    case .failedFetch(let reason):
      return reason.localizedDescription
    case .missingParameter(let reason):
       return reason.localizedDescription
    }
  }

}

extension CoreDataPlusError.FailingFetchFailureReason: LocalizedError {
  
    public var errorDescription: String? {
      switch self {
      case .countNotFound:
        return "The fetch count responded with NSNotFound."
        
      case .expectingOneObject:
         return "Returned multiple objects, expected max 1."
      }
    }
  
}

extension CoreDataPlusError.MissingParameterFailureReason: LocalizedError {
  
  public var errorDescription: String? {
    switch self {
    case .context(let managedObject):
      return "\(managedObject.description) is missing a NSManagedObjectContext."
      
    case .entityName(let entity):
      return "\(entity) not found."
      
    case .persistentStoreCoordinator(let context):
      return "The persistent store coordinator is missing: \(context.description)"
      
    case .predicate(let fetchRequestResult):
      return "The NSPredicate in \(fetchRequestResult) is missing."
    }
  }
  
}


