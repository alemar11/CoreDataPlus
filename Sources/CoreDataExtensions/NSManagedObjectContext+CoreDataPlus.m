// CoreDataPlus

#import "NSManagedObjectContext+CoreDataPlus.h"

@implementation NSManagedObjectContext (CoreDataPlus)
- (nullable NSArray *)cdp_executeFetchRequest:(nonnull NSFetchRequest *)request error:(NSError *_Nullable* _Nullable)error;
{
  // https://mjtsai.com/blog/2021/03/31/making-nsfetchrequest-fetchbatchsize-work-with-swift/
  return [self executeFetchRequest:request error:error];
}
@end
