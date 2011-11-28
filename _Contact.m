//
//  _Contact.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 28/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "_Contact.h"

NSString *kContactSyncStateChangedNotification = @"kContactSyncStateChanged";

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
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveRequest:) name:UIApplicationWillResignActiveNotification object:nil];
#else
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveRequest:) name:NSApplicationWillResignActiveNotification object:nil];
#endif
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
#else
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillResignActiveNotification object:nil];
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

+ (NSOperationQueue *)sharedOperationQueue {
	static dispatch_once_t onceToken = 0;
	__strong static NSOperationQueue *_operationQueue = nil;
	dispatch_once(&onceToken, ^{
		_operationQueue = [[NSOperationQueue alloc] init];
	});
	return _operationQueue;
}


+ (Contact *)findContactForRecordId:(AddressbookRecordIdentifier)recordId {
	NSString *addressbookIdentifier = [NSString stringWithFormat:@"%d", recordId];
	return (Contact *)[[ContactMappingCache sharedInstance] contactObjectForIdentifier:addressbookIdentifier];
}

- (void)awakeFromFetch {
	[super awakeFromFetch];
	
	NSLog(@"Contact '%@' has been initialiased, loading details from cache", self.compositeName);
	self.addressbookIdentifier = (AddressbookRecordIdentifier)[[[ContactMappingCache sharedInstance] identifierForContact:self] integerValue];
	_addressbookCacheState = kAddressbookCacheNotLoaded;
	if (self.addressbookIdentifier != 0) {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
		self.addressbookRecord = ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), self.addressbookIdentifier);
#else
		self.addressbookRecord = [[ABAddressBook sharedAddressBook] recordForUniqueId:self.addressbookIdentifier];
#endif
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
		
		//		[self syncAddressbookRecord];
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

- (NSArray *)ambigousContactMatches {
	return _ambigousPossibleMatches;	
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
