// NSPredicateTests

import XCTest

final class NSPredicateUtils_Tests: XCTestCase {
  func test_AlwaysTrueAndFalsePredicates() {
    XCTAssertEqual(NSPredicate.true().predicateFormat, "TRUEPREDICATE")
    XCTAssertEqual(NSPredicate.false().predicateFormat, "FALSEPREDICATE")
  }

  func test_PredicateComposition() {
    do {
      let predicate = NSPredicate(format: "X = 10").and(NSPredicate(format: "Y = 30"))
      XCTAssertTrue(predicate == NSPredicate(format: "X = 10 AND Y = 30"))
    }
    do {
      let predicate = NSPredicate(format: "Z = 20").or(NSPredicate(format: "K = 40"))
      XCTAssertTrue(predicate == NSPredicate(format: "Z = 20 OR K = 40"))
    }
    do {
      let predicate1 = NSPredicate(format: "X = 10").and(NSPredicate(format: "Y = 30"))  // X = 10 AND Y = 30
      let predicate2 = NSPredicate(format: "Z = 20").or(NSPredicate(format: "K = 40"))  // Z = 20 OR K = 40
      let predicate3 = predicate1.and(predicate2)
      XCTAssertTrue(predicate3.description == "(X == 10 AND Y == 30) AND (Z == 20 OR K == 40)")
    }
    do {
      let predicate1 = NSPredicate(format: "X = 10").and(NSPredicate(format: "Y = 30"))  // X = 10 AND Y = 30
      let predicate2 = NSPredicate(format: "Z = 20").or(NSPredicate(format: "K = 40"))  // Z = 20 OR K = 40
      let predicate3 = predicate1.or(predicate2)
      XCTAssertTrue(predicate3.description == "(X == 10 AND Y == 30) OR (Z == 20 OR K == 40)")
    }
    do {
      let predicate1 = NSPredicate(format: "X = 10 AND V = 11").and(NSPredicate(format: "Y = 30 OR W = 5"))
      let predicate2 = NSPredicate(format: "Z = 20").or(NSPredicate(format: "K = 40 AND C = 11"))
      let predicate3 = predicate1.or(predicate2)
      XCTAssertTrue(
        predicate3.description
          == "((X == 10 AND V == 11) AND (Y == 30 OR W == 5)) OR (Z == 20 OR (K == 40 AND C == 11))")
    }
  }
}
