//
//  MHWCoreDataTests.m
//  BookMigration
//
//  Created by Martin Hwasser on 8/31/13.
//  Copyright (c) 2013 Martin Hwasser. All rights reserved.
//

#import "MHWCoreDataTests.h"
#import "MHWMigrationManager.h"
#import "MHWCoreDataController.h"

@implementation MHWCoreDataTests

- (void)setUpCoreDataStackMigratingFromStoreWithName:(NSString *)name
{
    NSURL *storeURL = [self temporaryRandomURL];
    [self copyStoreWithName:name toURL:storeURL];

    NSURL *momURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];

    NSString *storeType = NSSQLiteStoreType;

    MHWMigrationManager *migrationManager = [MHWMigrationManager new];
    migrationManager.delegate = [MHWCoreDataController sharedInstance];
    NSError *error = nil;
    if (![migrationManager progressivelyMigrateURL:storeURL
                                            ofType:storeType
                                           toModel:self.managedObjectModel
                                             error:&error]) {
        NSLog(@"error migrating: %@", error);
    }

    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    [self.persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                  configuration:nil
                                                            URL:storeURL
                                                        options:nil
                                                          error:nil];

    self.managedObjectContext = [[NSManagedObjectContext alloc] init];
    self.managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
}

- (NSURL *)temporaryRandomURL
{
    NSString *uniqueName = [NSProcessInfo processInfo].globallyUniqueString;
    return [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:uniqueName]];
}

- (void)copyStoreWithName:(NSString *)name toURL:(NSURL *)url
{
    // Create a unique url every test so migration always runs
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSFileManager *fileManager = [NSFileManager new];
    NSString *path = [bundle pathForResource:[name stringByDeletingPathExtension] ofType:name.pathExtension];
    [fileManager copyItemAtPath:path
                         toPath:url.path error:nil];
}

@end
