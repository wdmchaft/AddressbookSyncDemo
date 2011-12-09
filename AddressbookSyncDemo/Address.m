//
//  Address.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 09/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Address.h"

@implementation Address

@synthesize _street;
@synthesize _city;
@synthesize _zip;
@synthesize _state;
@synthesize _country;


- (NSString *)description {
	return [NSString stringWithFormat:@"{%@: street: %@\n\t    city: %@\n\t    zip: %@\n\t    state: %@\n\t    country: %@}", self.label, self.street, self.city, self.zip, self.state, self.country];
}

- (void)populateWithProperties:(TFMultiValue *)properties reference:(TFMultiValueIdentifier)id {
	self.identifier = id;
	[self willChangeValueForKey:@"_label"];
	_label = TFLocalizedPropertyOrLabel([properties labelForIdentifier:self.identifier]);
	[self didChangeValueForKey:@"_label"];
	NSDictionary *addressDict = [properties valueForIdentifier:self.identifier];
	[self willChangeValueForKey:@"_street"];
	_street = [addressDict objectForKey:kTFAddressStreetKey];
	[self didChangeValueForKey:@"_street"];
	[self willChangeValueForKey:@"_city"];
	_city = [addressDict objectForKey:kTFAddressCityKey];
	[self didChangeValueForKey:@"_city"];
	[self willChangeValueForKey:@"_state"];
	_state = [addressDict objectForKey:kTFAddressStateKey];
	[self didChangeValueForKey:@"_state"];
	[self willChangeValueForKey:@"_country"];
	_country = [addressDict objectForKey:kTFAddressCountryKey];
	[self didChangeValueForKey:@"_country"];
	[self willChangeValueForKey:@"_zip"];
	_zip = [addressDict objectForKey:kTFAddressZIPKey];
	[self didChangeValueForKey:@"_zip"];
}

@end
