//
//  EmptyNSArrayControllerSelectionValueTransformer.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 07/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "EmptyNSArrayControllerSelectionValueTransformer.h"

@implementation EmptyNSArrayControllerSelectionValueTransformer

+ (Class)transformedValueClass {
	return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
	return NO;
}

- (id)transformedValue:(NSIndexSet *)value {
    return [NSNumber numberWithBool:(BOOL)[value count]];
}
@end
