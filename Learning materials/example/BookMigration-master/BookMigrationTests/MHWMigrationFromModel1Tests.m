//
//  BookMigrationTests.m
//  BookMigrationTests
//
//  Created by Martin Hwasser on 8/26/13.
//  Copyright (c) 2013 Martin Hwasser. All rights reserved.
//

#import "MHWMigrationFromModel1Tests.h"
#import "MHWMigrationManager.h"

@implementation MHWMigrationFromModel1Tests

- (void)tearDown
{
    // Tear-down code here.

    [super tearDown];
}

- (void)setUp
{
    [super setUp];
    [self setUpCoreDataStackMigratingFromStoreWithName:@"Model1.sqlite"];
}

- (void)testThatUsersExist
{
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];
    NSArray *users = [moc executeFetchRequest:request error:nil];
    STAssertTrue(0 < users.count, @"Users have disappeared after migration");
}

- (void)testThatAuthorsExists
{
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Book"];
    NSArray *books = [moc executeFetchRequest:request error:nil];
    STAssertTrue(0 < books.count, @"Books have disappeared after migration");
    for (NSManagedObject *book in books) {
        STAssertNotNil([book valueForKey:@"authors"], @"No authors");
    }
}

- (void)testThatAuthorNameIsUnique
{
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Author"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name LIKE 'Franz Kafka'"];
    request.predicate = predicate;
    NSInteger count = [moc countForFetchRequest:request error:nil];
    STAssertTrue(1 == count, @"Wrong count for authors: %d", count);
}

- (void)testCreatedTwoBooksWithSameAuthor
{
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Book"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY authors.name LIKE 'Franz Kafka'"];
    request.predicate = predicate;
    NSInteger count = [moc countForFetchRequest:request error:nil];
    STAssertTrue(2 == count, @"Wrong count for authors: %d", count);
}

@end
