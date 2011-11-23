//
//  Contact.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 23/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Contact.h"

@interface ContactMappingCache : NSObject {
@private
    NSDictionary *_mappings;
}
+ (ContactMappingCache *)sharedInstance;
- (NSString *)identifierForContact:(Contact *)contact;
- (void)setIdentifier:(NSString *)identifier forContact:(Contact *)contact;
@end

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
	}
	return self;
}

- (NSString *)identifierForContact:(Contact *)contact {
	return [_mappings objectForKey:[NSNumber numberWithInteger:[[contact.objectID URIRepresentation] hash]]];
}

- (void)setIdentifier:(NSString *)identifier forContact:(Contact *)contact {
	NSMutableDictionary *newMappings = [NSMutableDictionary dictionaryWithDictionary:_mappings];
	[newMappings setObject:identifier forKey:[NSNumber numberWithInteger:[[contact.objectID URIRepresentation] hash]]];
	NSURL *documentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	if (![newMappings writeToURL:[documentsDirectory URLByAppendingPathComponent:@"contactMapping.plist"] atomically:YES]) {
		NSLog(@"Failed to write contactMapping.plist");
	}
	_mappings = [NSDictionary dictionaryWithDictionary:newMappings];
}

@end

@implementation Contact

@synthesize addressbookIdentifier;
@dynamic lastSync;
@dynamic firstName;
@dynamic lastName;
@dynamic company;
@dynamic isCompany;
@dynamic syncStatus;

@interface Contact (private)
- (void)updateManagedObjectWithAddressbookRecord:(ABRecordRef)record;
@end

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

- (NSString *)addressbookIdentifier {
	if (addressbookIdentifier == nil) {
		addressbookIdentifier = [[ContactMappingCache sharedInstance] identifierForContact:self];
	}
	
	return addressbookIdentifier;
}

- (void)setAddressbookIdentifier:(NSString *)identifier {
	addressbookIdentifier = identifier;
	[[ContactMappingCache sharedInstance] setIdentifier:identifier forContact:self];
}

- (BOOL)isContactOlderThanAddressbookRecord:(ABRecordRef)record {
	if (self.lastSync == nil) {
		return true;
	}
	CFDateRef modificationDate = ABRecordCopyValue(record, kABPersonModificationDateProperty);
	return ([self.lastSync earlierDate:(__bridge NSDate *)modificationDate] == self.lastSync);
}

- (ABRecordRef)findAddressbookRecord {
	return ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), (ABRecordID)[self.addressbookIdentifier integerValue]);
}

- (NSString *)compositeName {
	if (self.isCompany) {
		return self.company;
	} else {
		return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
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
