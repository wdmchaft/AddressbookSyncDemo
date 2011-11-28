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
@property (assign) AddressbookRecordIdentifier addressbookIdentifier;
@property (assign) AddressbookRecord addressbookRecord;

+ (Contact *)initContactWithAddressbookRecord:(AddressbookRecord)record;
+ (Contact *)findContactForRecordId:(AddressbookRecordIdentifier)recordId;

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
@property (nonatomic) int16_t syncStatus;

@property (nonatomic, readonly) AddressbookCacheState addressbookCacheState;
@property (nonatomic, readonly) NSArray *ambigousContactMatches;

@property (weak, nonatomic, readonly) NSString *compositeName;
@property (weak, nonatomic, readonly) NSString *secondaryCompositeName;

@property (assign) AddressbookRecordIdentifier addressbookIdentifier;
@property (assign) AddressbookRecord addressbookRecord;

+ (NSOperationQueue *)sharedOperationQueue;

@end

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