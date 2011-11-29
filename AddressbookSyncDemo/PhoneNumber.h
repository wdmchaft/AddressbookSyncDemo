//
//  PhoneNumber.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 29/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "_PhoneNumber.h"
#import <AddressBook/AddressBook.h>

@interface PhoneNumber : _PhoneNumber {
	NSString *_label;
	NSString *_value;
}

@property (assign) ABMultiValueRef properties;
@property (assign) ABMultiValueIdentifier identifier;

@end
