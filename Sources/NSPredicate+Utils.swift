// CoreDataPlus

import Foundation

extension NSPredicate {
  /// A `NSPredicate` that always evaluates to `true`.
  public final class func `true`() -> NSPredicate { NSPredicate(value: true) }

  /// A `NSPredicate` that always evaluates to `false`.
  public final class func `false`() -> NSPredicate { NSPredicate(value: false) }

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
