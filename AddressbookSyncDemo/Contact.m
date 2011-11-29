//
//  Contact.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 23/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Contact.h"
#import "UIAlertView+BlockExtensions.h"
#import "PhoneNumber.h"

@implementation Contact


+ (Contact *)initContactWithAddressbookRecord:(ABRecordRef)record {
	// Add this contact to the Object Graph
	Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:MANAGED_OBJECT_CONTEXT];
	contact.addressbookIdentifier = ABRecordGetRecordID(record);
	[contact updateManagedObjectWithAddressbookRecordDetails];
	
	return contact;
}

- (BOOL)isContactOlderThanAddressbookRecord:(ABRecordRef)record {
	if (self.lastSync == nil) {
		return true;
	}
	CFDateRef modificationDate = ABRecordCopyValue(record, kABPersonModificationDateProperty);
	return ([self.lastSync earlierDate:(__bridge NSDate *)modificationDate] == self.lastSync);
}

- (ABRecordRef)findAddressbookRecord {
	ABRecordRef record;
	if (self.addressbookIdentifier) {
		record = ABAddressBookGetPersonWithRecordID([Contact sharedAddressbook], self.addressbookIdentifier);
		if (record == nil) { // i.e. we couldn't find the record
			NSLog(@"The value we had for addressbook identifier was incorrect (contact didn't exist)");
			self.addressbookIdentifier = 0;
			[[ContactMappingCache sharedInstance] removeIdentifierForContact:self];
			_addressbookCacheState = kAddressbookCacheNotLoaded;
			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
		}
	}
	
	return record;
}

- (AddressbookResyncResults)syncAddressbookRecord {
	@synchronized(self) {
		if (!self.addressbookIdentifier && _addressbookCacheState == kAddressbookCacheNotLoaded) {
			ABAddressBookRef addressbook = ABAddressBookCreate();
			_addressbookCacheState = kAddressbookCacheCurrentlyLoading;
			NSLog(@"We need to look up the contact & attempt to sync with Addressbook");
			NSArray *people = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(addressbook);
			
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

			// Filter out everyone who matches these properties & doesn't currently have a mapping to a existing Contact
			NSArray *filteredPeople = [people filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
				NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonFirstNameProperty);
				NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonLastNameProperty);
				NSString *company = (__bridge_transfer NSString *)ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonOrganizationProperty);
				CFNumberRef personType = ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonKindProperty);
				BOOL isCompany = (personType == kABPersonKindOrganization);
				
				return (((!firstName && !searchFirstName)|| [firstName isEqualToString:searchFirstName])
						&& ((!lastName && !searchLastName)|| [lastName isEqualToString:searchLastName])
						&& ((!company && !searchCompany)|| [company isEqualToString:searchCompany])
						&& isCompany == searchIsCompany)
				&& ![[ContactMappingCache sharedInstance] contactExistsForIdentifier:[NSString stringWithFormat:@"%d", ABRecordGetRecordID((__bridge ABRecordRef)evaluatedObject)]];
				
			}]];
			
			NSUInteger count = [filteredPeople count];
			
			if (count == 0) {
				NSLog(@"No match found for '%@'", self.compositeName);
				_addressbookCacheState = kAddressbookCacheLoadFailed;
				return kAddressbookSyncMatchFailed;
			} else if (count == 1) {
				self.addressbookIdentifier = ABRecordGetRecordID((__bridge ABRecordRef)[filteredPeople lastObject]);
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
				NSLog(@"Match on '%@' [%d]", (__bridge_transfer NSString *)ABRecordCopyCompositeName(self.addressbookRecord), ABRecordGetRecordID(self.addressbookRecord));
				return kAddressbookSyncMatchFound;
			} else {
				NSLog(@"Ambigous results found");			
				ABRecordRef record;
				for (NSUInteger i = 0; i < [filteredPeople count]; i++) {
					record = (__bridge ABRecordRef)[filteredPeople objectAtIndex:i];
					NSLog(@"Match on '%@' [%d]", (__bridge_transfer NSString *)ABRecordCopyCompositeName(record), ABRecordGetRecordID(record));
				}
				_ambigousPossibleMatches = filteredPeople;
				_addressbookCacheState = kAddressbookCacheLoadAmbigous;
				[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
				return kAddressbookSyncAmbigousResults;
			}
			CFRelease(addressbook);
		}
		
		return kAddressbookSyncNotRequired;
	}
}

