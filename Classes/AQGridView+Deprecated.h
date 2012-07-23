//
//  AQGridView+Deprecated.h
//  AQGridView
//
//  Created by Evadne Wu on 7/23/12.
//	Copyright (c) 2012 AQGridView. All rights reserved.
//


#import "AQGridView.h"

@interface AQGridView (Deprecated)

@property (nonatomic) BOOL allowsSelection DEPRECATED_ATTRIBUTE;	// use selectable

- (NSUInteger) indexOfSelectedItem DEPRECATED_ATTRIBUTE;
//	returns NSNotFound if no item is selected
//	returns first item in selectionIndexes if multiple selection is enabled

@property (nonatomic, assign) BOOL clipsContentWidthToBounds DEPRECATED_ATTRIBUTE;
//	default is YES. If you want to enable horizontal scrolling, set this to NO.
//	this property is now officially deprecated -- it will instead set the layout direction to horizontal if
//	this property is set to YES, or to vertical otherwise.

@end
