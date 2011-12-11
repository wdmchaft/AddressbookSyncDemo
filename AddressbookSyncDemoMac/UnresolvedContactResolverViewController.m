//
//  UnresolvedContactResolver.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 07/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UnresolvedContactResolverViewController.h"
#import "Contact.h"
#import <AddressBook/ABPersonView.h>
#import "TFPerson+CompositeName.h"

@implementation UnresolvedContactResolverViewController

@synthesize documentWindow;
@synthesize objectSheet;
@synthesize contactSelectionIndex;
@synthesize arrayController;
@synthesize personView;
@synthesize contact;
@synthesize ambigousContacts;
@synthesize _people;

- (void)awakeFromNib {
	// since we will only ever have one window, we can do this
	documentWindow = [[NSApplication sharedApplication] keyWindow];
	addressbook = [TFAddressBook addressBook];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentWindowWillClose:) name:NSWindowWillCloseNotification object:documentWindow];
}

- (void)documentWindowWillClose:(NSNotification *)note {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
}

- (IBAction)resolveConflict:(Contact *)c {
	self.contact = c;
	
	NSMutableArray *p = [NSMutableArray array];
	NSArray *people = [addressbook people];
	for (TFPerson *record in [people sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"compositeName" ascending:YES]]]) {
		[p addObject:[record uniqueId]];
		NSLog(@"%@", [record compositeName]);
	}
	_people = p;
		
	
    if (objectSheet == nil) {
        NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"UnresolvedContactResolver" bundle:myBundle];
		
		if (![nib instantiateNibWithOwner:self topLevelObjects:nil]) {
			NSBeginAlertSheet(NSLocalizedString(@"Loading of NIB failed", @"Loading of NIB failed"), @"OK", nil, nil, [[NSApp delegate] window], nil, nil, nil, nil, NSLocalizedString(@"Failed to instantiate NIB correctly", @"Failed to instantiate NIB correctly"));
			return;
		}
    }
	
	// Display the sheet
	[NSApp beginSheet:objectSheet
	   modalForWindow:documentWindow
		modalDelegate:self
	   didEndSelector:@selector(newContactSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}

- (IBAction)resolve:(id)sender {
	[NSApp endSheet:objectSheet returnCode:NSOKButton];
}

- (IBAction)later:(id)sender {
	[NSApp endSheet:objectSheet returnCode:NSCancelButton];
}

- (void)newContactSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
	if (returnCode == NSOKButton ) {
/*
		ABPerson *record = (ABPerson *)[addressbook recordForUniqueId:[self.contact.ambigousContactMatches objectAtIndex:[contactSelectionIndex firstIndex]]];
		if ([record isKindOfClass:[ABPerson class]]) {
			//			NSString *uid = [record valueForProperty:kABUIDProperty];
			[self.contact resolveConflictWithAddressbookRecord:record];
		}
 */
	}
	[objectSheet orderOut:self];
}


- (void)setContactSelectionIndex:(NSIndexSet *)value {
	contactSelectionIndex = value;
	if ([contactSelectionIndex count] != 0) {
		ABPerson *selected = (ABPerson *)[addressbook recordForUniqueId:[self.arrayController.arrangedObjects objectAtIndex:[contactSelectionIndex firstIndex]]];
		NSLog(@"Selected: '%@'", selected.compositeName);
		[personView setPerson:(ABPerson *)selected];
	} else {
		[personView setPerson:nil];
	}
}


@end