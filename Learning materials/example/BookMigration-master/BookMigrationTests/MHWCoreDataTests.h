//
//  MHWCoreDataTests.h
//  BookMigration
//
//  Created by Martin Hwasser on 8/31/13.
//  Copyright (c) 2013 Martin Hwasser. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface MHWCoreDataTests : SenTestCase


- (void)setUpCoreDataStackMigratingFromStoreWithName:(NSString *)name;

@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end