- (void)resolveConflictWithAddressbookRecord:(ABRecordRef)record {
	self.addressbookIdentifier = ABRecordGetRecordID(self.addressbookRecord);
	[self updateManagedObjectWithAddressbookRecordDetails];
	NSLog(@"Conflict for '%@' is now resolved", self.compositeName);
}

- (NSString *)compositeName {
	if (self.addressbookRecord != nil) {
		return (__bridge_transfer NSString *)ABRecordCopyCompositeName(self.addressbookRecord); 
	} else {
		if (self.isCompany) {
			return self.company;
		} else {
			NSString *firstName = (self.firstName?self.firstName:@"");
			NSString *lastName = (self.lastName?self.lastName:@"");
			if (ABPersonGetCompositeNameFormat() == kABPersonCompositeNameFormatFirstNameFirst) {
				return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
			} else {
				return [NSString stringWithFormat:@"%@ %@", lastName, firstName];
			}
		}
	}
}

- (NSString *)secondaryCompositeName {
	if (!self.isCompany) {
		return self.company;
	} else {
		NSString *firstName = (self.firstName?self.firstName:@"");
		NSString *lastName = (self.lastName?self.lastName:@"");
		if (ABPersonGetCompositeNameFormat() == kABPersonCompositeNameFormatFirstNameFirst) {
			return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
		} else {
			return [NSString stringWithFormat:@"%@ %@", lastName, firstName];
		}
	}
}


- (void)updateManagedObjectWithAddressbookRecordDetails {
	
	ABRecordRef record;
	if ((record = self.addressbookRecord) == NULL) {
		NSLog(@"Can't update record, addressbook record not found");
		return;
	}

	CFStringRef firstName = ABRecordCopyValue(self.addressbookRecord, kABPersonFirstNameProperty);
	CFStringRef lastName = ABRecordCopyValue(self.addressbookRecord, kABPersonLastNameProperty);
	CFStringRef company = ABRecordCopyValue(self.addressbookRecord, kABPersonOrganizationProperty);
	CFDateRef modificationDate = ABRecordCopyValue(self.addressbookRecord, kABPersonModificationDateProperty);
	
	CFNumberRef personType = ABRecordCopyValue(self.addressbookRecord, kABPersonKindProperty);
	
	self.isCompany = (personType == kABPersonKindOrganization);
	CFRelease(personType);
	
	if (firstName) {
		self.firstName = (__bridge NSString *)firstName;
		CFRelease(firstName);
	}
	if (lastName) {
		self.lastName = (__bridge NSString *)lastName;
		CFRelease(lastName);
	}
	if (company) {
		self.company = (__bridge NSString *)company;
		CFRelease(company);
	}
	
	if (modificationDate) {
		self.lastSync = (__bridge NSDate *)modificationDate;
	} else {
		NSLog(@"Contact has no last modification date");
	}
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
}

- (NSArray *)phoneNumbers {
	ABRecordRef record = self.addressbookRecord;
	NSArray *result;
	if (record) {
		ABMultiValueRef properties = ABRecordCopyValue(record, kABPersonPhoneProperty);
		CFIndex max = ABMultiValueGetCount(properties);
		if (max != 0) {
			NSMutableArray *values = [NSMutableArray arrayWithArray:_phoneNumbers];
			for (CFIndex i = 0; i < max; i++) {
				NSLog(@"%ld", i);
				PhoneNumber *phoneNumber = [[PhoneNumber alloc] init];
				phoneNumber.identifier = ABMultiValueGetIdentifierAtIndex(properties, i);
				phoneNumber.properties = properties;
				[values addObject:phoneNumber];
			}
			result = values;
		}
	}
	return _phoneNumbers;
}

- (NSArray *)emailAddresses {
	return _emailAddresses;
}

- (NSArray *)addresses {
	return _addresses;
}

- (NSArray *)websites {
	return _websites;
}


@end
