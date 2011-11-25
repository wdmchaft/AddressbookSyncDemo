//
//  Contact.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 23/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Contact.h"
#import "UIAlertView+BlockExtensions.h"

@interface ContactMappingCache : NSObject {
@private
    NSDictionary *_mappings;
	BOOL _changed;
}
+ (ContactMappingCache *)sharedInstance;
- (NSString *)identifierForContact:(Contact *)contact;
- (void)setIdentifier:(NSString *)identifier forContact:(Contact *)contact;
- (void)removeIdentifierForContact:(Contact *)contact;
- (BOOL)contactExistsForIdentifier:(NSString *)identifier;
@end

NSString *kContactSyncStateChanged = @"kContactSyncStateChanged";

@implementation ContactMappingCache

+ (ContactMappingCache *)sharedInstance {
	static dispatch_once_t onceToken = 0;
	__strong static id _sharedObject = nil;
	dispatch_once(&onceToken, ^{
		_sharedObject = [[ContactMappingCache alloc] init];
	});
	return _sharedObject;
}

- (id)init {
	if (self = [super init]) {
		NSURL *documentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
		_mappings = [NSDictionary dictionaryWithContentsOfURL:[documentsDirectory URLByAppendingPathComponent:@"contactMapping.plist"]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveRequest:) name:NSManagedObjectContextDidSaveNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveRequest:) name:UIApplicationWillResignActiveNotification object:nil];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)saveRequest:(NSNotification *)notification {
	if (_changed) {
		NSURL *documentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
		if (![_mappings writeToURL:[documentsDirectory URLByAppendingPathComponent:@"contactMapping.plist"] atomically:YES]) {
			NSLog(@"Failed to write contactMapping.plist");
		} else {
			NSLog(@"Contact Mappings saved");
			_changed = NO;
		}
	} else {
		NSLog(@"No contact mappings changes to save");
	}
}

- (NSString *)identifierForContact:(Contact *)contact {
	NSString *key = [[contact.objectID URIRepresentation] absoluteString];
	return [_mappings objectForKey:key];
}

- (void)setIdentifier:(NSString *)identifier forContact:(Contact *)contact {
	NSMutableDictionary *newMappings = [NSMutableDictionary dictionaryWithDictionary:_mappings];
	NSString *key = [[contact.objectID URIRepresentation] absoluteString];
	[newMappings setObject:identifier forKey:key];
	_mappings = [NSDictionary dictionaryWithDictionary:newMappings];
	_changed = YES;
}

- (void)removeIdentifierForContact:(Contact *)contact {
	NSMutableDictionary *newMappings = [NSMutableDictionary dictionaryWithDictionary:_mappings];
	NSString *key = [[contact.objectID URIRepresentation] absoluteString];
	[newMappings removeObjectForKey:key];
	_mappings = [NSDictionary dictionaryWithDictionary:newMappings];
	_changed = YES;
}

- (BOOL)contactExistsForIdentifier:(NSString *)identifier {
	return [[_mappings allValues] containsObject:identifier];
}

@end

@interface Contact (private)
- (void)updateManagedObjectWithAddressbookRecord:(ABRecordRef)record;
@end

@implementation Contact

@synthesize addressbookIdentifier;
@synthesize _addressbookCacheState;
@dynamic lastSync;
@dynamic firstName;
@dynamic lastName;
@dynamic company;
@dynamic isCompany;
@dynamic syncStatus;

+ (Contact *)initContactWithAddressbookRecord:(ABRecordRef)record {
	// Add this contact to the Object Graph
	Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:MANAGED_OBJECT_CONTEXT];
	[contact updateManagedObjectWithAddressbookRecord:record];
	
	return contact;
}

+ (Contact *)findContactForRecordId:(ABRecordID)recordId {
	return nil;
	
	NSString *addressbookIdentifier = [NSString stringWithFormat:@"%d", recordId];	
	// Check if we already have this contact in out object tree
	NSSet *results = [MANAGED_OBJECT_CONTEXT fetchObjectsForEntityName:@"Contact" withPredicate:@"addressbookIdentifier == %@", addressbookIdentifier];
	return [results anyObject];
}

- (void)awakeFromFetch {
	[super awakeFromFetch];
	addressbookIdentifier = [[ContactMappingCache sharedInstance] identifierForContact:self];
	self._addressbookCacheState = (addressbookIdentifier!=nil)?kAddressbookCacheLoaded:kAddressbookCacheNotLoaded;
}

- (void)awakeFromInsert {
	[super awakeFromInsert];
	addressbookIdentifier = [[ContactMappingCache sharedInstance] identifierForContact:self];
	self._addressbookCacheState = (addressbookIdentifier!=nil)?kAddressbookCacheLoaded:kAddressbookCacheNotLoaded;
}

- (void)didSave {
	if ([self isDeleted]) {
		NSLog(@"Removing identifier from Contacts Mapping");
		[[ContactMappingCache sharedInstance] removeIdentifierForContact:self];
	} else if (addressbookIdentifier) {
		NSLog(@"Adding/Updating identifier in Contacts Mapping");
		[[ContactMappingCache sharedInstance] setIdentifier:addressbookIdentifier forContact:self];
	}	
}

