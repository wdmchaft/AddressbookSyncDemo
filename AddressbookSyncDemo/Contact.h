//
//  Contact.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 23/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "_Contact.h"
#import "TFABAddressBook.h"

@interface Contact : _Contact <Contact> {
}

+ (Contact *)initContactWithAddressbookRecord:(TFRecord *)record;
- (void)updateManagedObjectWithAddressbookRecordDetails;
- (BOOL)isContactOlderThanAddressbookRecord:(TFRecord *)record;
- (TFRecord *)findAddressbookRecord;
- (AddressbookResyncResults)syncAddressbookRecord;
- (void)resolveConflictWithAddressbookRecord:(TFRecord *)record;

@end
