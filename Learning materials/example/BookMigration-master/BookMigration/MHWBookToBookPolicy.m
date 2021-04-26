//
//  MHWBookToBookPolicy.m
//  BookMigration
//
//  Created by Martin Hwasser on 8/27/13.
//  Copyright (c) 2013 Martin Hwasser. All rights reserved.
//

#import "MHWBookToBookPolicy.h"
#import "NSMigrationManager+Lookup.h"

@implementation MHWBookToBookPolicy

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sourceInstance
                                      entityMapping:(NSEntityMapping *)mapping
                                            manager:(NSMigrationManager *)manager
                                              error:(NSError *__autoreleasing *)error
{
    NSNumber *modelVersion = [mapping.userInfo valueForKey:@"modelVersion"];
    if (modelVersion.integerValue == 2 || modelVersion.integerValue == 3) {

        NSMutableArray *sourceKeys = [sourceInstance.entity.attributesByName.allKeys mutableCopy];
        NSDictionary *sourceValues = [sourceInstance dictionaryWithValuesForKeys:sourceKeys];

        NSManagedObject *destinationInstance = [NSEntityDescription insertNewObjectForEntityForName:[mapping destinationEntityName]
                                                                             inManagedObjectContext:[manager destinationContext]];
        NSArray *destinationKeys = destinationInstance.entity.attributesByName.allKeys;

        for (NSString *key in destinationKeys) {
            id value = [sourceValues valueForKey:key];
            // Avoid NULL values
            if (value && ![value isEqual:[NSNull null]]) {
                [destinationInstance setValue:value forKey:key];
            }
        }

        if (modelVersion.integerValue == 2) {
            // Check if we've already created the authors lookup
            NSMutableDictionary *authorLookup = [manager lookupWithKey:@"authors"];
            // Check if we've already created this author
            NSString *authorName = [sourceInstance valueForKey:@"authorName"];
            NSManagedObject *author = [authorLookup valueForKey:authorName];
            if (!author) {
                // Create the author
                author = [NSEntityDescription insertNewObjectForEntityForName:@"Author"
                                                       inManagedObjectContext:[manager destinationContext]];

                [author setValue:authorName forKey:@"name"];

                // Populate lookup for reuse
                [authorLookup setValue:author forKey:authorName];
            }
            [destinationInstance performSelector:@selector(addAuthorsObject:) withObject:author];
        } else if (modelVersion.integerValue == 3) {
            NSArray *sourceUsers = [sourceInstance valueForKey:@"users"];
            for (NSManagedObject *sourceUser in sourceUsers) {

                NSManagedObject *file = [NSEntityDescription insertNewObjectForEntityForName:@"File"
                                                                      inManagedObjectContext:manager.destinationContext];
                [file setValue:[sourceInstance valueForKey:@"fileURL"] forKey:@"fileURL"];
                [file setValue:destinationInstance forKey:@"book"];
                
                NSInteger userId = [[sourceUser valueForKey:@"userId"] integerValue];
                NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
                request.predicate = [NSPredicate predicateWithFormat:@"userId = %d", userId];
                NSManagedObject *destinationUser = [[manager.destinationContext executeFetchRequest:request error:nil] lastObject];
                [file setValue:destinationUser forKey:@"user"];
            }
        }
        [manager associateSourceInstance:sourceInstance
                 withDestinationInstance:destinationInstance
                        forEntityMapping:mapping];

        return YES;
    } else {
        return [super createDestinationInstancesForSourceInstance:sourceInstance
                                                    entityMapping:mapping
                                                          manager:manager
                                                            error:error];
    }
}


@end
