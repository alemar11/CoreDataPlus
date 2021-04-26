//
//  MHWViewController.h
//  BookMigration
//
//  Created by Martin Hwasser on 8/26/13.
//  Copyright (c) 2013 Martin Hwasser. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MHWViewController : UIViewController
<
UITableViewDataSource,
UITableViewDelegate
>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end
