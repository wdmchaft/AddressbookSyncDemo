//
//  _Contact.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 28/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum {
	kAddressbookCacheNotLoaded,
	kAddressbookCacheCurrentlyLoading,
	kAddressbookCacheLoadFailed,
	kAddressbookCacheLoadAmbigous,
	kAddressbookCacheLoaded
} AddressbookCacheState;

typedef enum {
	kAddressbookSyncNotRequired,
	kAddressbookSyncMatchFound,
	kAddressbookSyncAmbigousResults,
	kAddressbookSyncMatchFailed
} AddressbookResyncResults;

extern NSString *kContactSyncStateChangedNotification;

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#	import <AddressBook/AddressBook.h>
#	define AddressbookRecordIdentifier ABRecordID
#	define AddressbookRecord ABRecordRef
#else
#	import <AddressBook/AddressBook.h>
#	define AddressbookRecordIdentifier NSString *
#	define AddressbookRecord ABRecord *
#endif

@class Contact;

@protocol Contact <NSObject>

@property (weak, nonatomic, readonly) NSString *compositeName;
@property (weak, nonatomic, readonly) NSString *secondaryCompositeName;

@property (weak, nonatomic, readonly) NSArray *phoneNumbers;
@property (weak, nonatomic, readonly) NSArray *emailAddresses;
@property (weak, nonatomic, readonly) NSArray *addresses;
@property (weak, nonatomic, readonly) NSArray *websites;

+ (Contact *)initContactWithAddressbookRecord:(AddressbookRecord)record;

- (void)updateManagedObjectWithAddressbookRecordDetails;
- (BOOL)isContactOlderThanAddressbookRecord:(AddressbookRecord)record;
- (AddressbookRecord)findAddressbookRecord;
- (AddressbookResyncResults)syncAddressbookRecord;
- (void)resolveConflictWithAddressbookRecord:(AddressbookRecord)record;

@end


@interface _Contact : NSManagedObject {
	AddressbookCacheState _addressbookCacheState;
	NSArray *_ambigousPossibleMatches;
	NSArray *_phoneNumbers;
	NSArray *_emailAddresses;
	NSArray *_addresses;
	NSArray *_websites;
}

@property (nonatomic, strong) NSDate * lastSync;
@property (nonatomic, strong) NSString * firstName;
@property (nonatomic, strong) NSString * lastName;
@property (nonatomic, strong) NSString * company;
@property (nonatomic) BOOL isCompany;
@property (nonatomic, strong) NSString * sortTag1;
@property (nonatomic, strong) NSString * sortTag2;

@property (nonatomic, readonly) AddressbookCacheState addressbookCacheState;
@property (nonatomic, readonly) NSArray *ambigousContactMatches;

@property (weak, nonatomic, readonly) NSString *compositeName;
@property (weak, nonatomic, readonly) NSString *secondaryCompositeName;

@property (weak, nonatomic, readonly) NSString *groupingIndexCharacter;

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
@property (nonatomic, assign) AddressbookRecordIdentifier addressbookIdentifier;
@property (nonatomic, readonly) AddressbookRecord addressbookRecord;
#else
@property (nonatomic, strong) AddressbookRecordIdentifier addressbookIdentifier;
@property (nonatomic, readonly, weak) AddressbookRecord addressbookRecord;
#endif

+ (_Contact *)findContactForRecordId:(AddressbookRecordIdentifier)recordId;
+ (NSOperationQueue *)sharedOperationQueue;

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
+ (ABAddressBookRef)sharedAddressbook;
#else
+ (ABAddressBook *)sharedAddressbook;
#endif

@end

@interface ContactMappingCache : NSObject {
@private
    __strong NSDictionary *_mappings;
	BOOL _changed;
}
+ (ContactMappingCache *)sharedInstance;
- (NSString *)identifierForContact:(_Contact *)contact;
- (void)setIdentifier:(NSString *)identifier forContact:(_Contact *)contact;
- (void)removeIdentifierForContact:(_Contact *)contact;
- (BOOL)contactExistsForIdentifier:(NSString *)identifier;
- (_Contact *)contactObjectForIdentifier:(NSString *)identifier;
@end
