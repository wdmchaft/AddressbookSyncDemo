//
//  NSManagedObjectContext+SearchExtensions.h
//  ShootStudio
//
//  Created by Tom Fewster on 14/07/2011.
//  Copyright 2011 Tom Fewster. All rights reserved.
//


@interface NSManagedObjectContext (SearchExtensions)

- (NSSet *)fetchObjectsForEntityName:(NSString *)newEntityName withPredicate:(id)stringOrPredicate, ...;

@end
