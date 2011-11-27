//
//  AmbigousContactConflictResolverTableViewController.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 26/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Contact;

@interface AmbigousContactTableViewCell : UITableViewCell 
@property (weak) IBOutlet UILabel *text;
@property (weak) IBOutlet UILabel *detailText;
@property (weak) IBOutlet UILabel *lastModified;
@end

@interface AmbigousContactConflictResolverViewController : UIViewController

@property (weak) IBOutlet UILabel *contactName1;
@property (weak) IBOutlet UILabel *contactName2;
@property (weak) IBOutlet UITableView *tableView;
@property (weak) IBOutlet UIView *titleView;
@property (weak) Contact *contact;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@end
