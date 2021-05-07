//
//  NSManagedObjectModel+MHWAdditions.h
//  BookMigration
//
//  Created by Martin Hwasser on 9/7/13.
//  Copyright (c) 2013 Martin Hwasser. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectModel (MHWAdditions)

+ (NSArray *)mhw_allModelPaths;
- (NSString *)mhw_modelName;

@end
