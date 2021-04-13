// CoreDataPlus

import CoreData

extension NSEntityDescription {
  #warning("Check this implementation")
  public convenience init<T: NSManagedObject>(_ aClass: T.Type, withName name: String? = .none) {
    self.init()
    self.managedObjectClassName = String(describing: aClass.self)
    // unless specified otherwise the table name is equal to the class name
    self.name = (name == nil) ? String(describing: T.self) : name
    self.isAbstract = false
    self.subentities = []
  }

  public func add(_ property: NSPropertyDescription) {
    properties.append(property)
  }
}

//extension NSEntityDescription {
//
//
//  // 1 <-> 1
//  public func makeOneToOneRelation(to destinationEntity: NSEntityDescription, toName: String, fromName: String) {
//    let relation = NSRelationshipDescription(.toOne, name: toName, destinationEntity: destinationEntity)
//    let inverse = NSRelationshipDescription(.toOne, name: fromName, destinationEntity: self)
//    relation.inverseRelationship = inverse
//    inverse.inverseRelationship = relation
//    self.add(relation)
//    destinationEntity.add(inverse)
//  }
//
//  // 1 <-> N
//  public func makeOneToManyRelation(to destinationEntity: NSEntityDescription, toName: String, fromName: String) {
//    let relation = NSRelationshipDescription(.toMany, name: toName, destinationEntity: destinationEntity)
//    let inverse = NSRelationshipDescription(.toOne, name: fromName, destinationEntity: self)
//    relation.inverseRelationship = inverse
//    inverse.inverseRelationship = relation
//    self.add(relation)
//    destinationEntity.add(inverse)
//  }
//
//  // 1 <-> N Ordered
//  public func makeOneToOrderedManyRelation(to destinationEntity: NSEntityDescription, toName: String, fromName: String) {
//    let relation = NSRelationshipDescription(.toMany, name: toName, destinationEntity: destinationEntity, isOrdered: true)
//    let inverse = NSRelationshipDescription(.toOne, name: fromName, destinationEntity: self)
//    relation.inverseRelationship = inverse
//    inverse.inverseRelationship = relation
//    self.add(relation)
//    destinationEntity.add(inverse)
//  }
//
//  // M <-> N
//  public func makeManyToManyRelation(to destinationEntity: NSEntityDescription, toName: String, fromName: String) {
//    let relation = NSRelationshipDescription(.toMany, name: toName, destinationEntity: destinationEntity)
//    let inverse = NSRelationshipDescription(.toMany, name: fromName, destinationEntity: self)
//    relation.inverseRelationship = inverse
//    inverse.inverseRelationship = relation
//    self.add(relation)
//    destinationEntity.add(inverse)
//  }
//
//  // M <-> N Ordered
//  public func makeManyToOrderedManyRelation(to destinationEntity: NSEntityDescription, toName: String, fromName: String) {
//    let relation = NSRelationshipDescription(.toMany, name: toName, destinationEntity: destinationEntity, isOrdered: true)
//    let inverse = NSRelationshipDescription(.toMany, name: fromName, destinationEntity: self)
//    relation.inverseRelationship = inverse
//    inverse.inverseRelationship = relation
//    self.add(relation)
//    destinationEntity.add(inverse)
//  }
//
//  // M Ordered <-> N Ordered
//
//  // M Ordered <-> N
//
//}
//
//extension NSRelationshipDescription {
//  public enum Kind {
//    case toOne
//    case toMany
//    // TODO
//    //case toManyBounded(min: Int, max: Int)
//  }
//
//  public convenience init(_ kind: Kind,
//                          name: String,
//                          destinationEntity: NSEntityDescription?,
//                          deleteRule: NSDeleteRule = .nullifyDeleteRule,
//                          isOrdered: Bool = false,
//                          isOptional: Bool = false) {
//    self.init()
//    self.name = name
//    self.isOptional = isOptional
//    self.isOrdered = isOrdered
//    self.deleteRule = deleteRule
//    self.destinationEntity = destinationEntity
//    switch kind {
//      case .toOne:
//        self.minCount = 1
//        self.maxCount = 1
//      case .toMany:
//        self.minCount = 0
//        self.maxCount = .max
//    }
//  }
//}
