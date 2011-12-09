//
//  Contact.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 28/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
//#define MULTI_THREADED 1

#import "Contact.h"
#import "PhoneNumber.h"
#import "EmailAddress.h"
#import "Website.h"
#import "Address.h"

#define MULTI_THREADED 1

NSString *kContactSyncStateChangedNotification = @"kContactSyncStateChanged";

@implementation Contact

@dynamic lastSync;
@dynamic firstName;
@dynamic lastName;
@dynamic company;
@dynamic isCompany;
@dynamic sortTag1;
@dynamic sortTag2;

// These must be declared in the subclass
@dynamic compositeName;
@dynamic secondaryCompositeName;

@synthesize addressbookIdentifier;
@synthesize _addressbookCacheState;

+ (NSOperationQueue *)sharedOperationQueue {
	static dispatch_once_t onceToken = 0;
	__strong static NSOperationQueue *_operationQueue = nil;
	dispatch_once(&onceToken, ^{
		_operationQueue = [[NSOperationQueue alloc] init];
	});
	return _operationQueue;
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	if ([key isEqualToString:@"compositeName"]) {
		return [NSSet setWithObjects:@"firstName", @"lastName", @"company", @"addressbookIdentifier", nil];
	} else if ([key isEqualToString:@"secondaryCompositeName"]) {
		return [NSSet setWithObjects:@"firstName", @"lastName", @"company", @"addressbookIdentifier", nil];
	} else if ([key isEqualToString:@"helpfullText"]) {
		return [NSSet setWithObjects:@"addressbookIdentifier", @"addressbookCacheState", @"_addressbookCacheState", @"sortTag1", @"sortTag2", nil];
	}
	
	return nil;
}

+ (Contact *)findContactForRecordId:(TFRecordID)recordId {
	return (Contact *)[[ContactMappingCache sharedInstance] contactObjectForIdentifier:recordId];
}

+ (Contact *)initContactWithAddressbookRecord:(TFRecord *)record {
	// Add this contact to the Object Graph
	Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:MANAGED_OBJECT_CONTEXT];
	contact.addressbookIdentifier = [record uniqueId];
	[contact updateManagedObjectWithAddressbookRecordDetails];
	
	return contact;
}

- (void)awakeFromFetch {
	[super awakeFromFetch];
	
	NSLog(@"Contact '%@' has been initialiased, loading details from cache", self.compositeName);
	self._addressbookCacheState = kAddressbookCacheNotLoaded;
	if (self.addressbookIdentifier != 0) {
		TFRecord *record = [self addressbookRecordInAddressBook:[TFAddressBook addressBook]];
		if (record == nil) { // i.e. we couldn't find the record
			NSLog(@"The value we had for addressbook identifier was incorrect ('%@' didn't exist)", self.compositeName);
			self.addressbookIdentifier = 0;
			[[ContactMappingCache sharedInstance] removeIdentifierForContact:self];
			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
			[self syncAddressbookRecord];
		} else {
			if ([self isContactOlderThanAddressbookRecord:record]) {
				NSLog(@"Addressbook contact is newer, we need to update our cache");
				[self updateManagedObjectWithAddressbookRecordDetails];
			}
			self._addressbookCacheState = kAddressbookCacheLoaded;
			NSLog(@"Contact '%@' loaded", self.compositeName);
		}
	} else {
		NSLog(@"Contact '%@' has no identifier in the mapping yet", self.compositeName);
#ifdef MULTI_THREADED
		[[Contact sharedOperationQueue] addOperationWithBlock:^{
			[self syncAddressbookRecord];
		}];
#else
		[self syncAddressbookRecord];
#endif
	}
}

- (void)awakeFromInsert {
	[super awakeFromInsert];
	self._addressbookCacheState = kAddressbookCacheNotLoaded;
}

- (void)didSave {
	if ([self isDeleted]) {
		NSLog(@"Removing identifier from Contacts Mapping");
		[[ContactMappingCache sharedInstance] removeIdentifierForContact:self];
	} else if (self.addressbookIdentifier) {
		NSLog(@"Adding/Updating identifier in Contacts Mapping");
		[[ContactMappingCache sharedInstance] setIdentifier:self.addressbookIdentifier forContact:self];
	}	
}

- (BOOL)isContactOlderThanAddressbookRecord:(TFRecord *)record {
	if (self.lastSync == nil) {
		return true;
	}
	NSDate *modificationDate = [record valueForProperty:kTFModificationDateProperty];
	return ([self.lastSync laterDate:modificationDate] == modificationDate);
}

