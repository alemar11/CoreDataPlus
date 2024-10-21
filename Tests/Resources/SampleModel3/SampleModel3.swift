// CoreDataPlus

import CoreData

// MARK: - V1

@objc(User)
public class User: NSManagedObject {
  @NSManaged public var name: String!  // unique
  @NSManaged public var petName: String?
}

//// MARK: - V2
//
//@objc(UserV2)
//public class UserV2: NSManagedObject {
//  @NSManaged public var name: String! // unique
//  @NSManaged public var petName: String?
//  @NSManaged public var pet: Pet?
//}
//
//@objc(Pet)
//public class Pet: NSManagedObject {
//  @NSManaged public var name: String! // unique
//  @NSManaged public var owner: UserV2!
//}
//
//// MARK: - V2
//
//@objc(UserV3)
//public class UserV3: NSManagedObject {
//  @NSManaged public var name: String! // unique
//  @NSManaged public var pet: Pet?
//}
