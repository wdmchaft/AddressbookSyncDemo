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

@implementation Contact


+ (Contact *)initContactWithAddressbookRecord:(TFRecord *)record {
	// Add this contact to the Object Graph
	Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:MANAGED_OBJECT_CONTEXT];
	contact.addressbookIdentifier = [record uniqueId];
	[contact updateManagedObjectWithAddressbookRecordDetails];
	
	return contact;
}

- (NSString *)compositeName {
	if (self.addressbookRecord != nil) {
		return (__bridge_transfer NSString *)ABRecordCopyCompositeName(self.addressbookRecord); 
	} else {
		if (self.isCompany) {
			return self.company;
		} else {
			NSString *firstName = (self.firstName?self.firstName:@"");
			NSString *lastName = (self.lastName?self.lastName:@"");
			if (ABPersonGetCompositeNameFormat() == kABPersonCompositeNameFormatFirstNameFirst) {
				return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
			} else {
				return [NSString stringWithFormat:@"%@ %@", lastName, firstName];
			}
		}
	}
}

- (NSString *)secondaryCompositeName {
	if (!self.isCompany) {
		return self.company;
	} else {
		NSString *firstName = (self.firstName?self.firstName:@"");
		NSString *lastName = (self.lastName?self.lastName:@"");
		if (ABPersonGetCompositeNameFormat() == kABPersonCompositeNameFormatFirstNameFirst) {
			return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
		} else {
			return [NSString stringWithFormat:@"%@ %@", lastName, firstName];
		}
	}
}



- (NSArray *)phoneNumbers {
	/*
	ABRecordRef record = self.addressbookRecord;
	if (record) {
		ABMultiValueRef properties = ABRecordCopyValue(record, kABPersonPhoneProperty);
		CFIndex max = ABMultiValueGetCount(properties);
		if (max != 0) {
			NSMutableArray *values = [NSMutableArray arrayWithArray:_phoneNumbers];
			for (CFIndex i = 0; i < max; i++) {
				ABMultiValueIdentifier identifier = ABMultiValueGetIdentifierAtIndex(properties, i);
				NSUInteger index = [values indexOfObjectPassingTest:^BOOL(PhoneNumber *obj, NSUInteger idx, BOOL *stop) {
					return obj.identifier == identifier;
				}];
				PhoneNumber *phoneNumber;
				if (index == NSNotFound) {
					NSLog(@"creating new");
					phoneNumber = [[PhoneNumber alloc] init];
					phoneNumber.identifier = identifier;
					[values addObject:phoneNumber];
				} else {
					NSLog(@"reusing & updating");
					phoneNumber = [values objectAtIndex:index];
				}
				phoneNumber.properties = properties;
			}
			
			_phoneNumbers = [values filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"hasChanged = YES"]];
		}
	}
	 */
	return _phoneNumbers;
}

- (NSArray *)emailAddresses {
	return _emailAddresses;
}

- (NSArray *)addresses {
	return _addresses;
}

- (NSArray *)websites {
	return _websites;
}


@end