- (TFRecordID)addressbookIdentifier {
	if (addressbookIdentifier == 0) {
		addressbookIdentifier = [[ContactMappingCache sharedInstance] identifierForContact:self];
	}
	return addressbookIdentifier;
}


- (TFRecord *)addressbookRecordInAddressBook:(TFAddressBook *)addressBook {
	if (self.addressbookIdentifier != 0) {
		return [addressBook recordForUniqueId:self.addressbookIdentifier];
	}
	return nil;
}

- (void)updateManagedObjectWithAddressbookRecordDetails {

	TFPerson *record = (TFPerson *)[self addressbookRecordInAddressBook:[TFAddressBook addressBook]];
	
	if (record == nil) {
		NSLog(@"Can't update record, object's _addressbookRecord is nil");
		NSLog(@"The value we had for addressbook identifier was incorrect ('%@' didn't exist)", self.compositeName);
		self.addressbookIdentifier = 0;
		[[ContactMappingCache sharedInstance] removeIdentifierForContact:self];
		_addressbookCacheState = kAddressbookCacheNotLoaded;
		[self syncAddressbookRecord];
	} else {
		NSInteger personFlags = [[record valueForProperty:kTFPersonFlags] integerValue];
		self.isCompany = (personFlags & kTFShowAsCompany);
		
		self.firstName = [record valueForProperty:kTFFirstNameProperty];
		self.lastName = [record valueForProperty:kTFLastNameProperty];
		self.company = [record valueForProperty:kTFOrganizationProperty];
		
		NSDate *modificationDate = [record valueForProperty:kTFModificationDateProperty];
		if (modificationDate) {
			self.lastSync = modificationDate;
		} else {
			NSLog(@"Contact has no last modification date");
		}
		
		[self willChangeValueForKey:@"_addresses"];
		[self willChangeValueForKey:@"_phoneNumbers"];
		[self willChangeValueForKey:@"_emailAddresses"];
		[self willChangeValueForKey:@"_websites"];
		_addresses = nil;
		_phoneNumbers = nil;
		_emailAddresses = nil;
		_websites = nil;
		[self didChangeValueForKey:@"_addresses"];
		[self didChangeValueForKey:@"_phoneNumbers"];
		[self didChangeValueForKey:@"_emailAddresses"];
		[self didChangeValueForKey:@"_websites"];
	}
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
}

- (NSArray *)ambigousContactMatches {
	return _ambigousPossibleMatches;	
}

- (void)resolveConflictWithAddressbookRecordId:(TFRecordID)recordId {
	self.addressbookIdentifier = recordId;
	[self updateManagedObjectWithAddressbookRecordDetails];
	NSLog(@"Conflict for '%@' is now resolved", self.compositeName);
}

