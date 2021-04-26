//
//  NSFileManager+MHWAdditions.m
//  BookMigration
//
//  Created by Martin Hwasser on 8/26/13.
//  Copyright (c) 2013 Martin Hwasser. All rights reserved.
//

#import "NSFileManager+MHWAdditions.h"

@implementation NSFileManager (MHWAdditions)

+ (NSURL *)urlToApplicationSupportDirectory
{
	NSString *applicationSupportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
																				 NSUserDomainMask,
																				 YES) objectAtIndex:0];
	BOOL isDir = NO;
	NSError *error = nil;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
	if (![fileManager fileExistsAtPath:applicationSupportDirectory
                           isDirectory:&isDir] && isDir == NO) {
		[fileManager createDirectoryAtPath:applicationSupportDirectory
               withIntermediateDirectories:NO
                                attributes:nil
                                     error:&error];
	}
    return [NSURL fileURLWithPath:applicationSupportDirectory];
}

@end
