//
//  _PhoneNumber.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 29/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFABAddressBook.h"

@interface _ContactMultiProperty : NSObject {
	NSString *_label;
	NSString *_value;
}

@property (assign) TFMultiValueIdentifier identifier;
@property (readonly, strong, nonatomic, getter=label) NSString *_label;
@property (readonly, strong, nonatomic, getter=value) NSString *_value;

- (void)populateWithProperties:(TFMultiValue *)properties reference:(TFMultiValueIdentifier)identifier;

@end