- (AddressbookResyncResults)syncAddressbookRecord {
	@synchronized(self) {
		if (!self.addressbookIdentifier && _addressbookCacheState == kAddressbookCacheNotLoaded) {
			TFAddressBook *addressbook = [TFAddressBook addressBook];
			self._addressbookCacheState = kAddressbookCacheCurrentlyLoading;

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
			
			
			TFSearchElement *firstNameSearchElement = [TFPerson searchElementForProperty:kTFFirstNameProperty label:nil key:nil value:searchFirstName comparison:kTFEqualCaseInsensitive];
			TFSearchElement *lastNameSearchElement = [TFPerson searchElementForProperty:kTFLastNameProperty label:nil key:nil value:searchLastName comparison:kTFEqualCaseInsensitive];
			TFSearchElement *companySearchElement = [TFPerson searchElementForProperty:kTFOrganizationProperty label:nil key:nil value:searchCompany comparison:kTFEqualCaseInsensitive];
			
			TFSearchElement *compositeSearchElement = [TFSearchElement searchElementForConjunction:kTFSearchAnd children:[NSArray arrayWithObjects:firstNameSearchElement, lastNameSearchElement, companySearchElement, nil]];
			
			NSArray *people = [addressbook recordsMatchingSearchElement:compositeSearchElement];
			
			// Filter out everyone who matches these properties & doesn't currently have a mapping to a existing Contact
			NSArray *filteredPeople = [people filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
				NSInteger personFlags = [[(TFPerson *)evaluatedObject valueForProperty:kTFPersonFlags] integerValue];
				return (self.isCompany == (personFlags & kTFShowAsCompany));
			}]];
			
			NSUInteger count = [filteredPeople count];
			
			if (count == 0) {
				NSLog(@"No match found for '%@'", self.compositeName);
				self._addressbookCacheState = kAddressbookCacheLoadFailed;
				return kAddressbookSyncMatchFailed;
			} else if (count == 1) {
				self.addressbookIdentifier = [[filteredPeople lastObject] uniqueId];
				[[ContactMappingCache sharedInstance] setIdentifier:self.addressbookIdentifier forContact:self];
				// we need to update our managed object back on the main thread
				if ([NSOperationQueue mainQueue] != [NSOperationQueue currentQueue]) {
					[[NSOperationQueue mainQueue] addOperationWithBlock:^{
						[self updateManagedObjectWithAddressbookRecordDetails];
					}];
					[[NSOperationQueue mainQueue] waitUntilAllOperationsAreFinished];
				} else {
					[self updateManagedObjectWithAddressbookRecordDetails];
				}
				NSLog(@"Match on '%@' [%@]", self.compositeName, [[self addressbookRecordInAddressBook:addressbook] uniqueId]);
				return kAddressbookSyncMatchFound;
			} else {
				NSLog(@"Ambigous results found");			
				TFRecord *record;
				for (NSUInteger i = 0; i < [filteredPeople count]; i++) {
					record = [filteredPeople objectAtIndex:i];
					NSLog(@"Match on '%@ %@/%@' [%@]", [record valueForProperty:kTFFirstNameProperty], [record valueForProperty:kTFLastNameProperty], [record  valueForProperty:kTFOrganizationProperty], [record uniqueId]);
				}
				_ambigousPossibleMatches = [filteredPeople valueForKeyPath:@"uniqueId"];
				self._addressbookCacheState = kAddressbookCacheLoadAmbigous;
				[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
				return kAddressbookSyncAmbigousResults;
			}
		}
		
		return kAddressbookSyncNotRequired;
	}
}

- (NSString *)compositeName {
	if (self.isCompany) {
		return self.company;
	} else {
		NSString *firstName = (self.firstName?self.firstName:@"");
		NSString *lastName = (self.lastName?self.lastName:@"");
		if ([[TFAddressBook addressBook] defaultNameOrdering] == kTFFirstNameFirst) {
			return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
		} else {
			return [NSString stringWithFormat:@"%@ %@", lastName, firstName];
		}
	}
}

- (NSString *)helpfullText {
	return self.addressbookIdentifier?[NSString stringWithFormat:@"%@ ['%@', '%@'] - '%@'", self.addressbookIdentifier, self.sortTag1, self.sortTag2, self.groupingIndexCharacter]:@"Contact not found";
}


- (NSString *)secondaryCompositeName {
	if (!self.isCompany) {
		return self.company;
	} else {
		NSString *firstName = (self.firstName?self.firstName:@"");
		NSString *lastName = (self.lastName?self.lastName:@"");
		if ([[TFAddressBook addressBook] defaultNameOrdering] == kTFFirstNameFirst) {
			return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
		} else {
			return [NSString stringWithFormat:@"%@ %@", lastName, firstName];
		}
	}
}

