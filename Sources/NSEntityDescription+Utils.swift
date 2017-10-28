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

extension NSEntityDescription {

  /// **CoreDataPlus**
  ///
  /// Returns the topmost ancestor entity.
  var topMostEntity: NSEntityDescription {
    return hierarchyEntities().last ?? self
  }

  /// **CoreDataPlus**
  ///
  /// Returns a collection with the entire super-entity hierarchy of `self`.
  func hierarchyEntities() -> [NSEntityDescription] {
    var entities = [self]
    var currentSuperEntity = superentity

    while let entity = currentSuperEntity {
      if !entities.contains(entity) {
        entities.append(entity)
      }
      currentSuperEntity = entity.superentity
    }

    return entities
  }

  /// **CoreDataPlus**
  ///
  /// Returns the common ancestor entity (if any) between `self` and a given `entity.`
  ///
  /// - Parameter entity: the entity to evaluate
  /// - Returns: Returns the common ancestor entity (if any).
  func commonEntityAncestor(with entity: NSEntityDescription) -> NSEntityDescription? {
    guard self != entity else { return entity }

    let selfHierarchy = Set(self.hierarchyEntities())
    let entityHirarchy = Set(entity.hierarchyEntities())
    let intersection = selfHierarchy.intersection(entityHirarchy)

    guard !intersection.isEmpty else { return nil }

    if intersection.contains(self) { return self }
    
    return entity
  }

}
