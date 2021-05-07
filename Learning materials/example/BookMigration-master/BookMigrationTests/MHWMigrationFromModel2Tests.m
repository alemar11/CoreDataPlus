//
//  MHWMigrationFromModel2Tests.m
//  BookMigration
//
//  Created by Martin Hwasser on 9/1/13.
//  Copyright (c) 2013 Martin Hwasser. All rights reserved.
//

#import "MHWMigrationFromModel2Tests.h"

@implementation MHWMigrationFromModel2Tests

- (void)setUp
{
    [super setUp];
    [self setUpCoreDataStackMigratingFromStoreWithName:@"Model1.sqlite"];
}

- (void)testThatUserHasFiles
{
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];
    request.predicate = [NSPredicate predicateWithFormat:@"userId == 1"];
    NSArray *users = [moc executeFetchRequest:request error:nil];
    STAssertTrue(0 < users.count, @"Users have disappeared after migration");
    NSManagedObject *user = users.lastObject;
    NSSet *files = [user valueForKey:@"files"];
    STAssertTrue(files.count == 4, @"Wrong files count: %d", files.count);
}

- (void)testThatFilesHaveBooks
{
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"File"];
    NSArray *files = [moc executeFetchRequest:request error:nil];
    for (NSManagedObject *file in files) {
        STAssertNotNil([file valueForKey:@"book"], @"No book on file");
    }
}

- (void)testThatBooksHaveAuthors
{
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Book"];
    NSArray *books = [moc executeFetchRequest:request error:nil];
    for (NSManagedObject *book in books) {
        STAssertNotNil([book valueForKey:@"authors"], @"No author on file");
    }
}

@end
