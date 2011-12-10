//
//  AppDelegate.h
//  AddressbookSyncDemoMac
//
//  Created by Tom Fewster on 27/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddressBook/ABPersonView.h>
#import "TFABAddressBook.h"

@class AmbigousContactResolverViewController;
@class UnresolvedContactResolverViewController;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
	TFAddressBook *_addressbook;
}

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSIndexSet *contactSelectionIndex;
@property (weak) IBOutlet ABPersonView *personView;
@property (weak) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet AmbigousContactResolverViewController *ambigousContactResolver;
@property (strong) IBOutlet UnresolvedContactResolverViewController *unresolvedContactResolver;

@property (weak, readonly, nonatomic) NSArray *sortDescriptors;
@property (strong) NSPredicate *searchFilter;

- (IBAction)saveAction:(id)sender;

@end
