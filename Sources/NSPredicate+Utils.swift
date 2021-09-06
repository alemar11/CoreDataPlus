// CoreDataPlus

import Foundation

extension NSPredicate {
  /// An always `true` NSPredicate.
  public static let `true` = NSPredicate(value: true)

  /// An always `false` NSPredicate.
  public static let `false` = NSPredicate(value: false)

  /// Returns a `new` compound NSPredicate formed by **AND**-ing `self` with `predicate`.
  /// - Parameter predicate: A `NSPredicate` object.
  public final func and(_ predicate: NSPredicate) -> NSPredicate { NSCompoundPredicate(andPredicateWithSubpredicates: [self, predicate]) }

  /// Returns: a `new` compound NSPredicate formed by **OR**-ing `self` with `predicate`.
  /// - Parameter predicate: A `NSPredicate` object.
  public final func or(_ predicate: NSPredicate) -> NSPredicate { NSCompoundPredicate(orPredicateWithSubpredicates: [self, predicate]) }
}