- (NSString *)addressbookIdentifier {
	if (addressbookIdentifier == nil) {
		addressbookIdentifier = [[ContactMappingCache sharedInstance] identifierForContact:self];
		self._addressbookCacheState = (addressbookIdentifier!=nil)?kAddressbookCacheLoaded:self._addressbookCacheState;
	}
	
	return addressbookIdentifier;
}

- (void)setAddressbookIdentifier:(NSString *)identifier {
	addressbookIdentifier = identifier;
	_addressbookRecord = nil; // cause it to be reloaded when required
}

- (BOOL)isContactOlderThanAddressbookRecord:(ABRecordRef)record {
	if (self.lastSync == nil) {
		return true;
	}
	CFDateRef modificationDate = ABRecordCopyValue(record, kABPersonModificationDateProperty);
	return ([self.lastSync earlierDate:(__bridge NSDate *)modificationDate] == self.lastSync);
}

- (ABRecordRef)findAddressbookRecord {
	if (!_addressbookRecord) {
		if (self.addressbookIdentifier) {
			_addressbookRecord = ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), (ABRecordID)[self.addressbookIdentifier integerValue]);
			if (_addressbookRecord == nil) { // i.e. we couldn't find the record
				NSLog(@"The value we had for addressbook identifier was incorrect (contact didn't exist)");
				self.addressbookIdentifier = nil;
				[[ContactMappingCache sharedInstance] removeIdentifierForContact:self];
				_addressbookCacheState = kAddressbookCacheNotLoaded;
				[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChanged object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
			}
		}
	}
	
	return _addressbookRecord;
}

- (AddressbookResyncResults)syncAddressbookRecord {
	if (addressbookIdentifier == nil && self._addressbookCacheState == kAddressbookCacheNotLoaded) {
		self._addressbookCacheState = kAddressbookCacheCurrentlyLoading;
		NSLog(@"We need to look up the contact & attempt to sync with Addressbook");
		NSArray *people = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(ABAddressBookCreate());
		
		// Filter out everyone who matches these properties & doesn't currently have a mapping to a existing Contact
		NSArray *filteredPeople = [people filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
			NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonFirstNameProperty);
			NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonLastNameProperty);
			NSString *company = (__bridge_transfer NSString *)ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonOrganizationProperty);
			CFNumberRef personType = ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonKindProperty);
			BOOL isCompany = (personType == kABPersonKindOrganization);
			
			return (((!firstName && !self.firstName)|| [firstName isEqualToString:self.firstName])
					&& ((!lastName && !self.lastName)|| [lastName isEqualToString:self.lastName])
					&& ((!company && !self.company)|| [company isEqualToString:self.company])
					&& isCompany == self.isCompany)
			&& ![[ContactMappingCache sharedInstance] contactExistsForIdentifier:[NSString stringWithFormat:@"%d", ABRecordGetRecordID((__bridge ABRecordRef)evaluatedObject)]];
			
		}]];
		
		NSUInteger count = [filteredPeople count];
		
		if (count == 0) {
			NSLog(@"No match found for contact"); // %@", self.compositeName);
			self._addressbookCacheState = kAddressbookCacheLoadFailed;
			return kAddressbookSyncMatchFailed;
		} else if (count == 1) {
			_addressbookRecord = (__bridge ABRecordRef)[filteredPeople lastObject];
			addressbookIdentifier = [NSString stringWithFormat:@"%d", ABRecordGetRecordID(_addressbookRecord)];
			[[ContactMappingCache sharedInstance] setIdentifier:self.addressbookIdentifier forContact:self];
			NSLog(@"Match on '%@' [%d]", (__bridge_transfer NSString *)ABRecordCopyCompositeName(_addressbookRecord), ABRecordGetRecordID(_addressbookRecord));
			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChanged object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
			return kAddressbookSyncMatchFound;
		} else {
			NSLog(@"Ambigous results found");			
			ABRecordRef record;
			for (NSUInteger i = 0; i < [filteredPeople count]; i++) {
				record = (__bridge ABRecordRef)[filteredPeople objectAtIndex:i];
				NSLog(@"Match on '%@' [%d]", (__bridge_transfer NSString *)ABRecordCopyCompositeName(record), ABRecordGetRecordID(record));
			}
			self._addressbookCacheState = kAddressbookCacheLoadFailed;
			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChanged object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
			return kAddressbookSyncAmbigousResults;
		}
	}
	
	return kAddressbookSyncNotRequired;
}

- (NSString *)compositeName {

	ABRecordRef person = self.findAddressbookRecord;
	if (person != nil) {
		return (__bridge_transfer NSString *)ABRecordCopyCompositeName(person); 
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

- (void)updateManagedObjectWithAddressbookRecord:(ABRecordRef)record {
	CFStringRef firstName = ABRecordCopyValue(record, kABPersonFirstNameProperty);
	CFStringRef lastName = ABRecordCopyValue(record, kABPersonLastNameProperty);
	CFStringRef company = ABRecordCopyValue(record, kABPersonOrganizationProperty);
	CFDateRef modificationDate = ABRecordCopyValue(record, kABPersonModificationDateProperty);
	
	CFNumberRef personType = ABRecordCopyValue(record, kABPersonKindProperty);
	
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
	
	NSString *identifier = [NSString stringWithFormat:@"%d", ABRecordGetRecordID(record)];	
	self.addressbookIdentifier = identifier;
	
}

@end
