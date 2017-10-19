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
    let entities = self.entitiesRemovingSubclassEntities()

    print(entities.count)
    for entity in entities {

      let request = NSFetchRequest<NSFetchRequestResult>()
      request.entity = entity
      request.returnsObjectsAsFaults = false
      request.predicate = NSPredicate(format: "self IN %@", faults)
      
      do {
        let r = try context.fetch(request)
        //print(r.count)
        print(r)
      } catch {
        fatalError(error.localizedDescription)
      }
    }
  }


  /// Returns all the different `NSEntityDescription` defined in the collection.
  public func entities() -> Set<NSEntityDescription> {
    return Set(self.map { $0.entity })
  }

  /// Returns all the different `NSEntityDescription` defined in the collection.
  /// Removes all the entities that are sublcass of entities already in the collection.
  func entitiesRemovingSubclassEntities() -> Set<NSEntityDescription> {
    let entities = self.entities()
    // todo: find the real super entity (more than 1 level) --> rootSuperEntity
    var superEntities =  entities.filter{ $0.superentity == nil }
    let notSuperEntities =  entities.filter{ $0.superentity != nil }

    for subclassEntity in notSuperEntities {
      let hierarchy = Set(subclassEntity.hierarchyEntities())
      let intersection = hierarchy.intersection(superEntities)
      
      if intersection.isEmpty {
        superEntities.insert(subclassEntity)
      }
//      guard let superEntity = subclassEntity.superentity else { continue }
//
//      if !superEntities.contains(superEntity) {
//        superEntities.insert(subclassEntity)
//      }

    }

    return superEntities
  }
  
}
