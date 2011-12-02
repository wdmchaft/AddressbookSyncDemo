//
//  Contact.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 28/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Contact.h"

@implementation Contact


+ (Contact *)initContactWithAddressbookRecord:(AddressbookRecord)record {
	// Add this contact to the Object Graph
	Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:MANAGED_OBJECT_CONTEXT];
	contact.addressbookIdentifier = [record uniqueId];
	[contact updateManagedObjectWithAddressbookRecordDetails];
	
	return contact;
}





@end
