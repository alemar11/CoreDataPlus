//
//  MHWUserToUserPolicy.m
//  BookMigration
//
//  Created by Martin Hwasser on 9/1/13.
//  Copyright (c) 2013 Martin Hwasser. All rights reserved.
//

#import "MHWUserToUserPolicy.h"
#import "NSMigrationManager+Lookup.h"

@implementation MHWUserToUserPolicy

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sourceInstance
                                      entityMapping:(NSEntityMapping *)mapping
                                            manager:(NSMigrationManager *)manager
                                              error:(NSError *__autoreleasing *)error
{
    NSNumber *modelVersion = [mapping.userInfo valueForKey:@"modelVersion"];
    if (modelVersion.integerValue == 3) {
        NSManagedObject *destinationInstance = [NSEntityDescription insertNewObjectForEntityForName:[mapping destinationEntityName]
                                                                  inManagedObjectContext:[manager destinationContext]];


        NSMutableArray *sourceKeys = [sourceInstance.entity.attributesByName.allKeys mutableCopy];
        NSDictionary *sourceValues = [sourceInstance dictionaryWithValuesForKeys:sourceKeys];

        NSArray *destinationKeys = destinationInstance.entity.attributesByName.allKeys;
        for (NSString *key in destinationKeys) {
            id value = [sourceValues valueForKey:key];
            // Avoid NULL values
            if (value && ![value isEqual:[NSNull null]]) {
                [destinationInstance setValue:value forKey:key];
            }
        }

        NSSet *books = [sourceInstance valueForKey:@"books"];
        NSDictionary *filesLookup = [manager lookupWithKey:@"files"];
        for (NSManagedObject *book in books) {
            NSString *bookObjectID = book.objectID.URIRepresentation.description;
            NSManagedObject *file = [filesLookup valueForKey:bookObjectID];
            [file setValue:destinationInstance forKey:@"user"];
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
