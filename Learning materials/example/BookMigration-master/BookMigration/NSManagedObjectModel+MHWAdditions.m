//
//  NSManagedObjectModel+MHWAdditions.m
//  BookMigration
//
//  Created by Martin Hwasser on 9/7/13.
//  Copyright (c) 2013 Martin Hwasser. All rights reserved.
//

#import "NSManagedObjectModel+MHWAdditions.h"

@implementation NSManagedObjectModel (MHWAdditions)

+ (NSArray *)mhw_allModelPaths
{
    //Find all of the mom and momd files in the Resources directory
    NSMutableArray *modelPaths = [NSMutableArray array];
    NSArray *momdArray = [[NSBundle mainBundle] pathsForResourcesOfType:@"momd"
                                                            inDirectory:nil];
    for (NSString *momdPath in momdArray) {
        NSString *resourceSubpath = [momdPath lastPathComponent];
        NSArray *array = [[NSBundle mainBundle] pathsForResourcesOfType:@"mom"
                                                            inDirectory:resourceSubpath];
        [modelPaths addObjectsFromArray:array];
    }
    NSArray *otherModels = [[NSBundle mainBundle] pathsForResourcesOfType:@"mom"
                                                              inDirectory:nil];
    [modelPaths addObjectsFromArray:otherModels];
    return modelPaths;
}

- (NSString *)mhw_modelName
{
    NSString *modelName = nil;
    NSArray *modelPaths = [[self class] mhw_allModelPaths];
    for (NSString *modelPath in modelPaths) {
        NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
        NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        if ([model isEqual:self]) {
            modelName = modelURL.lastPathComponent.stringByDeletingPathExtension;
            break;
        }
    }
    return modelName;
}

@end
