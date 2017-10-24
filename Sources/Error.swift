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


public enum CustomError: Error {
  case failedFetchExecution(reason: String)
  case missingContext
  case missingEntityName(entity: String)
  case missingPersistentStoreCoordinator(context: NSManagedObjectContext)
  case missingPredicate
  //missingModuleVersion

  public enum MissingParameterFailureReason {
    case context(in: NSManagedObject)
    case entityName(entity: String)
    case persistentStoreCoordinator(context: NSManagedObjectContext)
    case predicate(in: NSFetchRequestResult)
  }

  public enum FailingFetchFailureReason {
    case count
    case expectingOneObject
  }

  case failedFetch(reason: FailingFetchFailureReason)
  case missingParameter(reason: MissingParameterFailureReason)
}

extension CustomError : LocalizedError {

//  public var errorDescription: String? {
//    switch self {
//    case .failedFetchExecution(let reason):
//      return "Failed executions: \(reason)"
//    case .missingContext:
//       return "The managed object must have a context."
//    case .missingEntityName(let entity):
//       return "Entity \(entity) not found."
//    case .missingPersistentStoreCoordinator(let context):
//       return "The persistent store coordinator of \(context.description) is missing."
//    case .missingPredicate:
//       return ""
//    }
//  }

  //  var errorDescription: String?
  //  var failureReason: String?
  //  var recoverySuggestion: String?
  //  var helpAnchor: String?

  //private var description : String

//let c = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

  //  init(_ description: String) {
  //    errorDescription = description
  //  }
  //
  //  init(description: String, reason: String) {
  //    errorDescription = description
  //    failureReason = reason
  //  }
  //
  //  init(description: String, reason: String, suggestion: String) {
  //    errorDescription = description
  //    failureReason = reason
  //    recoverySuggestion = suggestion
  //
  //  }
  //
  //  init(description: String, reason: String, suggestion: String, help: String) {
  //    errorDescription = description
  //    failureReason = reason
  //    recoverySuggestion = suggestion
  //    helpAnchor = help
  //  }

}


