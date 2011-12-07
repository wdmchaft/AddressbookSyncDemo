//
//  TFPerson+CompositeName.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 07/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TFABAddressBook.h"

@interface TFPerson (CompositeName)

@property (nonatomic, readonly, weak) NSString *compositeName;

@end
