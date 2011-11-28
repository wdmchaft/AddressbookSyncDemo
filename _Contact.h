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

@property (assign) AddressbookRecordIdentifier addressbookIdentifier;
@property (assign) AddressbookRecord addressbookRecord;

+ (_Contact *)findContactForRecordId:(AddressbookRecordIdentifier)recordId;
+ (NSOperationQueue *)sharedOperationQueue;

@end

@interface ContactMappingCache : NSObject {
@private
    NSDictionary *_mappings;
	BOOL _changed;
}
+ (ContactMappingCache *)sharedInstance;
- (NSString *)identifierForContact:(_Contact *)contact;
- (void)setIdentifier:(NSString *)identifier forContact:(_Contact *)contact;
- (void)removeIdentifierForContact:(_Contact *)contact;
- (BOOL)contactExistsForIdentifier:(NSString *)identifier;
@end