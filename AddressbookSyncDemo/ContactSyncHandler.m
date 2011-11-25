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
	NSOperationQueue *addressbookSyncOperationQueue = [[NSOperationQueue alloc] init];
	
	for (NSManagedObject *object in [[notification userInfo] valueForKey:NSInsertedObjectsKey]) {
		if ([object isKindOfClass:[Contact class]]) {
			NSLog(@"Contact has been added as a result of a merge");
			Contact *contact = (Contact *)object;
			NSBlockOperation *syncBlock = [NSBlockOperation blockOperationWithBlock:^{
				[contact syncAddressbookRecord];
			}];
			
			[syncBlock setCompletionBlock:^{
				if ([addressbookSyncOperationQueue operationCount] == 0) {
					NSLog(@"All iCloud import tasks complete");
					NSSet *unmatched = [[[notification userInfo] valueForKey:NSInsertedObjectsKey] filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"addressbookCacheState", kAddressbookCacheLoadFailed]];
					NSSet *ambigous = [[[notification userInfo] valueForKey:NSInsertedObjectsKey] filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"addressbookCacheState", kAddressbookCacheLoadAmbigous]];
					
					NSLog(@"Unmatched: %d Ambigous: %d", [unmatched count], [ambigous count]);
				}
			}];
			
			[addressbookSyncOperationQueue addOperation:syncBlock];
		}
	}

	for (NSManagedObject *object in [[notification userInfo] valueForKey:NSUpdatedObjectsKey]) {
		// does our object still exist?
	}
}

@end
