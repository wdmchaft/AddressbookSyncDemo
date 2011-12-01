//
//  _Contact.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 28/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "_Contact.h"

NSString *kContactSyncStateChangedNotification = @"kContactSyncStateChanged";

@implementation _Contact

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
@synthesize addressbookRecord;

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	if ([key isEqualToString:@"compositeName"]) {
		return [NSSet setWithObjects:@"firstName", @"lastName", @"comapny", nil];
	} else if ([key isEqualToString:@"secondaryCompositeName"]) {
		return [NSSet setWithObjects:@"firstName", @"lastName", @"comapny", nil];
	}
	
	return nil;
}

+ (Contact *)findContactForRecordId:(TFRecordID)recordId {
	NSString *addressbookIdentifier = [NSString stringWithFormat:@"%d", recordId];
	return (Contact *)[[ContactMappingCache sharedInstance] contactObjectForIdentifier:addressbookIdentifier];
}

- (void)awakeFromFetch {
	[super awakeFromFetch];
	
	NSLog(@"Contact '%@' has been initialiased, loading details from cache", self.compositeName);
	_addressbookCacheState = kAddressbookCacheNotLoaded;
	if (self.addressbookIdentifier != 0) {
		if (self.addressbookRecord == nil) { // i.e. we couldn't find the record
			NSLog(@"The value we had for addressbook identifier was incorrect ('%@' didn't exist)", self.compositeName);
			self.addressbookIdentifier = 0;
			[[ContactMappingCache sharedInstance] removeIdentifierForContact:self];
			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
			[(NSObject<Contact> *)self syncAddressbookRecord];
		} else {
			if ([(NSObject<Contact> *)self isContactOlderThanAddressbookRecord:self.addressbookRecord]) {
				NSLog(@"Addressbook contact is newer, we need to update our cache");
				[(NSObject<Contact> *)self updateManagedObjectWithAddressbookRecordDetails];
			}
			_addressbookCacheState = kAddressbookCacheLoaded;
			NSLog(@"Contact '%@' loaded", self.compositeName);
		}
	} else {
		NSLog(@"Contact '%@' has no identifier in the mapping yet", self.compositeName);

		[[_Contact sharedOperationQueue] addOperationWithBlock:^{
			[(NSObject<Contact> *)self syncAddressbookRecord];
		}];

		//[(NSObject<Contact> *)self syncAddressbookRecord];
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
	} else if (self.addressbookIdentifier) {
		NSLog(@"Adding/Updating identifier in Contacts Mapping");
		[[ContactMappingCache sharedInstance] setIdentifier:[NSString stringWithFormat:@"%d", self.addressbookIdentifier] forContact:self];
	}	
}

- (AddressbookCacheState)addressbookCacheState {
	return _addressbookCacheState;
}

- (BOOL)isContactOlderThanAddressbookRecord:(TFRecord *)record {
	if (self.lastSync == nil) {
		return true;
	}
	NSDate *modificationDate = [record valueForProperty:kTFModificationDateProperty];
	return ([self.lastSync earlierDate:modificationDate] == self.lastSync);
}

