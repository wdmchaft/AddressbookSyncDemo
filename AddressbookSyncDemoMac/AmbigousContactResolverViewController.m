//
//  AmbigousContactResolverViewController.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 04/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AmbigousContactResolverViewController.h"
#import "Contact.h"
#import <AddressBook/ABPersonView.h>
#import "TFPerson+CompositeName.h"

@implementation AmbigousContactResolverViewController

@synthesize documentWindow;
@synthesize objectSheet;
@synthesize contactSelectionIndex;
@synthesize arrayController;
@synthesize personView;
@synthesize contact;
@synthesize ambigousContacts;

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

    if (objectSheet == nil) {
        NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"AmbigousContactResolver" bundle:myBundle];
		
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
		TFRecordID uid = [self.contact.ambigousContactMatches objectAtIndex:[contactSelectionIndex firstIndex]];
		ABPerson *record = (ABPerson *)[addressbook recordForUniqueId:uid];
		if ([record isKindOfClass:[ABPerson class]]) {
			//			NSString *uid = [record valueForProperty:kABUIDProperty];
			[self.contact resolveConflictWithAddressbookRecordId:uid];
		}
	}
	[objectSheet orderOut:self];
}

- (void)setContactSelectionIndex:(NSIndexSet *)value {
	contactSelectionIndex = value;
	if ([contactSelectionIndex count] != 0) {
		ABPerson *selected = (ABPerson *)[addressbook recordForUniqueId:[self.contact.ambigousContactMatches objectAtIndex:[contactSelectionIndex firstIndex]]];
		NSLog(@"Selected: '%@'", selected.compositeName);
		[personView setPerson:(ABPerson *)selected];
	} else {
		[personView setPerson:nil];
	}
}

@end
