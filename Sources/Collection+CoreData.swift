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

import CoreData

// MARK: - NSManagedObject

extension Collection where Element: NSManagedObject {
  
  /// **CoreDataPlus**
  ///
  /// Fetches all faulted object in one batch executing a single fetch request for all objects that we’re interested in.
  /// - Note: Materializing all objects in one batch is faster than triggering the fault for each object on its own.
  public func fetchFaultedObjects() {
    guard !self.isEmpty else { return }
    guard let context = self.first?.managedObjectContext else { fatalError("The managed object must have a context.") }
    
    let faults = self.filter { $0.isFault }
    
    guard let mo = faults.first else { return }
    
    let request = NSFetchRequest<NSFetchRequestResult>()
    request.entity = mo.entity
    request.returnsObjectsAsFaults = false
    request.predicate = NSPredicate(format: "self IN %@", faults)
    
    do {
      try context.fetch(request)
    } catch {
      fatalError(error.localizedDescription)
    }
  }
  
  // http://www.cocoabuilder.com/archive/cocoa/150371-batch-faulting.html
  // https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CoreData/Performance.html#//apple_ref/doc/uid/TP40001075-CH25-SW6
  
  public func _fetchFaultedObjects() {
    guard !self.isEmpty else { return }
    guard let context = self.first?.managedObjectContext else { fatalError("The managed object must have a context.") }
    
    let faults = self.filter { $0.isFault }
    guard faults.count > 0 else { return }

    // avoid multiple fetches for subclass entities.
    let entities = self.entities().entitiesKeepingOnlyCommonEntityAncestors()

    for entity in entities {

      let request = NSFetchRequest<NSFetchRequestResult>()
      request.entity = entity
      request.returnsObjectsAsFaults = false
      request.predicate = NSPredicate(format: "self IN %@", faults)
      
      do {
        let r = try context.fetch(request)
        print("----fetch----")
      } catch {
        fatalError(error.localizedDescription)
      }
    }
  }


  /// Returns all the different `NSEntityDescription` defined in the collection.
  public func entities() -> Set<NSEntityDescription> {
    return Set(self.map { $0.entity })
  }

}


// MARK: - NSEntityDescription

extension Collection where Element: NSEntityDescription {

  func entitiesKeepingOnlyCommonEntityAncestors() -> Set<NSEntityDescription> {

    // grouped by the same ancestors
    let grouped = Dictionary(grouping: self) { return $0.topMostEntity }
    var result = [NSEntityDescription]()

    grouped.forEach { _, entities in

      let test = entities.reduce([]) { (result, e) -> [NSEntityDescription] in
        var newResult = result
        guard !newResult.isEmpty else { return [e] }

        for (index, entityR) in result.enumerated() {
          if let ancestor = entityR.commonEntityAncestor(with: e) {
            if !newResult.contains(ancestor) {
              newResult.remove(at: index)
              newResult.append(ancestor)
            }
          } else {
            newResult.append(e)
          }

        }

        return newResult
      }

      result.append(contentsOf: test)

    }

    return Set(result)

  }
}
