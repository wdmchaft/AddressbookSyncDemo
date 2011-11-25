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
@property (nonatomic, assign) ABRecordID addressbookIdentifier;
@property (nonatomic, assign) ABRecordRef addressbookRecord;
- (void)updateManagedObjectWithAddressbookRecordDetails;
@end

@implementation Contact

@synthesize addressbookIdentifier;
@synthesize addressbookRecord;

@dynamic lastSync;
@dynamic firstName;
@dynamic lastName;
@dynamic company;
@dynamic isCompany;
@dynamic syncStatus;

+ (Contact *)initContactWithAddressbookRecord:(ABRecordRef)record {
	// Add this contact to the Object Graph
	Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:MANAGED_OBJECT_CONTEXT];
	contact.addressbookIdentifier = ABRecordGetRecordID(record);
	contact.addressbookRecord = record;
	[contact updateManagedObjectWithAddressbookRecordDetails];
	
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

	NSLog(@"Contach has been initialiased, loading details from cache");
	_addressbookIdentifier = (ABRecordID)[[[ContactMappingCache sharedInstance] identifierForContact:self] integerValue];
	_addressbookCacheState = kAddressbookCacheNotLoaded;
	if (_addressbookIdentifier != 0) {
		_addressbookRecord = ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), _addressbookIdentifier);
		if (_addressbookRecord == nil) { // i.e. we couldn't find the record
			NSLog(@"The value we had for addressbook identifier was incorrect (contact didn't exist)");
			_addressbookIdentifier = 0;
			[[ContactMappingCache sharedInstance] removeIdentifierForContact:self];
			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChanged object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
		} else {
			if ([self isContactOlderThanAddressbookRecord:_addressbookRecord]) {
				NSLog(@"Addressbook contact is newer, we need to update our cache");
				[self updateManagedObjectWithAddressbookRecordDetails];
			}
			_addressbookCacheState = kAddressbookCacheLoaded;
		}
	} else {
		NSLog(@"Contact has no identifier in the mapping yet");
	}
}

- (void)awakeFromInsert {
	[super awakeFromInsert];
	_addressbookCacheState = kAddressbookCacheNotLoaded;
}

- (void)didSave {
	if ([self isDeleted]) {
		NSLog(@"Removing identifier from Contacts Mapping");
		[[ContactMappingCache sharedInstance] removeIdentifierForContact:self];
	} else if (_addressbookIdentifier) {
		NSLog(@"Adding/Updating identifier in Contacts Mapping");
		[[ContactMappingCache sharedInstance] setIdentifier:[NSString stringWithFormat:@"%d", _addressbookIdentifier] forContact:self];
	}	
}

- (ABRecordID)addressbookIdentifier {
	return _addressbookIdentifier;
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
		if (_addressbookIdentifier) {
			_addressbookRecord = ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), _addressbookIdentifier);
			if (_addressbookRecord == nil) { // i.e. we couldn't find the record
				NSLog(@"The value we had for addressbook identifier was incorrect (contact didn't exist)");
				_addressbookIdentifier = 0;
				[[ContactMappingCache sharedInstance] removeIdentifierForContact:self];
				_addressbookCacheState = kAddressbookCacheNotLoaded;
				[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChanged object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
			}
		}
	}
	
	return _addressbookRecord;
}

- (AddressbookResyncResults)syncAddressbookRecord {
	if (_addressbookIdentifier && _addressbookCacheState == kAddressbookCacheNotLoaded) {
		_addressbookCacheState = kAddressbookCacheCurrentlyLoading;
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
			_addressbookCacheState = kAddressbookCacheLoadFailed;
			return kAddressbookSyncMatchFailed;
		} else if (count == 1) {
			_addressbookIdentifier = ABRecordGetRecordID(_addressbookRecord);
			_addressbookRecord = (__bridge ABRecordRef)[filteredPeople lastObject];
			[[ContactMappingCache sharedInstance] setIdentifier:[NSString stringWithFormat:@"%d", _addressbookIdentifier] forContact:self];
			[self updateManagedObjectWithAddressbookRecordDetails];
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
			_addressbookCacheState = kAddressbookCacheLoadFailed;
			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChanged object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
			return kAddressbookSyncAmbigousResults;
		}
	}
	
	return kAddressbookSyncNotRequired;
}

- (NSString *)compositeName {
	if (_addressbookRecord != nil) {
		return (__bridge_transfer NSString *)ABRecordCopyCompositeName(_addressbookRecord); 
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

- (void)updateManagedObjectWithAddressbookRecordDetails {
	
	if (_addressbookRecord == 0) {
		NSLog(@"Can't update record, object's _addressbookRecord is nil");
		return;
	}
	
	CFStringRef firstName = ABRecordCopyValue(_addressbookRecord, kABPersonFirstNameProperty);
	CFStringRef lastName = ABRecordCopyValue(_addressbookRecord, kABPersonLastNameProperty);
	CFStringRef company = ABRecordCopyValue(_addressbookRecord, kABPersonOrganizationProperty);
	CFDateRef modificationDate = ABRecordCopyValue(_addressbookRecord, kABPersonModificationDateProperty);
	
	CFNumberRef personType = ABRecordCopyValue(_addressbookRecord, kABPersonKindProperty);
	
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
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChanged object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
}

@end
