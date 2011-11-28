//
//  Contact.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 28/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "_Contact.h"

@interface Contact : _Contact <Contact>

+ (Contact *)initContactWithAddressbookRecord:(AddressbookRecord)record;
- (void)updateManagedObjectWithAddressbookRecordDetails;
- (BOOL)isContactOlderThanAddressbookRecord:(AddressbookRecord)record;
- (AddressbookRecord)findAddressbookRecord;
- (AddressbookResyncResults)syncAddressbookRecord;
- (void)resolveConflictWithAddressbookRecord:(AddressbookRecord)record;

@end
