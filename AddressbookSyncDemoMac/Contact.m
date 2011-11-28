//
//  Contact.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 28/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Contact.h"

@implementation Contact

- (void)updateManagedObjectWithAddressbookRecordDetails;
- (AddressbookRecord)findAddressbookRecord;
- (AddressbookResyncResults)syncAddressbookRecord;
- (void)resolveConflictWithAddressbookRecord:(AddressbookRecord)record;

+ (Contact *)initContactWithAddressbookRecord:(AddressbookRecord)record {
	// Add this contact to the Object Graph
	Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:MANAGED_OBJECT_CONTEXT];
	contact.addressbookIdentifier = [record uniqueId];
	contact.addressbookRecord = record;
	[contact updateManagedObjectWithAddressbookRecordDetails];
	
	return contact;
}

- (BOOL)isContactOlderThanAddressbookRecord:(AddressbookRecord)record {
	if (self.lastSync == nil) {
		return true;
	}
	NSDate *modificationDate = [record valueForProperty:kABModificationDateProperty];
	return ([self.lastSync earlierDate:modificationDate] == self.lastSync);
}

- (void)resolveConflictWithAddressbookRecord:(AddressbookRecord)record {
	self.addressbookRecord = record;
	self.addressbookIdentifier = [self.addressbookRecord uniqueId];
	[self updateManagedObjectWithAddressbookRecordDetails];
	NSLog(@"Conflict for '%@' is now resolved", self.compositeName);
}

- (NSString *)compositeName {
	if (self.isCompany) {
		return self.company;
	} else {
		NSString *firstName = (self.firstName?self.firstName:@"");
		NSString *lastName = (self.lastName?self.lastName:@"");
		if ([[ABAddressBook sharedAddressBook] defaultNameOrdering] == kABFirstNameFirst) {
			return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
		} else {
			return [NSString stringWithFormat:@"%@ %@", lastName, firstName];
		}
	}
}

- (NSString *)secondaryCompositeName {
	if (!self.isCompany) {
		return self.company;
	} else {
		NSString *firstName = (self.firstName?self.firstName:@"");
		NSString *lastName = (self.lastName?self.lastName:@"");
		if ([[ABAddressBook sharedAddressBook] defaultNameOrdering] == kABFirstNameFirst) {
			return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
		} else {
			return [NSString stringWithFormat:@"%@ %@", lastName, firstName];
		}
	}
}

@end
