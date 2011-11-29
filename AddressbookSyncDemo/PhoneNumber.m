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

@synthesize _changed;

- (void)initialiseCache {
	if (_label == nil) {
		CFIndex index = ABMultiValueGetIndexForIdentifier(self.properties, self.identifier);
		CFStringRef rawLabel = ABMultiValueCopyLabelAtIndex(properties, index);
		_label = (__bridge_transfer NSString *)ABAddressBookCopyLocalizedLabel(rawLabel);
		if (rawLabel) {
			CFRelease(rawLabel);
		}
	}
	if (_value == nil) {
		CFIndex index = ABMultiValueGetIndexForIdentifier(self.properties, self.identifier);
		_value = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(properties, index);
	}
}

- (NSString *)label {
	if (_label == nil || _changed) {
		[self initialiseCache];
		_changed = NO;
	}
	return _label;
}

- (NSString *)value {
	if (_value == nil || _changed) {
		[self initialiseCache];
		_changed = NO;
	}
	return _value;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"{%@: %@}", self.label, self.value];
}

- (void)setProperties:(ABMultiValueRef)value {
	properties = value;
	_changed = YES;
}

- (BOOL)isEqual:(PhoneNumber *)object {
	return (self.identifier == object.identifier);
}

@end
