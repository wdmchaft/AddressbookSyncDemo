//
//  _PhoneNumber.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 29/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "_ContactMultiProperty.h"

@implementation _ContactMultiProperty

@synthesize identifier;
@synthesize _value;
@synthesize _label;

- (NSString *)description {
	return [NSString stringWithFormat:@"{%@: %@}", self.label, self.value];
}

- (void)populateWithProperties:(TFMultiValue *)properties reference:(TFMultiValueIdentifier)id {
	self.identifier = id;
	[self willChangeValueForKey:@"_label"];
	_label = [properties labelForIdentifier:identifier];
	[self didChangeValueForKey:@"_label"];
	[self willChangeValueForKey:@"_value"];
	_value = [properties valueForIdentifier:identifier];
	[self didChangeValueForKey:@"_value"];
}

- (BOOL)isEqual:(_ContactMultiProperty *)object {
	return (self.identifier == object.identifier);
}

- (NSUInteger)hash {
	return (NSUInteger)self.identifier;
}

@end
