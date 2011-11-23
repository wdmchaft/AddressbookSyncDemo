//
//  ContactSyncHandler.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 23/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ContactSyncHandler.h"
#import "Contact.h"

@implementation ContactSyncHandler

- (id)init {
	if (self = [super init]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudMergeNotification:) name:@"iCloudMergeNotification" object:[[UIApplication sharedApplication] delegate]];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)iCloudMergeNotification:(NSNotification *)notification {
	for (NSManagedObject *object in [[notification userInfo] valueForKey:NSInsertedObjectsKey]) {
		if ([object isKindOfClass:[Contact class]]) {
			NSLog(@"Contact has been added as a result of a merge");
			Contact *contact = (Contact *)object;
			contact.addressbookIdentifier = nil;
		}
	}

	for (NSManagedObject *object in [[notification userInfo] valueForKey:NSUpdatedObjectsKey]) {
		// does our object still exist?
	}
}

@end
