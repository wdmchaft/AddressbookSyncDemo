//
//  Contact.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 23/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "_Contact.h"
#import <AddressBook/AddressBook.h>

@interface Contact : _Contact <Contact> {
}

+ (Contact *)initContactWithAddressbookRecord:(AddressbookRecord)record;
- (void)updateManagedObjectWithAddressbookRecordDetails;
- (BOOL)isContactOlderThanAddressbookRecord:(AddressbookRecord)record;
- (AddressbookRecord)findAddressbookRecord;
- (AddressbookResyncResults)syncAddressbookRecord;
- (void)resolveConflictWithAddressbookRecord:(AddressbookRecord)record;

@end
