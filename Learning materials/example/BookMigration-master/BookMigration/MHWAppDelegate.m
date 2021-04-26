//
//  MHWAppDelegate.m
//  BookMigration
//
//  Created by Martin Hwasser on 8/26/13.
//  Copyright (c) 2013 Martin Hwasser. All rights reserved.
//

#import "MHWAppDelegate.h"

#import "MHWViewController.h"
#import "MHWCoreDataController.h"

@implementation MHWAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    // Fake an old store so that we migrate on each launch
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSBundle *bundle in [NSBundle allBundles]) {
        NSURL *oldStoreURL = [bundle URLForResource:@"Model1" withExtension:@"sqlite"];
        NSLog(@"old: %@", oldStoreURL);
        if (oldStoreURL) {
            [fileManager removeItemAtURL:[MHWCoreDataController sharedInstance].sourceStoreURL error:nil];
            [fileManager copyItemAtURL:oldStoreURL
                                 toURL:[MHWCoreDataController sharedInstance].sourceStoreURL
                                 error:nil];
            break;
        }
    }

    if ([MHWCoreDataController sharedInstance].isMigrationNeeded) {
        [[MHWCoreDataController sharedInstance] migrate:nil];
    }

    return YES;

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.viewController = [[MHWViewController alloc] initWithNibName:@"MHWViewController_iPhone" bundle:nil];
    } else {
        self.viewController = [[MHWViewController alloc] initWithNibName:@"MHWViewController_iPad" bundle:nil];
    }
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];


    return YES;
}

- (void)populateLegacyDatabase
{
    NSManagedObjectContext *moc = [MHWCoreDataController sharedInstance].managedObjectContext;

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Book"];
    NSArray *result = [moc executeFetchRequest:request error:nil];
    NSLog(@"results: %@", result);

    for (id mo in result) {
        [moc deleteObject:mo];
    }

    NSManagedObject *mo;
    NSEntityDescription *entityDescription;

    entityDescription = [NSEntityDescription entityForName:@"User" inManagedObjectContext:moc];
    mo = [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:moc];
    [mo setValue:@(1) forKey:@"userId"];
    NSManagedObject *user = mo;

    entityDescription = [NSEntityDescription entityForName:@"Book" inManagedObjectContext:moc];
    mo = [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:moc];
    [mo setValue:@"Franz Kafka" forKey:@"authorName"];
    [mo setValue:@"Metamorphosis" forKey:@"title"];
    [mo setValue:[[mo valueForKey:@"title"] stringByAppendingPathExtension:@"file"] forKey:@"fileURL"];
    [mo setValue:user forKey:@"user"];

    mo = [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:moc];
    [mo setValue:@"Franz Kafka" forKey:@"authorName"];
    [mo setValue:@"The Trial" forKey:@"title"];
    [mo setValue:[[mo valueForKey:@"title"] stringByAppendingPathExtension:@"file"] forKey:@"fileURL"];
    [mo setValue:user forKey:@"user"];

    mo = [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:moc];
    [mo setValue:@"Witold Gombrowicz" forKey:@"authorName"];
    [mo setValue:@"Cosmos" forKey:@"title"];
    [mo setValue:[[mo valueForKey:@"title"] stringByAppendingPathExtension:@"file"] forKey:@"fileURL"];
    [mo setValue:user forKey:@"user"];

    mo = [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:moc];
    [mo setValue:@"Thomas Bernhard" forKey:@"authorName"];
    [mo setValue:@"Extinction" forKey:@"title"];
    [mo setValue:[[mo valueForKey:@"title"] stringByAppendingPathExtension:@"file"] forKey:@"fileURL"];
    [mo setValue:user forKey:@"user"];

    [moc save:nil];

    request = [[NSFetchRequest alloc] initWithEntityName:@"Book"];
    result = [moc executeFetchRequest:request error:nil];
    NSLog(@"results: %@", result);
    for (id mo in result) {
        NSLog(@"mo: %@", mo);
    }

}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