- (TFRecord *)findAddressbookRecord {
	TFRecord * record;
	if (!self.addressbookRecord) {
		if (self.addressbookIdentifier) {
			record = [[TFAddressBook sharedAddressBook] recordForUniqueId:self.addressbookIdentifier];
			if (record == nil) { // i.e. we couldn't find the record
				NSLog(@"The value we had for addressbook identifier was incorrect (contact didn't exist)");
				self.addressbookIdentifier = 0;
				[[ContactMappingCache sharedInstance] removeIdentifierForContact:self];
				_addressbookCacheState = kAddressbookCacheNotLoaded;
				[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
			}
		}
	}
	
	return record;
}

- (TFRecordID)addressbookIdentifier {
	if (addressbookIdentifier == 0) {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
		addressbookIdentifier = (TFRecordID)[[[ContactMappingCache sharedInstance] identifierForContact:self] integerValue];
#else
		addressbookIdentifier = (TFRecordID)[[ContactMappingCache sharedInstance] identifierForContact:self];
#endif
	}
	return addressbookIdentifier;
}


- (TFRecord *)addressbookRecord {
	return [[TFAddressBook sharedAddressBook] recordForUniqueId:self.addressbookIdentifier];
}

- (void)updateManagedObjectWithAddressbookRecordDetails {
	
	if (self.addressbookRecord == 0) {
		NSLog(@"Can't update record, object's _addressbookRecord is nil");
		return;
	}
	
	NSInteger personFlags = [[self.addressbookRecord valueForProperty:kTFPersonFlags] integerValue];
	self.isCompany = (personFlags & kTFShowAsCompany);
	
	self.firstName = [self.addressbookRecord valueForProperty:kTFFirstNameProperty];
	self.lastName = [self.addressbookRecord valueForProperty:kTFLastNameProperty];
	self.company = [self.addressbookRecord valueForProperty:kTFOrganizationProperty];
	
	NSDate *modificationDate = [self.addressbookRecord valueForProperty:kTFModificationDateProperty];
	if (modificationDate) {
		self.lastSync = modificationDate;
	} else {
		NSLog(@"Contact has no last modification date");
	}
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
}

- (NSArray *)ambigousContactMatches {
	return _ambigousPossibleMatches;	
}

- (void)resolveConflictWithAddressbookRecord:(TFRecord *)record {
	self.addressbookIdentifier = [self.addressbookRecord uniqueId];
	[self updateManagedObjectWithAddressbookRecordDetails];
	NSLog(@"Conflict for '%@' is now resolved", self.compositeName);
}

- (AddressbookResyncResults)syncAddressbookRecord {
	@synchronized(self) {
		if (!self.addressbookIdentifier && _addressbookCacheState == kAddressbookCacheNotLoaded) {
			TFAddressBook *addressbook = [TFAddressBook addressBook];
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
			
			
			TFSearchElement *firstNameSearchElement = [TFPerson searchElementForProperty:kTFFirstNameProperty label:nil key:nil value:searchFirstName comparison:kTFEqualCaseInsensitive];
			TFSearchElement *lastNameSearchElement = [TFPerson searchElementForProperty:kTFLastNameProperty label:nil key:nil value:searchLastName comparison:kTFEqualCaseInsensitive];
			TFSearchElement *companySearchElement = [TFPerson searchElementForProperty:kTFOrganizationProperty label:nil key:nil value:searchCompany comparison:kTFEqualCaseInsensitive];
			
			TFSearchElement *compositeSearchElement = [TFSearchElement searchElementForConjunction:kTFSearchAnd children:[NSArray arrayWithObjects:firstNameSearchElement, lastNameSearchElement, companySearchElement, nil]];
			
			NSArray *people = [addressbook recordsMatchingSearchElement:compositeSearchElement];
			
			// Filter out everyone who matches these properties & doesn't currently have a mapping to a existing Contact
			NSArray *filteredPeople = [people filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
				NSInteger personFlags = [[(ABPerson *)evaluatedObject valueForProperty:kABPersonFlags] integerValue];
				return (self.isCompany == (personFlags & kABShowAsCompany));
			}]];
			
			NSUInteger count = [filteredPeople count];
			
			if (count == 0) {
				NSLog(@"No match found for '%@'", self.compositeName);
				_addressbookCacheState = kAddressbookCacheLoadFailed;
				return kAddressbookSyncMatchFailed;
			} else if (count == 1) {
				self.addressbookIdentifier = [[filteredPeople lastObject] uniqueId];
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
				TFRecord *record;
				for (NSUInteger i = 0; i < [filteredPeople count]; i++) {
					record = [filteredPeople objectAtIndex:i];
					NSLog(@"Match on '%@ %@/%@' [%@]", [record valueForProperty:kTFFirstNameProperty], [record valueForProperty:kTFLastNameProperty], [record  valueForProperty:kTFOrganizationProperty], [record uniqueId]);
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

- (NSString *)identifierForContact:(_Contact *)contact {
	@synchronized(self) {
		NSString *key = [[contact.objectID URIRepresentation] absoluteString];
		return [_mappings objectForKey:key];
	}
}

- (void)setIdentifier:(NSString *)identifier forContact:(_Contact *)contact {
	NSString *key = [[contact.objectID URIRepresentation] absoluteString];
	@synchronized(self) {
		NSMutableDictionary *newMappings = [NSMutableDictionary dictionaryWithDictionary:_mappings];
		[newMappings setObject:identifier forKey:key];
		_mappings = [NSDictionary dictionaryWithDictionary:newMappings];
	}
	_changed = YES;
}

- (void)removeIdentifierForContact:(_Contact *)contact {
	NSString *key = [[contact.objectID URIRepresentation] absoluteString];
	@synchronized(self) {
		NSMutableDictionary *newMappings = [NSMutableDictionary dictionaryWithDictionary:_mappings];
		[newMappings removeObjectForKey:key];
		_mappings = [NSDictionary dictionaryWithDictionary:newMappings];
	}
	_changed = YES;
}

- (BOOL)contactExistsForIdentifier:(NSString *)identifier {
	@synchronized(self) {
		return [[_mappings allValues] containsObject:identifier];
	}
}

- (_Contact *)contactObjectForIdentifier:(NSString *)identifier {
	if ([self contactExistsForIdentifier:identifier]) {
		@synchronized(self) {
			for (NSString *urlAsString in [_mappings allKeys]) {
				if ([[_mappings valueForKey:urlAsString] isEqualToString:identifier]) {
					NSError *error = nil;
					NSURL *objectURL = [NSURL URLWithString:urlAsString];
					if (objectURL) {
						NSManagedObjectID *objectId = [[MANAGED_OBJECT_CONTEXT persistentStoreCoordinator] managedObjectIDForURIRepresentation:objectURL];
						if (objectId) {
							_Contact *contact = (_Contact *)[MANAGED_OBJECT_CONTEXT existingObjectWithID:objectId error:&error];
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