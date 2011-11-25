//
//  Contact.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 23/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <AddressBook/AddressBook.h>

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

extern NSString *kContactSyncStateChanged;

@interface Contact : NSManagedObject {
	AddressbookCacheState _addressbookCacheState;
}

@property (nonatomic, strong) NSDate * lastSync;
@property (nonatomic, strong) NSString * firstName;
@property (nonatomic, strong) NSString * lastName;
@property (nonatomic, strong) NSString * company;
@property (nonatomic) BOOL isCompany;
@property (nonatomic) int16_t syncStatus;
@property (assign) ABRecordID addressbookIdentifier;
@property (assign) ABRecordRef addressbookRecord;
@property (nonatomic, readonly) AddressbookCacheState addressbookCacheState;

@property (nonatomic, readonly) NSString *compositeName;

+ (Contact *)initContactWithAddressbookRecord:(ABRecordRef)record;
+ (Contact *)findContactForRecordId:(ABRecordID)recordId;
- (BOOL)isContactOlderThanAddressbookRecord:(ABRecordRef)record;

- (ABRecordRef)findAddressbookRecord;
- (AddressbookResyncResults)syncAddressbookRecord;

@end
