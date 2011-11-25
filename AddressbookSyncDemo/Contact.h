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
	ABRecordRef _addressbookRecord;
}

@property (nonatomic, strong) NSDate * lastSync;
@property (nonatomic, strong) NSString * firstName;
@property (nonatomic, strong) NSString * lastName;
@property (nonatomic, strong) NSString * company;
@property (nonatomic, strong) NSString * addressbookIdentifier;
@property (nonatomic) AddressbookCacheState _addressbookCacheState;
@property (nonatomic) BOOL isCompany;
@property (nonatomic) int16_t syncStatus;

@property (nonatomic, readonly) NSString *compositeName;

+ (Contact *)initContactWithAddressbookRecord:(ABRecordRef)record;
+ (Contact *)findContactForRecordId:(ABRecordID)recordId;
- (ABRecordRef)findAddressbookRecord;
- (BOOL)isContactOlderThanAddressbookRecord:(ABRecordRef)record;
- (AddressbookResyncResults)syncAddressbookRecord;

@end
