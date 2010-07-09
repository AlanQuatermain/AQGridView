//
//  AQGridViewAnimatorItem.m
//  Kobov3
//
//  Created by Jim Dovey on 10-06-29.
//  Copyright 2010 Kobo Inc. All rights reserved.
//

#import "AQGridViewAnimatorItem.h"

@implementation AQGridViewAnimatorItem

@synthesize animatingView, index;

+ (AQGridViewAnimatorItem *) itemWithView: (UIView *) aView index: (NSUInteger) anIndex
{
	AQGridViewAnimatorItem * result = [[self alloc] init];
	result.animatingView = aView;
	result.index = anIndex;
	return ( [result autorelease] );
}

- (void) dealloc
{
	self.animatingView = nil;
	[super dealloc];
}

- (BOOL) isEqual: (AQGridViewAnimatorItem *) object
{
	if ( [object isKindOfClass: [self class]] == NO )
		return ( NO );
	
	return ( object.index == self.index );
}

- (NSUInteger) hash
{
	return ( self.index );
}

@end
