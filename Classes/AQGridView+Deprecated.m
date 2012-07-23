//
//  AQGridView+Deprecated.m
//  AQGridView
//
//  Created by Evadne Wu on 7/23/12.
//	Copyright (c) 2012 AQGridView. All rights reserved.
//

#import "AQGridView+Deprecated.h"

@implementation AQGridView (Deprecated)

- (BOOL) allowsSelection {

	return [self selectable];

}

- (void) setAllowsSelection:(BOOL)allowsSelection {

	[self setSelectable:allowsSelection];

}

- (NSUInteger) indexOfSelectedItem {

	NSIndexSet *indexes = [self selectionIndexes];
	if (![indexes count])
		return NSNotFound;
	
	return [indexes firstIndex];

}

- (BOOL) clipsContentWidthToBounds {
	
	return (self.layoutDirection == AQGridViewLayoutDirectionVertical);
	
}

- (void) setClipsContentWidthToBounds:(BOOL)value {
	
	self.layoutDirection = (value ? AQGridViewLayoutDirectionVertical : AQGridViewLayoutDirectionHorizontal);
	
}

@end
