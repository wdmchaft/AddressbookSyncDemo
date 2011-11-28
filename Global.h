//
//  Global.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 27/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NSManagedObjectContext+SearchExtensions.h"
#import "NSObject+BlockExtensions.h"

#ifdef UNIT_TEST
extern NSManagedObjectContext *s_unitTestManagedObjectContext;
#	define MANAGED_OBJECT_CONTEXT s_unitTestManagedObjectContext
#else
#	if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
@protocol UIManagedObjectApplicationDelegate <UIApplicationDelegate>
- (NSManagedObjectContext *)managedObjectContext;
@end
#		define UIApp [UIApplication sharedApplication]
#		define MANAGED_OBJECT_CONTEXT [((NSObject<UIManagedObjectApplicationDelegate> *)[UIApp delegate]) managedObjectContext]
#	else
#		define MANAGED_OBJECT_CONTEXT [[NSApp delegate] managedObjectContext]
#	endif
#endif
