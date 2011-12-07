//
//  CompositeNameValueTransformer.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 07/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CompositeNameValueTransformer.h"
#import "TFABAddressBook.h"
#import "TFPerson+CompositeName.h"

@implementation CompositeNameValueTransformer
+ (Class)transformedValueClass {
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
	return NO;
}

- (id)transformedValue:(NSString *)value {
	if (value == nil) {
		return nil;
	} else {
		return [(TFPerson *)[[TFAddressBook addressBook] recordForUniqueId:value] compositeName];
	}
}
@end