- (NSString *)groupingIndexCharacter {
	NSString *result = nil;
	if (self.isCompany) {
		if (self.company) {
			result = self.company;
		} else if (self.lastName) {
			result = self.lastName;
		} else if (self.firstName) {
			result = self.firstName;
		} else {
			result = @"N";
		}
	} else {
		if (self.lastName) {
			result = self.lastName;
		} else if (self.firstName) {
			result = self.firstName;
		} else if (self.company) {
			result = self.company;
		} else {
			result = @"N";
		}
	}
	
	return [[result substringWithRange:NSMakeRange([result rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location, 1)] uppercaseString];
}

- (void)resetSearchTags {
	NSRange range = [self.company rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
	NSString *c = [[self.company substringWithRange:NSMakeRange(range.location, [self.company length]-range.location)] uppercaseString];
	range = [self.firstName rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
	NSString *f = [[self.firstName substringWithRange:NSMakeRange(range.location, [self.firstName length]-range.location)] uppercaseString];
	range = [self.lastName rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
	NSString *l = [[self.lastName substringWithRange:NSMakeRange(range.location, [self.lastName length]-range.location)] uppercaseString];
	if (self.isCompany) {
		if (c) {
			self.sortTag1 = c;
			self.sortTag2 = c;
		} else if (f) {
			self.sortTag1 = f;
			if (l) {
				self.sortTag2 = l;
			} else {
				self.sortTag2 = f;
			}
		} else if (l) {
			self.sortTag1 = l;
			self.sortTag2 = l;
		}
	} else {
		if (f) {
			self.sortTag1 = f;
			if (l) {
				self.sortTag2 = l;
			} else {
				self.sortTag2 = f;
			}
		} else if (l) {
			self.sortTag1 = l;
			self.sortTag2 = l;
		} else if (c) {
			self.sortTag1 = c;
			self.sortTag2 = c;
		}
	}
}

- (void)setFirstName:(NSString *)firstName {
	[self willChangeValueForKey:@"firstName"];
	[self setPrimitiveValue:firstName forKey:@"firstName"];
	[self didChangeValueForKey:@"firstName"];
	[self resetSearchTags];
}

- (void)setLastName:(NSString *)lastName {
	[self willChangeValueForKey:@"lastName"];
	[self setPrimitiveValue:lastName forKey:@"lastName"];
	[self didChangeValueForKey:@"lastName"];
	[self resetSearchTags];
}

- (void)setCompany:(NSString *)company {
	[self willChangeValueForKey:@"company"];
	[self setPrimitiveValue:company forKey:@"company"];
	[self didChangeValueForKey:@"company"];	
	[self resetSearchTags];
}

- (NSArray *)phoneNumbers {
	if (_phoneNumbers == nil) {
		TFRecord *record = [self addressbookRecordInAddressBook:[TFAddressBook addressBook]];
		if (record) {
			TFMultiValue *properties = [record valueForProperty:kTFPhoneProperty];
			NSMutableArray *values = [NSMutableArray array];
			for (NSUInteger i = 0; i < [properties count]; i++) {
				TFMultiValueIdentifier identifier = [properties identifierAtIndex:i];
				NSUInteger index = NSNotFound;
				if (_phoneNumbers) {
					index = [_phoneNumbers indexOfObjectPassingTest:^BOOL(PhoneNumber *obj, NSUInteger idx, BOOL *stop) {
						return obj.identifier == identifier;
					}];
				}
				
				PhoneNumber *phoneNumber;
				if (index == NSNotFound) {
					NSLog(@"creating new");
					phoneNumber = [[PhoneNumber alloc] init];
				} else {
					NSLog(@"reusing & updating");
					phoneNumber = [_phoneNumbers objectAtIndex:index];
				}
				[values addObject:phoneNumber];
				[phoneNumber populateWithProperties:properties reference:identifier];
			}
			_phoneNumbers = values;
		}
	}
	return _phoneNumbers;
}

- (NSArray *)emailAddresses {
	if (_emailAddresses == nil) {
		TFRecord *record = [self addressbookRecordInAddressBook:[TFAddressBook addressBook]];
		if (record) {
			TFMultiValue *properties = [record valueForProperty:kTFEmailProperty];
			NSMutableArray *values = [NSMutableArray array];
			for (NSUInteger i = 0; i < [properties count]; i++) {
				TFMultiValueIdentifier identifier = [properties identifierAtIndex:i];
				NSUInteger index = NSNotFound;
				if (_emailAddresses) {
					index = [_emailAddresses indexOfObjectPassingTest:^BOOL(PhoneNumber *obj, NSUInteger idx, BOOL *stop) {
						return obj.identifier == identifier;
					}];
				}
				
				EmailAddress *emailAddress;
				if (index == NSNotFound) {
					NSLog(@"creating new");
					emailAddress = [[EmailAddress alloc] init];
				} else {
					NSLog(@"reusing & updating");
					emailAddress = [_emailAddresses objectAtIndex:index];
				}
				[values addObject:emailAddress];
				[emailAddress populateWithProperties:properties reference:identifier];
			}
			_emailAddresses = values;
		}
	}
	return _emailAddresses;
}

- (NSArray *)addresses {
	if (_addresses == nil) {
		TFRecord *record = [self addressbookRecordInAddressBook:[TFAddressBook addressBook]];
		if (record) {
			TFMultiValue *properties = [record valueForProperty:kTFAddressProperty];
			NSMutableArray *values = [NSMutableArray array];
			for (NSUInteger i = 0; i < [properties count]; i++) {
				TFMultiValueIdentifier identifier = [properties identifierAtIndex:i];
				NSUInteger index = NSNotFound;
				if (_addresses) {
					index = [_addresses indexOfObjectPassingTest:^BOOL(Address *obj, NSUInteger idx, BOOL *stop) {
						return obj.identifier == identifier;
					}];
				}
				
				Address *address;
				if (index == NSNotFound) {
					NSLog(@"creating new");
					address = [[Address alloc] init];
				} else {
					NSLog(@"reusing & updating");
					address = [_addresses objectAtIndex:index];
				}
				[values addObject:address];
				[address populateWithProperties:properties reference:identifier];
			}
			_addresses = values;
		}
	}
	return _addresses;
}

- (NSArray *)websites {
	if (_websites == nil) {	
		TFRecord *record = [self addressbookRecordInAddressBook:[TFAddressBook addressBook]];
		if (record) {
			TFMultiValue *properties = [record valueForProperty:kTFURLsProperty];
			NSMutableArray *values = [NSMutableArray array];
			for (NSUInteger i = 0; i < [properties count]; i++) {
				TFMultiValueIdentifier identifier = [properties identifierAtIndex:i];
				NSUInteger index = NSNotFound;
				if (_websites) {
					index = [_websites indexOfObjectPassingTest:^BOOL(Website *obj, NSUInteger idx, BOOL *stop) {
						return obj.identifier == identifier;
					}];
				}				
				Website *website;
				if (index == NSNotFound) {
					NSLog(@"creating new");
					website = [[Website alloc] init];
				} else {
					NSLog(@"reusing & updating");
					website = [_websites objectAtIndex:index];
				}
				[values addObject:website];
				[website populateWithProperties:properties reference:identifier];
			}
			_websites = values;
		}
	}
	return _websites;
}

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
		@synchronized(self) {
			NSURL *documentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
			_mappings = [NSDictionary dictionaryWithContentsOfURL:[documentsDirectory URLByAppendingPathComponent:@"contactMapping.plist"]];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveRequest:) name:NSManagedObjectContextDidSaveNotification object:nil];
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveRequest:) name:UIApplicationWillResignActiveNotification object:nil];
#endif
		}
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
#endif
}

