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
	BOOL _changed;
	NSString *_label;
	NSString *_value;
}

@property (nonatomic, assign) ABMultiValueRef properties;
@property (assign) ABMultiValueIdentifier identifier;

@property (readonly, getter=hasChanged) BOOL _changed;

@end
