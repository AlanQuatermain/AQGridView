//
//  AQGridView+Deprecated.m
//  AQGridView
//
//  Created by Evadne Wu on 7/23/12.
//
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

@end
