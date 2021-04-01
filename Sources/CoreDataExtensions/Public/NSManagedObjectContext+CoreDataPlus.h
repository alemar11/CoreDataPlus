// CoreDataPlus

@import CoreData;

@interface NSManagedObjectContext (CoreDataPlus)

/// **CoreDataPlus**
///
/// Returns an array of objects that meet the criteria specified by a given fetch request.
/// @Note The Swift version returns an *Array* and for performance issues you should prefer using a NSArray* **for batched requests**: https://developer.apple.com/forums/thread/651325 .
- (nullable NSArray *)cdp_executeFetchRequest:(nonnull NSFetchRequest *)request error:(NSError *_Nullable* _Nullable)error;

@end
