//
//  UnresolvedContactResolver.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 07/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TFABAddressBook.h"

@class Contact;
@class ABPersonView;

@interface UnresolvedContactResolverViewController : NSViewController

@property (nonatomic, strong) IBOutlet NSWindow *documentWindow;
@property (nonatomic, strong) IBOutlet NSPanel *objectSheet;
@property (weak) IBOutlet ABPersonView *personView;
@property (weak) IBOutlet NSArrayController *arrayController;
@property (nonatomic, retain) NSIndexSet *contactSelectionIndex;
@property (nonatomic, strong) Contact *contact;
@property (strong) NSArray *ambigousContacts;

- (IBAction)resolveConflict:(Contact *)contact;
- (IBAction)later:(id)sender;
- (IBAction)resolve:(id)sender;

@end
