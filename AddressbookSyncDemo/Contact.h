//
//  Contact.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 23/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "_Contact.h"
#import <AddressBook/AddressBook.h>

@interface Contact : _Contact <Contact> {
}

@property (weak, nonatomic, readonly) NSString *compositeName;
@property (weak, nonatomic, readonly) NSString *secondaryCompositeName;

+ (Contact *)initContactWithAddressbookRecord:(ABRecordRef)record;
+ (Contact *)findContactForRecordId:(ABRecordID)recordId;
- (BOOL)isContactOlderThanAddressbookRecord:(ABRecordRef)record;

- (ABRecordRef)findAddressbookRecord;
- (AddressbookResyncResults)syncAddressbookRecord;
- (void)resolveConflictWithAddressbookRecord:(ABRecordRef)record;

@end
