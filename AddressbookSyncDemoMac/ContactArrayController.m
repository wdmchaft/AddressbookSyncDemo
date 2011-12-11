//
//  ContactArrayController.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 04/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ContactArrayController.h"

@implementation ContactArrayController

- (BOOL)fetchWithRequest:(NSFetchRequest *)fetchRequest merge:(BOOL)merge error:(NSError **)error {
	fetchRequest.returnsObjectsAsFaults = YES;
	return [super fetchWithRequest:fetchRequest merge:merge error:error];
}

@end
