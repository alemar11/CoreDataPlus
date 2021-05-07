//
//  MHWCoreDataController.h
//  BookMigration
//
//  Created by Martin Hwasser on 8/26/13.
//  Copyright (c) 2013 Martin Hwasser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MHWMigrationManager.h"

@interface MHWCoreDataController : NSObject <MHWMigrationManagerDelegate>

+ (MHWCoreDataController *)sharedInstance;

- (BOOL)isMigrationNeeded;
- (BOOL)migrate:(NSError *__autoreleasing *)error;

- (NSURL *)sourceStoreURL;

@property (nonatomic, readonly, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end
