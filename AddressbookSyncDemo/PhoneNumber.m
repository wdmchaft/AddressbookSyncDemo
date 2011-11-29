//
//  PhoneNumber.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 29/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PhoneNumber.h"

@implementation PhoneNumber

@synthesize properties;
@synthesize identifier;

- (NSString *)label {
	if (_label == nil) {
		[self willChangeValueForKey:@"label"];
		CFIndex index = ABMultiValueGetIndexForIdentifier(self.properties, self.identifier);
		CFStringRef rawLabel = ABMultiValueCopyLabelAtIndex(properties, index);
		_label = (__bridge_transfer NSString *)ABAddressBookCopyLocalizedLabel(rawLabel);
		if (rawLabel) {
			CFRelease(rawLabel);
		}
		[self didChangeValueForKey:@"label"];
	}
	return _label;
}

- (NSString *)value {
	if (_value == nil) {
		[self willChangeValueForKey:@"value"];
		CFIndex index = ABMultiValueGetIndexForIdentifier(self.properties, self.identifier);
		_value = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(properties, index);
		[self didChangeValueForKey:@"value"];
	}
	return _value;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"{%@: %@}", self.label, self.value];
}

- (BOOL)isEqual:(PhoneNumber *)object {
	return (self.identifier == object.identifier);
}

@end
