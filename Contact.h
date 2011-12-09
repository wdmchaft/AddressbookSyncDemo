//
//  _Contact.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 28/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "TFABAddressBook.h"

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

@interface Contact : NSManagedObject {
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

@property (assign, getter=addressbookCacheState) AddressbookCacheState _addressbookCacheState;
@property (nonatomic, readonly) NSArray *ambigousContactMatches;

@property (weak, nonatomic, readonly) NSString *compositeName;
@property (weak, nonatomic, readonly) NSString *secondaryCompositeName;
@property (weak, nonatomic, readonly) NSString *helpfullText;

@property (weak, nonatomic, readonly) NSString *groupingIndexCharacter;

@property (nonatomic, strong) TFRecordID addressbookIdentifier;
@property (nonatomic, readonly, weak) TFRecord *addressbookRecord;

@property (weak, nonatomic, readonly) NSArray *phoneNumbers;
@property (weak, nonatomic, readonly) NSArray *emailAddresses;
@property (weak, nonatomic, readonly) NSArray *addresses;
@property (weak, nonatomic, readonly) NSArray *websites;

+ (Contact *)initContactWithAddressbookRecord:(TFRecord *)record;
+ (Contact *)findContactForRecordId:(TFRecordID)recordId;
+ (NSOperationQueue *)sharedOperationQueue;
+ (TFAddressBook *)sharedAddressBook;

- (void)updateManagedObjectWithAddressbookRecordDetails;
- (BOOL)isContactOlderThanAddressbookRecord:(TFRecord *)record;
- (TFRecord *)findAddressbookRecord;
- (AddressbookResyncResults)syncAddressbookRecord;
- (void)resolveConflictWithAddressbookRecordId:(TFRecordID)recordId;

@end

@interface ContactMappingCache : NSObject {
@private
    __strong NSDictionary *_mappings;
	BOOL _changed;
}
+ (ContactMappingCache *)sharedInstance;
- (TFRecordID)identifierForContact:(Contact *)contact;
- (void)setIdentifier:(TFRecordID)identifier forContact:(Contact *)contact;
- (void)removeIdentifierForContact:(Contact *)contact;
- (BOOL)contactExistsForIdentifier:(TFRecordID)identifier;
- (Contact *)contactObjectForIdentifier:(TFRecordID)identifier;
@end
