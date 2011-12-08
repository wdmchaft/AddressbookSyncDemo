//
//  Contact.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 23/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Contact.h"
#import "UIAlertView+BlockExtensions.h"
#import "PhoneNumber.h"
#import "EmailAddress.h"

@implementation Contact


+ (Contact *)initContactWithAddressbookRecord:(TFRecord *)record {
	// Add this contact to the Object Graph
	Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:MANAGED_OBJECT_CONTEXT];
	contact.addressbookIdentifier = [record uniqueId];
	[contact updateManagedObjectWithAddressbookRecordDetails];
	
	return contact;
}

- (NSArray *)phoneNumbers {
	if (_phoneNumbers == nil) {
		_phoneNumbers = [NSArray array];
	}
	
	TFRecord *record = self.addressbookRecord;
	if (record) {
		TFMultiValue *properties = [record valueForProperty:kTFPhoneProperty];
		NSMutableArray *values = [NSMutableArray arrayWithArray:_phoneNumbers];
		for (NSUInteger i = 0; i < [properties count]; i++) {
			TFMultiValueIdentifier identifier = [properties identifierAtIndex:i];
			NSUInteger index = [_phoneNumbers indexOfObjectPassingTest:^BOOL(PhoneNumber *obj, NSUInteger idx, BOOL *stop) {
				return obj.identifier == identifier;
			}];

			PhoneNumber *phoneNumber;
			if (index == NSNotFound) {
				NSLog(@"creating new");
				phoneNumber = [[PhoneNumber alloc] init];
				[values addObject:phoneNumber];
			} else {
				NSLog(@"reusing & updating");
				phoneNumber = [_phoneNumbers objectAtIndex:index];
				[values addObject:phoneNumber];
			}
			[phoneNumber populateWithProperties:properties reference:identifier];
		}
		_phoneNumbers = values;
	}
	return _phoneNumbers;
}

- (NSArray *)emailAddresses {
	if (_emailAddresses == nil) {
		_emailAddresses = [NSArray array];
	}
	
	TFRecord *record = self.addressbookRecord;
	if (record) {
		TFMultiValue *properties = [record valueForProperty:kTFEmailProperty];
		NSMutableArray *values = [NSMutableArray arrayWithArray:_emailAddresses];
		for (NSUInteger i = 0; i < [properties count]; i++) {
			TFMultiValueIdentifier identifier = [properties identifierAtIndex:i];
			NSUInteger index = [_emailAddresses indexOfObjectPassingTest:^BOOL(PhoneNumber *obj, NSUInteger idx, BOOL *stop) {
				return obj.identifier == identifier;
			}];
			
			EmailAddress *emailAddress;
			if (index == NSNotFound) {
				NSLog(@"creating new");
				emailAddress = [[EmailAddress alloc] init];
				[values addObject:emailAddress];
			} else {
				NSLog(@"reusing & updating");
				emailAddress = [_emailAddresses objectAtIndex:index];
				[values addObject:emailAddress];
			}
			[emailAddress populateWithProperties:properties reference:identifier];
		}
		_emailAddresses = values;
	}
	return _emailAddresses;
}

- (NSArray *)addresses {
	return _addresses;
}

- (NSArray *)websites {
	return _websites;
}


@end
