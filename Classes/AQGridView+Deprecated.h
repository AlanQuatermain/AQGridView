//
//  AQGridView+Deprecated.h
//  AQGridView
//
//  Created by Evadne Wu on 7/23/12.
//
//

#import "AQGridView.h"

@interface AQGridView (Deprecated)

@property (nonatomic) BOOL allowsSelection DEPRECATED_ATTRIBUTE;	// use selectable

- (NSUInteger) indexOfSelectedItem DEPRECATED_ATTRIBUTE;
//	returns NSNotFound if no item is selected
//	returns first item in selectionIndexes if multiple selection is enabled

@end