- (void)saveRequest:(NSNotification *)notification {
	@synchronized(self) {
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
}

- (TFRecordID)identifierForContact:(Contact *)contact {
	@synchronized(self) {
		NSString *key = [[contact.objectID URIRepresentation] absoluteString];
		return [_mappings objectForKey:key];
	}
}

- (void)setIdentifier:(TFRecordID)identifier forContact:(Contact *)contact {
	NSString *key = [[contact.objectID URIRepresentation] absoluteString];
	@synchronized(self) {
		NSMutableDictionary *newMappings = [NSMutableDictionary dictionaryWithDictionary:_mappings];
		[newMappings setObject:identifier forKey:key];
		_mappings = [NSDictionary dictionaryWithDictionary:newMappings];
	}
	_changed = YES;
}

- (void)removeIdentifierForContact:(Contact *)contact {
	NSString *key = [[contact.objectID URIRepresentation] absoluteString];
	@synchronized(self) {
		NSMutableDictionary *newMappings = [NSMutableDictionary dictionaryWithDictionary:_mappings];
		[newMappings removeObjectForKey:key];
		_mappings = [NSDictionary dictionaryWithDictionary:newMappings];
	}
	_changed = YES;
}

- (BOOL)contactExistsForIdentifier:(TFRecordID)identifier {
	@synchronized(self) {
		NSString *search = nil;
		search = identifier;
		return [[_mappings allValues] containsObject:search];
	}
}

- (Contact *)contactObjectForIdentifier:(TFRecordID)uniqueID {
	if ([self contactExistsForIdentifier:uniqueID]) {
		@synchronized(self) {
			NSString *identifier = nil;
			identifier = uniqueID;
			for (NSString *urlAsString in [_mappings allKeys]) {
				if ([[_mappings valueForKey:urlAsString] isEqualToString:identifier]) {
					NSError *error = nil;
					NSURL *objectURL = [NSURL URLWithString:urlAsString];
					if (objectURL) {
						NSManagedObjectID *objectId = [[MANAGED_OBJECT_CONTEXT persistentStoreCoordinator] managedObjectIDForURIRepresentation:objectURL];
						if (objectId) {
							Contact *contact = (Contact *)[MANAGED_OBJECT_CONTEXT existingObjectWithID:objectId error:&error];
							if (error) {
								NSLog(@"Error retreiving object: %@", [error localizedDescription]);
							}
							return contact;
						}
					}
				}
			}
		}
	}
	return nil;
}

@end