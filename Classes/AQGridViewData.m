/*
 * AQGridViewData.h
 * AQGridView
 * 
 * Created by Jim Dovey on 1/3/2010.
 * Copyright (c) 2010 Kobo Inc. All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "AQGridViewData.h"
#import "AQGridView.h"

@interface AQGridViewData (AQGridViewDataPrivate)
- (void) fixDesiredCellSizeForWidth: (CGFloat) width;
@end

@implementation AQGridViewData

@synthesize reorderedIndex=_reorderedIndex, numberOfItems=_numberOfItems, topPadding=_topPadding, bottomPadding=_bottomPadding, leftPadding=_leftPadding, rightPadding=_rightPadding;

- (id) initWithGridView: (AQGridView *) gridView
{
	self = [super init];
	if ( self == nil )
		return ( nil );
	
	_gridView = gridView;
	_currentWidth = gridView.bounds.size.width;
	
	return ( self );
}

- (id) copyWithZone: (NSZone *) zone
{
	AQGridViewData * theCopy = [[AQGridViewData allocWithZone: zone] initWithGridView: _gridView];
	theCopy->_desiredCellSize = _desiredCellSize;
	theCopy->_actualCellSize = _actualCellSize;
	theCopy->_topPadding = _topPadding;
	theCopy->_bottomPadding = _bottomPadding;
	theCopy->_numberOfItems = _numberOfItems;
	theCopy->_reorderedIndex = _reorderedIndex;
	return ( theCopy );
}

- (id) mutableCopyWithZone: (NSZone *) zone
{
	return ( [self copyWithZone: zone] );
}

- (void) gridViewDidChangeToWidth: (CGFloat) newWidth
{
	_currentWidth = newWidth;
	[self fixDesiredCellSizeForWidth: newWidth];
}

- (NSUInteger) itemIndexForPoint: (CGPoint) point
{
	// adjust for top padding
	point.y -= _topPadding;
	point.x -= _leftPadding;
	
	// get a count of all rows before the one containing the point
	NSUInteger y = (NSUInteger)floorf(point.y);
	NSUInteger row = y / (NSUInteger)_actualCellSize.height;
	
	// now column
	NSUInteger x = (NSUInteger)floorf(point.x);
	NSUInteger col = x / (NSUInteger)_actualCellSize.width;
	
	return ( (row * [self numberOfItemsPerRow]) + col );
}

- (CGRect) cellRectForPoint: (CGPoint) point
{
	return ( [self cellRectAtIndex: [self itemIndexForPoint: point]] );
}

- (void) setDesiredCellSize: (CGSize) desiredCellSize
{
	_desiredCellSize = desiredCellSize;
	[self fixDesiredCellSizeForWidth: _currentWidth];
}

- (CGSize) cellSize
{
	return ( _actualCellSize );
}

- (CGRect) rectForEntireGrid
{
	CGRect rect = _gridView.bounds;
	rect.size.height = [self heightForEntireGrid];
	return ( rect );
}

- (CGFloat) heightForEntireGrid
{
	NSUInteger numPerRow = [self numberOfItemsPerRow];
    if ( numPerRow == 0 )       // avoid a divide-by-zero exception
        return ( 0.0 );
	NSUInteger numRows = _numberOfItems / numPerRow;
	if ( _numberOfItems % numPerRow != 0 )
		numRows++;
	
	return ( ((CGFloat)ceilf((CGFloat)numRows * _actualCellSize.height)) + _topPadding + _bottomPadding );
}

- (NSUInteger) numberOfItemsPerRow
{
	return ( (NSUInteger)floorf(_currentWidth / _actualCellSize.width) );
}

- (CGRect) cellRectAtIndex: (NSUInteger) index
{
	NSUInteger numPerRow = [self numberOfItemsPerRow];
    if ( numPerRow == 0 )       // avoid a divide-by-zero exception
        return ( CGRectZero );
	NSUInteger skipRows = index / numPerRow;
	NSUInteger skipCols = index % numPerRow;
	CGFloat horSpacing = (_currentWidth / numPerRow) - _actualCellSize.width;
	
	CGRect result = CGRectZero;
	result.origin.x = (horSpacing / 2) + ((_actualCellSize.width + horSpacing) * (CGFloat)skipCols + _leftPadding);
	result.origin.y = (_actualCellSize.height  * (CGFloat)skipRows) + _topPadding;
	result.size = _actualCellSize;
	
	return ( result );
}

- (NSIndexSet *) indicesOfCellsInRect: (CGRect) aRect
{
	NSMutableIndexSet * result = [NSMutableIndexSet indexSet];
	NSUInteger numPerRow = [self numberOfItemsPerRow];
	
	for ( NSUInteger i = 0; i < _numberOfItems; i++ )
	{
		CGRect cellRect = [self cellRectAtIndex: i];
		
		if ( CGRectGetMaxY(cellRect) < CGRectGetMinY(aRect) )
		{
			// jump forward to the next row
			i += (numPerRow - 1);
			continue;
		}
		
		if ( CGRectIntersectsRect(cellRect, aRect) )
		{
			[result addIndex: i];
			if ( (CGRectGetMaxY(cellRect) > CGRectGetMaxY(aRect)) &&
				 (CGRectGetMaxX(cellRect) > CGRectGetMaxX(aRect)) )
			{
				// passed the bottom-right edge of the given rect
				break;
			}
		}
	}
	
	return ( result );
}

@end

@implementation AQGridViewData (AQGridViewDataPrivate)

- (void) fixDesiredCellSizeForWidth: (CGFloat) width
{
	NSUInteger w = (NSUInteger)floorf(width - _leftPadding - _rightPadding);
	NSUInteger dw = (NSUInteger)floorf(_desiredCellSize.width);
	
	if ( dw > w )
	{
		dw = w;
	}
	else
	{
		// TODO: this could be optimized
		while ( (w % dw) != 0 )
			dw++;
	}
	
	_actualCellSize.width = 192;
	_actualCellSize.height = _desiredCellSize.height;
}

@end
