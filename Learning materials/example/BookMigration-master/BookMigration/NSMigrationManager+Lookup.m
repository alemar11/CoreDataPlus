//
//  NSMigrationManager+Lookup.m
//  BookMigration
//
//  Created by Martin Hwasser on 9/1/13.
//  Copyright (c) 2013 Martin Hwasser. All rights reserved.
//

#import "NSMigrationManager+Lookup.h"

@implementation NSMigrationManager (Lookup)

- (NSMutableDictionary *)lookupWithKey:(NSString *)lookupKey
{
    NSMutableDictionary *userInfo = (NSMutableDictionary *)self.userInfo;
    // Check if we've already created a userInfo dictionary
    if (!userInfo) {
        userInfo = [@{} mutableCopy];
        self.userInfo = userInfo;
    }

    NSMutableDictionary *lookup = [userInfo valueForKey:lookupKey];
    if (!lookup) {
        lookup = [@{} mutableCopy];
        [userInfo setValue:lookup forKey:lookupKey];
    }
    return lookup;
}

@end
