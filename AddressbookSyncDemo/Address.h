//
//  Address.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 09/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "_ContactMultiProperty.h"

@interface Address : _ContactMultiProperty

@property (readonly, strong, nonatomic, getter=street) NSString *_street;
@property (readonly, strong, nonatomic, getter=city) NSString *_city;
@property (readonly, strong, nonatomic, getter=zip) NSString *_zip;
@property (readonly, strong, nonatomic, getter=state) NSString *_state;
@property (readonly, strong, nonatomic, getter=country) NSString *_country;

@end
