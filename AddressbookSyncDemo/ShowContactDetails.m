//
//  ShowContactDetails.m
//  ShootStudio
//
//  Created by Tom Fewster on 22/09/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ShowContactDetails.h"
#import "Contact.h"

@interface ShowContactDetails (private)
- (UIViewController *)displayTemplateForUnknownContact;
- (UIViewController *)view;
@end

@implementation ShowContactDetails

@synthesize parentViewController;
@synthesize contact;

+ (UIViewController *)viewControllerForDisplayingContact:(Contact *)contact {
	static dispatch_once_t onceToken = 0;
	__strong static ShowContactDetails *contactDetails = nil;
	dispatch_once(&onceToken, ^{
		contactDetails =[[ShowContactDetails alloc] init];
	});
	contactDetails.contact = contact;
	return [contactDetails view];
}

- (UIViewController *)view {
	if (self.contact.addressbookIdentifier) {
		ABAddressBookRef addressBook = ABAddressBookCreate();
		
		ABRecordID recordId = [self.contact.addressbookIdentifier integerValue];
		if (recordId == 0 && (errno == EINVAL || errno == ERANGE)) {
			NSLog(@"'%@' isn't a valid record id", self.contact.addressbookIdentifier);
			return [self displayTemplateForUnknownContact];
		} else {
			ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, recordId);
			if (person != nil) {
				ABPersonViewController *picker = [[ABPersonViewController alloc] init];
				picker.personViewDelegate = self;
				picker.displayedPerson = person;
				// Allow users to edit the person’s information
				picker.allowsEditing = YES;
				return picker;
			} else {
				return [self displayTemplateForUnknownContact];
			}
		}
		CFRelease(addressBook);
	} else {
		return [self displayTemplateForUnknownContact];
	}	
}


- (UIViewController *)displayTemplateForUnknownContact {
	ABRecordRef aContact = ABPersonCreate();
	CFErrorRef error = NULL;
	if (self.contact.firstName && error == NULL) {
		ABRecordSetValue(aContact, kABPersonFirstNameProperty, (__bridge CFStringRef)self.contact.firstName, &error);
	}
	if (self.contact.lastName && error == NULL) {
		ABRecordSetValue(aContact, kABPersonLastNameProperty, (__bridge CFStringRef)self.contact.lastName, &error);
	}
	if (self.contact.company && error == NULL) {
		ABRecordSetValue(aContact, kABPersonOrganizationProperty, (__bridge CFStringRef)self.contact.company, &error);
	}
	if (self.contact.isCompany && error == NULL) {
		ABRecordSetValue(aContact, kABPersonKindProperty, self.contact.isCompany?kABPersonKindOrganization:kABPersonKindPerson, &error);
	}
	
	CFRelease(aContact);
	
	return nil;
}


#pragma mark ABPersonViewControllerDelegate methods
// Does not allow users to perform default actions such as dialing a phone number, when they select a contact property.
- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person 
					property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifierForValue
{
	return YES;
}


#pragma mark ABNewPersonViewControllerDelegate methods
// Dismisses the new-person view controller. 
- (void)newPersonViewController:(ABNewPersonViewController *)newPersonViewController didCompleteWithNewPerson:(ABRecordRef)person
{
	[self.parentViewController dismissModalViewControllerAnimated:YES];
}


#pragma mark ABUnknownPersonViewControllerDelegate methods
// Dismisses the picker when users are done creating a contact or adding the displayed person properties to an existing contact. 
- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonView didResolveToPerson:(ABRecordRef)person
{
	[self.parentViewController dismissModalViewControllerAnimated:YES];
}


// Does not allow users to perform default actions such as emailing a contact, when they select a contact property.
- (BOOL)unknownPersonViewController:(ABUnknownPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person 
						   property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	return YES;
}

@end
