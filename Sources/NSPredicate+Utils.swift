// CoreDataPlus

import Foundation

extension NSPredicate {
  /// A `NSPredicate` that always evaluates to `true`.
  public static let `true` = NSPredicate(value: true)

  /// A `NSPredicate` that always evaluates to `false`.
  public static let `false` = NSPredicate(value: false)

  /// Returns a `new` compound NSPredicate formed by **AND**-ing `self` with `predicate`.
  /// - Parameter predicate: A `NSPredicate` object.
  public final func and(_ predicate: NSPredicate) -> NSPredicate {
    NSCompoundPredicate(andPredicateWithSubpredicates: [self, predicate])
  }

  /// Returns: a `new` compound NSPredicate formed by **OR**-ing `self` with `predicate`.
  /// - Parameter predicate: A `NSPredicate` object.
  public final func or(_ predicate: NSPredicate) -> NSPredicate {
    NSCompoundPredicate(orPredicateWithSubpredicates: [self, predicate])
  }
}
