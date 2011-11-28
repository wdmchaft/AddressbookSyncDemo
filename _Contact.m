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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveRequest:) name:UIApplicationWillResignActiveNotification object:nil];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
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

- (NSString *)identifierForContact:(NSManagedObject *)contact {
	@synchronized(self) {
		NSString *key = [[contact.objectID URIRepresentation] absoluteString];
		return [_mappings objectForKey:key];
	}
}

- (void)setIdentifier:(NSString *)identifier forContact:(NSManagedObject *)contact {
	NSString *key = [[contact.objectID URIRepresentation] absoluteString];
	@synchronized(self) {
		NSMutableDictionary *newMappings = [NSMutableDictionary dictionaryWithDictionary:_mappings];
		[newMappings setObject:identifier forKey:key];
		_mappings = [NSDictionary dictionaryWithDictionary:newMappings];
	}
	_changed = YES;
}

- (void)removeIdentifierForContact:(NSManagedObject *)contact {
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

@end

@implementation _Contact

@dynamic lastSync;
@dynamic firstName;
@dynamic lastName;
@dynamic company;
@dynamic isCompany;
@dynamic syncStatus;

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
/*
- (void)awakeFromFetch {
	[super awakeFromFetch];
	
	NSLog(@"Contact '%@' has been initialiased, loading details from cache", self.compositeName);
	self.addressbookIdentifier = (ABRecordID)[[[ContactMappingCache sharedInstance] identifierForContact:self] integerValue];
	_addressbookCacheState = kAddressbookCacheNotLoaded;
	if (self.addressbookIdentifier != 0) {
		self.addressbookRecord = ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), self.addressbookIdentifier);
		if (self.addressbookRecord == nil) { // i.e. we couldn't find the record
			NSLog(@"The value we had for addressbook identifier was incorrect ('%@' didn't exist)", self.compositeName);
			self.addressbookIdentifier = 0;
			[[ContactMappingCache sharedInstance] removeIdentifierForContact:self];
			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
			[self syncAddressbookRecord];
		} else {
			if ([self isContactOlderThanAddressbookRecord:self.addressbookRecord]) {
				NSLog(@"Addressbook contact is newer, we need to update our cache");
				[self updateManagedObjectWithAddressbookRecordDetails];
			}
			_addressbookCacheState = kAddressbookCacheLoaded;
			NSLog(@"Contact '%@' loaded", self.compositeName);
		}
	} else {
		NSLog(@"Contact '%@' has no identifier in the mapping yet", self.compositeName);
		[[Contact sharedOperationQueue] addOperationWithBlock:^{
			[self syncAddressbookRecord];
		}];
		
		//		[self syncAddressbookRecord];
	}
}
*/
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

@end
