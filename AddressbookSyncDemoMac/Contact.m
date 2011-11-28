//
//  Contact.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 28/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Contact.h"

@implementation Contact


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

- (void)updateManagedObjectWithAddressbookRecordDetails {
	if (self.addressbookRecord == 0) {
		NSLog(@"Can't update record, object's _addressbookRecord is nil");
		return;
	}
	
	NSInteger personFlags = [[self.addressbookRecord valueForProperty:kABPersonFlags] integerValue];
	self.isCompany = !(personFlags && kABShowAsPerson);
	
	self.firstName = [self.addressbookRecord valueForProperty:kABFirstNameProperty];
	self.lastName = [self.addressbookRecord valueForProperty:kABLastNameProperty];
	self.company = [self.addressbookRecord valueForProperty:kABOrganizationProperty];
	
	NSDate *modificationDate = [self.addressbookRecord valueForProperty:kABModificationDateProperty];
	if (modificationDate) {
		self.lastSync = modificationDate;
	} else {
		NSLog(@"Contact has no last modification date");
	}
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
}

- (AddressbookRecord)findAddressbookRecord {
	if (!self.addressbookRecord) {
		if (self.addressbookIdentifier) {
			self.addressbookRecord = [[ABAddressBook sharedAddressBook] recordForUniqueId:self.addressbookIdentifier];
			if (self.addressbookRecord == nil) { // i.e. we couldn't find the record
				NSLog(@"The value we had for addressbook identifier was incorrect (contact didn't exist)");
				self.addressbookIdentifier = 0;
				[[ContactMappingCache sharedInstance] removeIdentifierForContact:self];
				_addressbookCacheState = kAddressbookCacheNotLoaded;
				[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
			}
		}
	}
	
	return self.addressbookRecord;
}

- (AddressbookResyncResults)syncAddressbookRecord {
	@synchronized(self) {
		if (!self.addressbookIdentifier && _addressbookCacheState == kAddressbookCacheNotLoaded) {
			ABAddressBook *addressbook = [ABAddressBook addressBook];
			_addressbookCacheState = kAddressbookCacheCurrentlyLoading;
			NSLog(@"We need to look up the contact & attempt to sync with Addressbook");
			__block NSString *searchFirstName;
			__block NSString *searchLastName;
			__block NSString *searchCompany;
			__block BOOL searchIsCompany;
			
			void (^setup)(void) = ^{
				searchFirstName = self.firstName;
				searchLastName = self.lastName;
				searchCompany = self.company;
				searchIsCompany = self.isCompany;
			};
			
			if ([NSOperationQueue mainQueue] != [NSOperationQueue currentQueue]) {
				[[NSOperationQueue mainQueue] addOperationWithBlock:setup];
				[[NSOperationQueue mainQueue] waitUntilAllOperationsAreFinished];
			} else {
				setup();
			}


			ABSearchElement *firstNameSearchElement = [ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:searchFirstName comparison:kABEqualCaseInsensitive];
			ABSearchElement *lastNameSearchElement = [ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil value:searchLastName comparison:kABEqualCaseInsensitive];
			ABSearchElement *companySearchElement = [ABPerson searchElementForProperty:kABOrganizationProperty label:nil key:nil value:searchCompany comparison:kABEqualCaseInsensitive];

			ABSearchElement *compositeSearchElement = [ABSearchElement searchElementForConjunction:kABSearchAnd children:[NSArray arrayWithObjects:firstNameSearchElement, lastNameSearchElement, companySearchElement, nil]];
			
			NSArray *people = [addressbook recordsMatchingSearchElement:compositeSearchElement];

			// Filter out everyone who matches these properties & doesn't currently have a mapping to a existing Contact
			NSArray *filteredPeople = [people filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
				NSInteger personFlags = [[(ABPerson *)evaluatedObject valueForProperty:kABPersonFlags] integerValue];
				return (self.isCompany != (personFlags && kABShowAsPerson));
			}]];
			
			NSUInteger count = [filteredPeople count];
			
			if (count == 0) {
				NSLog(@"No match found for '%@'", self.compositeName);
				_addressbookCacheState = kAddressbookCacheLoadFailed;
				return kAddressbookSyncMatchFailed;
			} else if (count == 1) {
				self.addressbookRecord = [filteredPeople lastObject];
				self.addressbookIdentifier = [self.addressbookRecord uniqueId];
				[[ContactMappingCache sharedInstance] setIdentifier:[NSString stringWithFormat:@"%d", self.addressbookIdentifier] forContact:self];
				// we need to update our managed object back on the main thread
				if ([NSOperationQueue mainQueue] != [NSOperationQueue currentQueue]) {
					[[NSOperationQueue mainQueue] addOperationWithBlock:^{
						[self updateManagedObjectWithAddressbookRecordDetails];
					}];
					[[NSOperationQueue mainQueue] waitUntilAllOperationsAreFinished];
				} else {
					[self updateManagedObjectWithAddressbookRecordDetails];
				}
				NSLog(@"Match on '%@' [%@]", self.compositeName, [self.addressbookRecord uniqueId]);
				return kAddressbookSyncMatchFound;
			} else {
				NSLog(@"Ambigous results found");			
				ABRecord *record;
				for (NSUInteger i = 0; i < [filteredPeople count]; i++) {
					record = [filteredPeople objectAtIndex:i];
					NSLog(@"Match on '%@ %@/%@' [%@]", [record valueForProperty:kABFirstNameProperty], [record valueForProperty:kABLastNameProperty], [record  valueForProperty:kABOrganizationProperty], [record uniqueId]);
				}
				_ambigousPossibleMatches = filteredPeople;
				_addressbookCacheState = kAddressbookCacheLoadAmbigous;
				[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
				return kAddressbookSyncAmbigousResults;
			}
		}
		
		return kAddressbookSyncNotRequired;
	}
}


@end
