//
//  SelectContactSheetController.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 28/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SelectContactSheetController.h"
#import <AddressBook/AddressBook.h>
#import "Contact.h"

@implementation SelectContactSheetController

@synthesize documentWindow;
@synthesize objectSheet;
@synthesize peoplePicker;

- (void)awakeFromNib {
	// since we will only ever have one window, we can do this
	documentWindow = [[NSApplication sharedApplication] keyWindow];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentWindowWillClose:) name:NSWindowWillCloseNotification object:documentWindow];
}

- (void)documentWindowWillClose:(NSNotification *)note {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
}


- (IBAction)addContact:(id)sender {
    if (objectSheet == nil) {
        NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"SelectContact" bundle:myBundle];
		
		if (![nib instantiateNibWithOwner:self topLevelObjects:nil]) {
			NSBeginAlertSheet(NSLocalizedString(@"Loading of NIB failed", @"Loading of NIB failed"), @"OK", nil, nil, [[NSApp delegate] window], nil, nil, nil, nil, NSLocalizedString(@"Failed to instantiate NIB correctly", @"Failed to instantiate NIB correctly"));
			return;
		}
    }
	
	[peoplePicker addObserver:self forKeyPath:@"selectedValues" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];
	
	[peoplePicker setTarget:self];
	[peoplePicker setNameDoubleAction:@selector(complete:)];
	
	// Display the sheet
	[NSApp beginSheet:objectSheet
	   modalForWindow:documentWindow
		modalDelegate:self
	   didEndSelector:@selector(newContactSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}

- (IBAction)complete:sender {
	[NSApp endSheet:objectSheet returnCode:NSOKButton];
}

- (IBAction)cancelOperation:sender {
	[NSApp endSheet:objectSheet returnCode:NSCancelButton];
}

- (void)newContactSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
	if (returnCode == NSOKButton ) {
		
		NSArray *selectedContacts = [peoplePicker selectedRecords];
		for (ABRecord *record in selectedContacts) {
			if ([record isKindOfClass:[ABPerson class]]) {
				NSString *uid = [record valueForProperty:kABUIDProperty];
				NSLog(@"Adding person: %@ %@ [%@]", [record valueForProperty:kABFirstNameProperty], [record valueForProperty:kABLastNameProperty], uid);
				[Contact initContactWithAddressbookRecord:record];
			}
		}
	}
	
	[objectSheet orderOut:self];
}

@end
