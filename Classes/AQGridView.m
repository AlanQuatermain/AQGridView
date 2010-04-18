/*
 * AQGridView.m
 * AQGridView
 * 
 * Created by Jim Dovey on 10/2/2010.
 * Copyright 2010 Kobo Inc. All rights reserved.
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

#import "AQGridView.h"
#import "AQGridViewUpdateItem.h"
#import "AQGridViewData.h"
#import "AQGridViewUpdateInfo.h"
#import "AQGridViewCell+AQGridViewCellPrivate.h"
#import "AQGridView+CellLocationDelegation.h"
#import "NSIndexSet+AQIsSetContiguous.h"

// see _basicHitTest:withEvent: below
#import <objc/objc.h>
#import <objc/runtime.h>

NSString * const AQGridViewSelectionDidChangeNotification = @"AQGridViewSelectionDidChangeNotification";

@interface AQGridView ()
@property (nonatomic, copy) NSArray * animatingCells;
@end

@interface AQGridView (AQCellGridMath)
- (NSUInteger) visibleCellListIndexForItemIndex: (NSUInteger) itemIndex;
@end

@interface AQGridView (AQCellLayout)
- (void) layoutCellsInVisibleCellRange: (NSRange) range;
- (void) layoutAllCells;
- (CGRect) fixCellFrame: (CGRect) cellFrame forGridRect: (CGRect) gridRect;
- (void) updateVisibleGridCellsNow;
- (AQGridViewCell *) createPreparedCellForIndex: (NSUInteger) index;
- (void) insertVisibleCell: (AQGridViewCell *) cell atIndex: (NSUInteger) visibleCellListIndex;
- (void) deleteVisibleCell: (AQGridViewCell *) cell atIndex: (NSUInteger) visibleCellListIndex appendingNewCell: (AQGridViewCell *) newLastCell;
@end

@implementation AQGridView

@synthesize dataSource=_dataSource, backgroundView=_backgroundView, separatorColor=_separatorColor, animatingCells=_animatingCells;

- (void) _sharedGridViewInit
{
	_gridData = [[AQGridViewData alloc] initWithGridView: self];
	[_gridData setDesiredCellSize: CGSizeMake(96.0, 128.0)];
	
	_visibleBounds = self.bounds;
	_visibleCells = [[NSMutableArray alloc] init];
	_reusableGridCells = [[NSMutableDictionary alloc] init];
	_highlightedIndices = [[NSMutableIndexSet alloc] init];

	self.clipsToBounds = YES;
	self.separatorColor = [UIColor colorWithWhite: 0.85 alpha: 1.0];
	
	_selectedIndex = NSNotFound;
	_pendingSelectionIndex = NSNotFound;
	
	_flags.resizesCellWidths = 0;
	_flags.numColumns = [_gridData numberOfItemsPerRow];
	_flags.separatorStyle = AQGridViewCellSeparatorStyleEmptySpace;
	_flags.allowsSelection = 1;
	_flags.usesPagedHorizontalScrolling = NO;
	_flags.clipsContentWidthToBounds = 1;
	_flags.contentSizeFillsBounds = 1;
}

- (id)initWithFrame: (CGRect) frame
{
    self = [super initWithFrame:frame];
	if ( self == nil )
		return ( nil );
	
	[self _sharedGridViewInit];
	
	return ( self );
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
	self = [super initWithCoder: aDecoder];
	if ( self == nil )
		return ( nil );
	
	[self _sharedGridViewInit];
	
	return ( self );
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc
{
	[_visibleCells release];
	[_reusableGridCells release];
	[_highlightedIndices release];
	[_backgroundView release];
	[_separatorColor release];
	[_gridData release];
	[_updateInfo release];
	[_animatingCells release];
	[_headerView release];
	[_footerView release];
	
    [super dealloc];
}

#pragma mark -
#pragma mark Properties

- (void) setDelegate: (id<AQGridViewDelegate>) obj
{
	if ( (obj != nil) && ([obj conformsToProtocol: @protocol(AQGridViewDelegate)] == NO ))
		[NSException raise: NSInvalidArgumentException format: @"Argument to -setDelegate must conform to the AQGridViewDelegate protocol"];
	[super setDelegate: obj];
	
	_flags.delegateWillDisplayCell = [obj respondsToSelector: @selector(gridView:willDisplayCell:forItemAtIndex:)];
	_flags.delegateWillSelectItem = [obj respondsToSelector: @selector(gridView:willSelectItemAtIndex:)];
	_flags.delegateWillDeselectItem = [obj respondsToSelector: @selector(gridView:willDeselectItemAtIndex:)];
	_flags.delegateDidSelectItem = [obj respondsToSelector: @selector(gridView:didSelectItemAtIndex:)];
	_flags.delegateDidDeselectItem = [obj respondsToSelector: @selector(gridView:didDeselectItemAtIndex:)];
	_flags.delegateGestureRecognizerActivated = [obj respondsToSelector: @selector(gridView:gestureRecognizer:activatedForItemAtIndex:)];
	_flags.delegateAdjustGridCellFrame = [obj respondsToSelector: @selector(gridView:adjustCellFrame:withinGridCellFrame:)];
}

- (id<AQGridViewDelegate>) delegate
{
	id obj = [super delegate];
	if ( [obj conformsToProtocol: @protocol(AQGridViewDelegate)] == NO )
		return ( nil );
	return ( obj );
}

- (void) setDataSource: (id<AQGridViewDataSource>) obj
{
	if ((obj != nil) && ([obj conformsToProtocol: @protocol(AQGridViewDataSource)] == NO ))
		[NSException raise: NSInvalidArgumentException format: @"Argument to -setDataSource must conform to the AQGridViewDataSource protocol"];
	
	_dataSource = obj;
	
	_flags.dataSourceGridCellSize = [obj respondsToSelector: @selector(portraitGridCellSizeForGridView:)];
}

- (NSUInteger) numberOfItems
{
	return ( _gridData.numberOfItems );
}

- (NSUInteger) numberOfColumns
{
	if ( _flags.numColumns == 0 )
		_flags.numColumns = 1;
	return ( _flags.numColumns );
}

- (NSUInteger) numberOfRows
{
	return ( _gridData.numberOfItems / _flags.numColumns );
}

- (BOOL) allowsSelection
{
	return ( _flags.allowsSelection );
}

- (void) setAllowsSelection: (BOOL) value
{
	_flags.allowsSelection = (value ? 1 : 0);
}

- (BOOL) requiresSelection
{
	return ( _flags.requiresSelection );
}

- (void) setRequiresSelection: (BOOL) value
{
	_flags.requiresSelection = (value ? 1 : 0);
}

- (BOOL) resizesCellWidthToFit
{
	return ( _flags.resizesCellWidths );
}

- (void) setResizesCellWidthToFit: (BOOL) value
{
	int i = (value ? 1 : 0);
	if ( _flags.resizesCellWidths == i )
		return;
	
	_flags.resizesCellWidths = i;
	[self setNeedsLayout];
}

- (BOOL) clipsContentWidthToBounds
{
	return ( _flags.clipsContentWidthToBounds );
}

- (void) setClipsContentWidthToBounds: (BOOL) value
{
	_flags.clipsContentWidthToBounds = value;
}

- (BOOL) usesPagedHorizontalScrolling
{
	return ( _flags.usesPagedHorizontalScrolling );
}

- (void) setUsesPagedHorizontalScrolling: (BOOL) value
{
	int i = (value ? 1 : 0);
	if ( _flags.usesPagedHorizontalScrolling == i )
		return;
	
	_flags.usesPagedHorizontalScrolling = i;
	[self setNeedsLayout];
}

- (AQGridViewCellSeparatorStyle) separatorStyle
{
	return ( _flags.separatorStyle );
}

- (void) setSeparatorStyle: (AQGridViewCellSeparatorStyle) style
{
	if ( style == _flags.separatorStyle )
		return;
	
	_flags.separatorStyle = style;
	
	for ( AQGridViewCell * cell in _visibleCells )
	{
		cell.separatorStyle = style;
	}
	
	[self setNeedsLayout];
}

- (CGFloat) leftContentInset
{
	return ( _gridData.leftPadding );
}

- (void) setLeftContentInset: (CGFloat) inset
{
	_gridData.leftPadding = inset;
}

- (CGFloat) rightContentInset
{
	return ( _gridData.rightPadding );
}

- (void) setRightContentInset: (CGFloat) inset
{
	_gridData.rightPadding = inset;
}

- (CGSize) gridCellSize
{
	return ( [_gridData cellSize] );
}

- (UIView *) gridHeaderView
{
	return ( [[_headerView retain] autorelease] );
}

- (void) setGridHeaderView: (UIView *) newHeaderView
{
	if ( newHeaderView == _headerView )
		return;
	
	[_headerView removeFromSuperview];
	[_headerView release];
	
	_headerView = [newHeaderView retain];
	if ( _headerView == nil )
	{
		_gridData.topPadding = 0.0;
	}
	else
	{
		[self addSubview: _headerView];
		_gridData.topPadding = _headerView.frame.size.height;
	}
	
	[self setNeedsLayout];
}

- (UIView *) gridFooterView
{
	return ( [[_footerView retain] autorelease] );
}

- (void) setGridFooterView: (UIView *) newFooterView
{
	if ( newFooterView == _footerView )
		return;
	
	[_footerView removeFromSuperview];
	[_footerView release];
	
	_footerView = [newFooterView retain];
	if ( _footerView == nil )
	{
		_gridData.bottomPadding = 0.0;
	}
	else
	{
		[self addSubview: _footerView];
		_gridData.bottomPadding = _footerView.frame.size.height;
	}
	
	[self setNeedsLayout];
}

- (BOOL) contentSizeGrowsToFillBounds
{
	return ( _flags.contentSizeFillsBounds == 1 );
}

- (void) setContentSizeGrowsToFillBounds: (BOOL) value
{
	_flags.contentSizeFillsBounds = (value ? 1 : 0);
}

- (void) updateContentRectWithOldMaxY: (CGFloat) oldMaxY gridHeight: (CGFloat) gridHeight
{
	// update content size
	CGFloat contentWidth = _flags.clipsContentWidthToBounds ? self.bounds.size.width : MAX(self.contentSize.width, self.bounds.size.width);
	self.contentSize = CGSizeMake(contentWidth, gridHeight);
	
	// fix content offset if applicable
	CGPoint offset = self.contentOffset;
	if ( offset.y + self.bounds.size.height > self.contentSize.height )
	{
		offset.y = MAX(0.0, self.contentSize.height - self.bounds.size.height);
		self.contentOffset = offset;
	}
	else if ( oldMaxY == self.contentSize.height )
	{
		// we were scrolled to the bottom-- stay there as our height decreases
		offset.y = MAX(0.0, self.contentSize.height - self.bounds.size.height);
		self.contentOffset = offset;
	}
}

- (void) handleGridViewBoundsChanged: (CGRect) oldBounds toNewBounds: (CGRect) bounds
{
	[_gridData gridViewDidChangeToWidth: bounds.size.width];
    _flags.numColumns = [_gridData numberOfItemsPerRow];
	[self updateContentRectWithOldMaxY: CGRectGetMaxY(oldBounds) gridHeight: [_gridData heightForEntireGrid]];
	[self updateVisibleGridCellsNow];
	_flags.allCellsNeedLayout = 1;
}

- (void) setContentSize: (CGSize) newSize
{
	if ( (_flags.contentSizeFillsBounds == 1) && (newSize.height < self.bounds.size.height) )
		newSize.height = self.bounds.size.height;
	
	CGSize oldSize = self.contentSize;
	[super setContentSize: newSize];
	
	if ( oldSize.width != newSize.width )
		[_gridData gridViewDidChangeToWidth: newSize.width];
	
	if ( CGRectGetMaxY(self.bounds) > newSize.height )
	{
		CGRect b = self.bounds;
		CGFloat diff = CGRectGetMaxY(b) - newSize.height;
		b.origin.y = MAX(0.0, b.origin.y - diff);
		self.bounds = b;
	}
}

- (void) setFrame: (CGRect) newFrame
{
	CGRect oldBounds = self.bounds;
	[super setFrame: newFrame];
	CGRect newBounds = self.bounds;
	
	if ( newBounds.size.width != oldBounds.size.width )
		[self handleGridViewBoundsChanged: oldBounds toNewBounds: newBounds];
}

- (void) setBounds: (CGRect) bounds
{
	CGRect oldBounds = self.bounds;
	[super setBounds: bounds];
	bounds = self.bounds;		// in case it was modified
	
	if ( bounds.size.width != oldBounds.size.width )
		[self handleGridViewBoundsChanged: oldBounds toNewBounds: bounds];
}

#pragma mark -
#pragma mark Data Management

- (AQGridViewCell *) dequeueReusableCellWithIdentifier: (NSString *) reuseIdentifier
{
	NSMutableArray * cells = [_reusableGridCells objectForKey: reuseIdentifier];
	AQGridViewCell * cell = [[cells lastObject] retain];
	if ( cell == nil )
		return ( nil );
	
	[cell prepareForReuse];
	
	[cells removeLastObject];
	return ( [cell autorelease] );
}

- (void) enqueueReusableCells: (NSArray *) reusableCells
{
	for ( AQGridViewCell * cell in reusableCells )
	{
		NSMutableArray * reuseArray = [_reusableGridCells objectForKey: cell.reuseIdentifier];
		if ( reuseArray == nil )
		{
			reuseArray = [[NSMutableArray alloc] init];
			[_reusableGridCells setObject: reuseArray forKey: cell.reuseIdentifier];
			[reuseArray release];
		}
		
		[reuseArray addObject: cell];
	}
}

- (CGRect) gridViewVisibleBounds
{
	CGRect result = CGRectZero;
	result.origin = self.contentOffset;
	result.size   = self.bounds.size;
	return ( result );
}

- (void) reloadData
{
	if ( _reloadingSuspendedCount != 0 )
		return;
	
	if ( _flags.dataSourceGridCellSize == 1 )
	{
		[_gridData setDesiredCellSize: [_dataSource portraitGridCellSizeForGridView: self]];
		_flags.numColumns = [_gridData numberOfItemsPerRow];
	}
	
	_gridData.numberOfItems = [_dataSource numberOfItemsInGridView: self];
	if ( _gridData.numberOfItems == 0 )
		return;
	
	// update our content size as appropriate
	CGSize size = self.contentSize;
	size.height = [_gridData heightForEntireGrid];
	self.contentSize = size;
	
	// remove all existing cells
	_visibleIndices.length = 0;
	
	[_visibleCells makeObjectsPerformSelector: @selector(removeFromSuperview)];
	[self enqueueReusableCells: _visibleCells];
	[_visibleCells removeAllObjects];
	
	// reload the cell list
	[self updateVisibleGridCellsNow];
	
	// layout -- no animation
	[self setNeedsLayout];
	_flags.allCellsNeedLayout = 1;
}

- (void) layoutSubviews
{
	if ( (_flags.needsReload == 1) && (_flags.updating == 0) && (_reloadingSuspendedCount == 0) )
		[self reloadData];
	
	if ( (_reloadingSuspendedCount == 0) && (!CGRectIsEmpty([self gridViewVisibleBounds])) )
	{
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		[self updateVisibleGridCellsNow];
		[pool release];
	}
	
	if ( _flags.allCellsNeedLayout == 1 )
	{
		_flags.allCellsNeedLayout = 0;
		if ( _visibleIndices.length != 0 )
			[self layoutAllCells];
	}
	
	CGRect rect = CGRectZero;
	rect.size = self.contentSize;
	rect.size.height -= (_gridData.topPadding + _gridData.bottomPadding);
	rect.origin.y += _gridData.topPadding;
	self.backgroundView.frame = rect;
	
	if ( _headerView != nil )
	{
		rect = _headerView.frame;
		rect.origin = CGPointZero;
		rect.size.width = self.bounds.size.width;
		_headerView.frame = rect;
	}
	
	if ( _footerView != nil )
	{
		rect = _footerView.frame;
		rect.origin.x = 0.0;
		rect.origin.y  = self.contentSize.height - rect.size.height;
		rect.size.width = self.bounds.size.width;
		_footerView.frame = rect;
	}
}

- (CGRect) rectForItemAtIndex: (NSUInteger) index
{
	// simple case -- there's a cell already, we can just ask for its frame
	if ( NSLocationInRange(index, _visibleIndices) )
		return ( [[_visibleCells objectAtIndex: [self visibleCellListIndexForItemIndex: index]] frame] );
	
	// complex case-- compute the frame manually
	return ( [self fixCellFrame: CGRectZero forGridRect: [_gridData cellRectAtIndex: index]] );
}

- (AQGridViewCell *) cellForItemAtIndex: (NSUInteger) index
{
	//if ( NSLocationInRange(index, _visibleIndices) == NO )
	//	return ( nil );
	
	// we don't clip to visible range-- when animating edits the visible cell list can contain extra items
	NSUInteger visibleCellListIndex = [self visibleCellListIndexForItemIndex: index];
	if ( visibleCellListIndex < [_visibleCells count] )
		return ( [_visibleCells objectAtIndex: visibleCellListIndex] );
	return ( nil );
}

- (NSUInteger) indexForItemAtPoint: (CGPoint) point
{
	return ( [_gridData itemIndexForPoint: point] );
}

- (AQGridViewCell *) cellForItemAtPoint: (CGPoint) point
{
	return ( [self cellForItemAtIndex: [_gridData itemIndexForPoint: point]] );
}

- (NSArray *) visibleCells
{
	return ( [[_visibleCells copy] autorelease] );
}

- (NSIndexSet *) visibleCellIndices
{
	return ( [NSIndexSet indexSetWithIndexesInRange: _visibleIndices] );
}

- (void) scrollToItemAtIndex: (NSUInteger) index atScrollPosition: (AQGridViewScrollPosition) scrollPosition
					animated: (BOOL) animated
{
	CGRect gridRect = [_gridData cellRectAtIndex: index];
	CGRect targetRect = self.bounds;
	
	switch ( scrollPosition )
	{
		case AQGridViewScrollPositionNone:
		default:
			targetRect = gridRect;		// no special coordinate handling
			break;
			
		case AQGridViewScrollPositionTop:
			targetRect.origin.y = gridRect.origin.y;	// set target y origin to cell's y origin
			break;
			
		case AQGridViewScrollPositionMiddle:
			targetRect.origin.y = MAX(gridRect.origin.y - (CGFloat)ceilf((targetRect.size.height - gridRect.size.height) * 0.5), 0.0);
			break;
			
		case AQGridViewScrollPositionBottom:
			targetRect.origin.y = MAX((CGFloat)floorf(gridRect.origin.y - (targetRect.size.height - gridRect.size.height)), 0.0);
			break;
	}
	
	[self scrollRectToVisible: targetRect animated: animated];
}

#pragma mark -
#pragma mark Cell Updates

- (BOOL) isRectVisible: (CGRect) frameRect
{
	return ( CGRectIntersectsRect(frameRect, self.bounds) );
}

- (void) fixCellsFromAnimation
{
	// update the visible item list appropriately
	NSIndexSet * indices = [_gridData indicesOfCellsInRect: self.bounds];
	if ( [indices count] == 0 )
	{
		_visibleIndices.location = 0;
		_visibleIndices.length = 0;
		
		// update the content size/offset based on the new grid data
		[self updateContentRectWithOldMaxY: CGRectGetMaxY(self.bounds) gridHeight: [_gridData heightForEntireGrid]];
		return;
	}
	
	_visibleIndices.location = [indices firstIndex];
	_visibleIndices.length = ([indices lastIndex] - [indices firstIndex]) + 1;
	
	NSMutableArray * newVisibleCells = [[NSMutableArray alloc] initWithCapacity: _visibleIndices.length];
	for ( UIView * potentialCellView in self.animatingCells )
	{
		if ( [potentialCellView isKindOfClass: [AQGridViewCell class]] == NO )
		{
			[potentialCellView removeFromSuperview];
			continue;
		}
		
		if ( [self isRectVisible: [_gridData cellRectForPoint: potentialCellView.center]] == NO )
		{
			[potentialCellView removeFromSuperview];
			continue;
		}
		
		[newVisibleCells addObject: potentialCellView];
	}
	
	[newVisibleCells sortUsingSelector: @selector(compareOriginAgainstCell:)];
	[_visibleCells removeObjectsInArray: newVisibleCells];
	[_visibleCells makeObjectsPerformSelector: @selector(removeFromSuperview)];
	[_visibleCells setArray: newVisibleCells];
	[newVisibleCells release];
	self.animatingCells = nil;
	_revealingIndices.length = _revealingIndices.location = 0;
	
	// update the content size/offset based on the new grid data
	[self updateContentRectWithOldMaxY: CGRectGetMaxY(self.bounds) gridHeight: [_gridData heightForEntireGrid]];
}

- (void) setupUpdateAnimations
{
	_flags.updating = 1;
	_flags.isAnimatingUpdates = 1;
	_reloadingSuspendedCount++;
	if ( _updateInfo == nil )
		_updateInfo = [[AQGridViewUpdateInfo alloc] initWithOldGridData: _gridData forGridView: self];
}

- (void) endUpdateAnimations
{
	NSAssert(_updateInfo != nil, @"_updateInfo should not be nil at this point" );
	
	_reloadingSuspendedCount--;
	if ( _updateInfo.numberOfUpdates == 0 )
	{
		//_reloadingSuspendedCount--;
		[_updateInfo release];
		_updateInfo = nil;
		return;
	}
	
	[_updateInfo cleanupUpdateItems];
    
    [UIView beginAnimations: @"CellUpdates" context: nil];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDidStopSelector: @selector(cellUpdateAnimationStopped:finished:context:)];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration: 0.3];
    
	self.animatingCells = [_updateInfo animateCellUpdatesUsingVisibleContentRect: [self gridViewVisibleBounds]];
    
	[UIView commitAnimations];
	
	_flags.updating = 0;
	[_gridData release];
	_gridData = [[_updateInfo newGridViewData] retain];
	if ( _selectedIndex != NSNotFound )
		_selectedIndex = [_updateInfo newIndexForOldIndex: _selectedIndex];
	[_updateInfo release];
	_updateInfo = nil;
}

- (void) cellUpdateAnimationStopped: (NSString *) animationID finished: (BOOL) finished context: (void *) context
{
	// if nothing was animated, we don't have to do anything at all
	if ( self.animatingCells.count != 0 )
		[self fixCellsFromAnimation];
	
	_flags.isAnimatingUpdates = 0;
	
	//_reloadingSuspendedCount--;
}

- (void) beginUpdates
{
	if ( _updateCount++ == 0 )
		[self setupUpdateAnimations];
}

- (void) endUpdates
{
	if ( --_updateCount == 0 )
		[self endUpdateAnimations];
}

- (void) _updateItemsAtIndices: (NSIndexSet *) indices updateAction: (AQGridViewUpdateAction) action withAnimation: (AQGridViewItemAnimation) animation
{
	BOOL wasUpdating = (_flags.updating == 1);
	
	// not in the middle of an update loop -- start animations here
	if ( wasUpdating == NO )
		[self setupUpdateAnimations];
	
	[_updateInfo updateItemsAtIndices: indices updateAction: action withAnimation: animation];
	
	// not in the middle of an update loop -- commit animations here
	if ( wasUpdating == NO )
		[self endUpdateAnimations];
}

- (void) insertItemsAtIndices: (NSIndexSet *) indices withAnimation: (AQGridViewItemAnimation) animation
{
	[self _updateItemsAtIndices: indices updateAction: AQGridViewUpdateActionInsert withAnimation: animation];
}

- (void) deleteItemsAtIndices: (NSIndexSet *) indices withAnimation: (AQGridViewItemAnimation) animation
{
	[self _updateItemsAtIndices: indices updateAction: AQGridViewUpdateActionDelete withAnimation: animation];
}

- (void) reloadItemsAtIndices: (NSIndexSet *) indices withAnimation: (AQGridViewItemAnimation) animation
{
	[self _updateItemsAtIndices: indices updateAction: AQGridViewUpdateActionReload withAnimation: animation];
}

- (void) moveItemAtIndex: (NSUInteger) index toIndex: (NSUInteger) newIndex withAnimation: (AQGridViewItemAnimation) animation
{
	BOOL wasUpdating = (_flags.updating == 1);
	
	if ( wasUpdating == NO )
		[self setupUpdateAnimations];
	
	[_updateInfo moveItemAtIndex: index toIndex: newIndex withAnimation: animation];
	
	if ( wasUpdating == NO )
		[self endUpdateAnimations];
}

#pragma mark -
#pragma mark Selection

- (NSUInteger) indexOfSelectedItem
{
	return ( _selectedIndex );
}

- (void) selectItemAtIndex: (NSUInteger) index animated: (BOOL) animated
			scrollPosition: (AQGridViewScrollPosition) scrollPosition
{
	if ( _selectedIndex != NSNotFound )
		[self deselectItemAtIndex: _selectedIndex animated: NO];
	
	_selectedIndex = index;
	[self scrollToItemAtIndex: index atScrollPosition: AQGridViewScrollPositionNone animated: animated];
}

- (void) deselectItemAtIndex: (NSUInteger) index animated: (BOOL) animated
{
	AQGridViewCell * cell = [self cellForItemAtIndex: index];
	if ( cell != nil )
		[cell setSelected: NO animated: animated];
	
	if ( _selectedIndex == index )
		_selectedIndex = NSNotFound;
}

- (void) highlightItemAtIndex: (NSUInteger) index animated: (BOOL) animated scrollPosition: (AQGridViewScrollPosition) position
{
	if ( [_highlightedIndices containsIndex: index] )
	{
		if ( position != AQGridViewScrollPositionNone )
			[self scrollToItemAtIndex: index atScrollPosition: position animated: animated];
		return;
	}
	
	if ( index == NSNotFound )
	{
		NSUInteger i = [_highlightedIndices firstIndex];
		while ( i != NSNotFound )
		{
			AQGridViewCell * cell = [self cellForItemAtIndex: i];
			[cell setHighlighted: NO animated: animated];
			i = [_highlightedIndices indexGreaterThanIndex: i];
		}
		
		[_highlightedIndices removeAllIndexes];
		return;
	}
	
	AQGridViewCell * cell = [self cellForItemAtIndex: index];
	[cell setHighlighted: YES animated: animated];
	[_highlightedIndices addIndex: index];
	
	if ( position != AQGridViewScrollPositionNone )
		[self scrollToItemAtIndex: index atScrollPosition: position animated: animated];
}

- (void) unhighlightItemAtIndex: (NSUInteger) index animated: (BOOL) animated
{
	if ( [_highlightedIndices containsIndex: index] == NO )
		return;
	
	[_highlightedIndices removeIndex: index];
	AQGridViewCell * cell = [self cellForItemAtIndex: index];
	if ( cell != nil )
		[cell setHighlighted: NO animated: animated];
}

- (void) _deselectItemAtIndex: (NSUInteger) index animated: (BOOL) animated notifyDelegate: (BOOL) notifyDelegate
{
	if ( _selectedIndex != index )
		return;
	
	if ( notifyDelegate && _flags.delegateWillDeselectItem )
		[self.delegate gridView: self willDeselectItemAtIndex: index];
	
	_selectedIndex = NSNotFound;
	[[self cellForItemAtIndex: index] setSelected: NO animated: animated];
	
	if ( notifyDelegate && _flags.delegateDidDeselectItem )
		[self.delegate gridView: self didDeselectItemAtIndex: index];
	
	if ( notifyDelegate )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: AQGridViewSelectionDidChangeNotification
															object: self];
	}
}

- (void) _selectItemAtIndex: (NSUInteger) index animated: (BOOL) animated
			 scrollPosition: (AQGridViewScrollPosition) position notifyDelegate: (BOOL) notifyDelegate
{
	if ( _selectedIndex == index )
		return;		// already selected this item
	
	if ( _selectedIndex != NSNotFound )
		[self _deselectItemAtIndex: _selectedIndex animated: animated notifyDelegate: NO];
	
	if ( _flags.allowsSelection == 0 )
		return;
	
	if ( notifyDelegate && _flags.delegateWillSelectItem )
		[self.delegate gridView: self willSelectItemAtIndex: index];
	
	_selectedIndex = index;
	[[self cellForItemAtIndex: index] setSelected: YES animated: animated];
	
	if ( position != AQGridViewScrollPositionNone )
		[self scrollToItemAtIndex: index atScrollPosition: position animated: animated];
	
	if ( notifyDelegate )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: AQGridViewSelectionDidChangeNotification
															object: self];
	}
	
	if ( notifyDelegate && _flags.delegateDidSelectItem )
		[self.delegate gridView: self didSelectItemAtIndex: index];
}

#pragma mark -
#pragma mark Appearance

- (UIView *) backgroundView
{
	return ( [[_backgroundView retain] autorelease] );
}

- (void) setBackgroundView: (UIView *) newView
{
	if ( newView == _backgroundView )
		return;
	
	[_backgroundView removeFromSuperview];
	[_backgroundView release];
	
	_backgroundView = [newView retain];
	_backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	CGRect frame = self.bounds;
	frame.size = self.contentSize;
	_backgroundView.frame = UIEdgeInsetsInsetRect( frame, self.contentInset );
	
	[self insertSubview: _backgroundView atIndex: 0];
	
	// this view is already laid out nicely-- no need to call -setNeedsLayout at all
}

- (UIColor *) separatorColor
{
	return ( [[_separatorColor retain] autorelease] );
}

- (void) setSeparatorColor: (UIColor *) color
{
	if ( color == _separatorColor )
		return;
	
	[color retain];
	[_separatorColor release];
	_separatorColor = color;
	
	for ( AQGridViewCell * cell in _visibleCells )
	{
		cell.separatorColor = _separatorColor;
	}
}

#pragma mark -
#pragma mark Touch Events

- (UIView *) _basicHitTest: (CGPoint) point withEvent: (UIEvent *) event
{
	// STUPID STUPID RAT CREATURES
	// ===========================
	//
	// Problem: we want to do a default hit-test without UIScrollView's processing getting in the way.
	// UIScrollView implements _defaultHitTest:withEvent: for this, but we can't call that due to it
	//  being a private API.
	// Instead, we have to manufacture a call to our super-super class here, grr
	Method method = class_getInstanceMethod( [UIView class], @selector(hitTest:withEvent:) );
	IMP imp = method_getImplementation( method );
	return ( (UIView *)imp(self, @selector(hitTest:withEvent:), point, event) ); // -[UIView hitTest:withEvent:]
}

- (BOOL) _canSelectItemContainingHitView: (UIView *) hitView
{
	if ( [hitView isKindOfClass: [UIControl class]] )
		return ( NO );
	
	if ( [[hitView superview] isKindOfClass: [AQGridViewCell class]] )
		return ( YES );
	
	if ( [hitView isKindOfClass: [AQGridViewCell class]] )
		return ( YES );
	
	return ( NO );
}

- (void) _gridViewDeferredTouchesBegan: (NSNumber *) indexNum
{
	if ( (self.dragging == NO) && (_flags.ignoreTouchSelect == 0) && (_pendingSelectionIndex != NSNotFound) )
		[self highlightItemAtIndex: _pendingSelectionIndex animated: NO scrollPosition: AQGridViewScrollPositionNone];
	//_pendingSelectionIndex = NSNotFound;
}

- (void) _userSelectItemAtIndex: (NSNumber *) indexNum
{
	NSUInteger index = [indexNum unsignedIntegerValue];
	[self unhighlightItemAtIndex: index animated: NO];
	if ( ([[self cellForItemAtIndex: index] isSelected]) && (self.requiresSelection == NO) )
		[self _deselectItemAtIndex: index animated: NO notifyDelegate: YES];
	else
		[self _selectItemAtIndex: index animated: NO scrollPosition: AQGridViewScrollPositionNone notifyDelegate: YES];
	_pendingSelectionIndex = NSNotFound;
}

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event
{
	_flags.ignoreTouchSelect = ([self isDragging] ? 1 : 0);
	
	UITouch * touch = [touches anyObject];
	_touchBeganPosition = [touch locationInView: nil];
	if ( (touch != nil) && (_pendingSelectionIndex == NSNotFound) )
	{
		CGPoint pt = [touch locationInView: self];
		UIView * hitView = [self _basicHitTest: pt withEvent: event];
		_touchedContentView = hitView;
		
		// unhighlight anything not here
		if ( hitView != self )
			[self highlightItemAtIndex: NSNotFound animated: NO scrollPosition: AQGridViewScrollPositionNone];
		
		if ( [self _canSelectItemContainingHitView: hitView] )
		{
			NSUInteger index = [self indexForItemAtPoint: pt];
			if ( index != NSNotFound )
			{
				if ( _flags.allowsSelection == 1 )
				{
					_pendingSelectionIndex = index;
					
					// NB: In UITableView:
					// if ( [self usesGestureRecognizers] && [self isDragging] ) skip next line
					[self performSelector: @selector(_gridViewDeferredTouchesBegan:)
							   withObject: [NSNumber numberWithUnsignedInteger: index]
							   afterDelay: 0.0];
				}
			}
		}
	}
	
	[super touchesBegan: touches withEvent: event];
}

- (void) _cancelContentTouchUsingEvent: (UIEvent *) event forced: (BOOL) forced
{
	static char * name = "_cancelContentTouchWithEvent:forced:";
	
	// more manual ObjC runtime calls...
	SEL selector = sel_getUid( name );
	objc_msgSend( self, selector, event, forced );
}

- (void) touchesMoved: (NSSet *) touches withEvent: (UIEvent *) event
{
	if ( _flags.ignoreTouchSelect == 0 )
	{
		[self _cancelContentTouchUsingEvent: event forced: NO];
		[self highlightItemAtIndex: NSNotFound animated: NO scrollPosition: AQGridViewScrollPositionNone];
		_flags.ignoreTouchSelect = 1;
		_touchedContentView = nil;
	}
	
	[super touchesMoved: touches withEvent: event];
}

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event
{
    [[self class] cancelPreviousPerformRequestsWithTarget: self
												 selector: @selector(_gridViewDeferredTouchesBegan:)
												   object: nil];
	
	UIView * hitView = [_touchedContentView retain];
	_touchedContentView = nil;
	
	[super touchesEnded: touches withEvent: event];
	if ( _touchedContentView != nil )
	{
		[hitView release];
		hitView = [_touchedContentView retain];
	}
	
	if ( [hitView superview] == nil )
	{
		[hitView release];
		hitView = nil;
	}
	
	// poor-man's goto
	do
	{
		if ( self.dragging )
			break;
		
		UITouch * touch = [touches anyObject];
		if ( touch == nil )
			break;
		
		CGPoint pt = [touch locationInView: self];
		if ( (hitView != nil) && ([self _canSelectItemContainingHitView: hitView] == NO) )
			break;
		
		if ( _pendingSelectionIndex != [self indexForItemAtPoint: pt] )
			break;
		
		if ( _flags.allowsSelection == 0 )
			break;
		
		// run this on the next runloop tick
		[self performSelector: @selector(_userSelectItemAtIndex:)
				   withObject: [NSNumber numberWithUnsignedInteger: _pendingSelectionIndex]
				   afterDelay: 0.0];
		
		[hitView release];
		
	} while (0);
	
	if ( _pendingSelectionIndex != NSNotFound )
		[self unhighlightItemAtIndex: _pendingSelectionIndex animated: NO];
	_pendingSelectionIndex = NSNotFound;
}

- (void) touchesCancelled: (NSSet *) touches withEvent: (UIEvent *) event
{
    _pendingSelectionIndex = NSNotFound;
    [self highlightItemAtIndex: NSNotFound animated: NO scrollPosition: AQGridViewScrollPositionNone];
    [super touchesCancelled: touches withEvent: event];
}

@end

#pragma mark -

@implementation AQGridView (AQCellGridMath)

- (NSUInteger) visibleCellListIndexForItemIndex: (NSUInteger) itemIndex
{
	return ( itemIndex - _visibleIndices.location );
}

@end

#pragma mark -

@implementation AQGridView (AQCellLayout)

- (void) updateGridViewBoundsForNewGridData: (AQGridViewData *) newGridData
{
	[self updateContentRectWithOldMaxY: CGRectGetMaxY(self.bounds) gridHeight: [newGridData heightForEntireGrid]];
}

- (void) updateVisibleGridCellsNow
{
	if ( _reloadingSuspendedCount > 0 )
		return;
	
	_reloadingSuspendedCount++;
	NSIndexSet * newVisibleIndices = [_gridData indicesOfCellsInRect: [self gridViewVisibleBounds]];
	
	NSUInteger beforeTest = (_visibleIndices.location == 0 ? NSNotFound : _visibleIndices.location - 1);
	NSUInteger afterTest = MIN(_visibleIndices.location+_visibleIndices.length, _gridData.numberOfItems);
	
	//NSLog( @"New Visible Indices = %@, _visibleIndices = %@", newVisibleIndices, NSStringFromRange(_visibleIndices) );
	
	// do we need to remove anything?
	if ( [newVisibleIndices countOfIndexesInRange: _visibleIndices] < _visibleIndices.length )
	{
        NSMutableIndexSet * indicesToRemove = [[NSMutableIndexSet alloc] initWithIndexesInRange: _visibleIndices];
        [indicesToRemove removeIndexes: newVisibleIndices];
        if ( [indicesToRemove aq_isSetContiguous] )
        {
            // nice simple optimized version
            // front or back?
            BOOL removeFromFront = NO;
            if ( [indicesToRemove containsIndex: _visibleIndices.location] )
                removeFromFront = YES;
            
            NSUInteger numToRemove = [indicesToRemove count];
            NSRange arrayRange = {0, 0};
			if ( removeFromFront )
				arrayRange = NSMakeRange(0, numToRemove);
			else
				arrayRange = NSMakeRange([_visibleCells count] - numToRemove, numToRemove);
			
			//NSLog( @"Removing cells in visible range: %@", NSStringFromRange(arrayRange) );
			
			// grab the removed cells (retains them)
			NSMutableArray * removedCells = [[[_visibleCells subarrayWithRange: arrayRange] mutableCopy] autorelease];
			
			// don't remove cells which are animating right now
			if ( self.animatingCells.count != 0 )
			{
				[removedCells removeObjectsInArray: self.animatingCells];
				numToRemove = [removedCells count];
				arrayRange.length = numToRemove;
			}
			
			// remove from the visible list
			[_visibleCells removeObjectsInRange: arrayRange];
			
			// trim the visible cell index range
			_visibleIndices.length -= numToRemove;
			
			if ( removeFromFront )
				_visibleIndices.location += numToRemove;
			
			// remove cells from superview
			[removedCells makeObjectsPerformSelector: @selector(removeFromSuperview)];
			
			// put them into the recycled cell list
			[self enqueueReusableCells: removedCells];
			
			// done removing cells
        }
		else
		{
			// we need to be much more thorough-- a large number of items have been removed from all over
			NSMutableArray * removedCells = [[_visibleCells mutableCopy] autorelease];
			if ( self.animatingCells.count != 0 )
				[removedCells removeObjectsInArray: self.animatingCells];
			
			// remove any cells which aren't animating to new positions
			[_visibleCells removeObjectsInArray: removedCells];
			[removedCells makeObjectsPerformSelector: @selector(removeFromSuperview)];
			[self enqueueReusableCells: removedCells];
			
			// update visible indices as appropriate-- brute force this time
			_visibleIndices.location = [newVisibleIndices firstIndex];
			_visibleIndices.length = [newVisibleIndices count];
			
			// load the new cells
			NSUInteger idx = [newVisibleIndices firstIndex];
			while ( idx != NSNotFound )
			{
				AQGridViewCell * cell = [self createPreparedCellForIndex: idx];
				[self delegateWillDisplayCell: cell atIndex: idx];
				[_visibleCells addObject: cell];
				idx = [newVisibleIndices indexGreaterThanIndex: idx];
			}
			
			[self layoutCellsInVisibleCellRange: NSMakeRange(0, [_visibleCells count])];
			
			// all done
		}
	}
	
	// no animations on automatic cell layout
	[UIView setAnimationsEnabled: NO];
	
	if ( (beforeTest != NSNotFound) && ([newVisibleIndices containsIndex: beforeTest]) )
	{
		// moving backwards
		NSMutableIndexSet * newIndices = [[newVisibleIndices mutableCopy] autorelease];
		
		// prune the ones we know about already, so we have a list of only the new ones
		[newIndices removeIndexesInRange: _visibleIndices];
		[newIndices removeIndexesInRange: _revealingIndices];
		
		// insert any new cells, in reverse order (so we always insert at index zero)
		NSUInteger idx = [newIndices lastIndex];
		while ( idx != NSNotFound )
		{
			AQGridViewCell * cell = [self createPreparedCellForIndex: idx];
			[self delegateWillDisplayCell: cell atIndex: idx];
			[_visibleCells insertObject: cell atIndex: _revealingIndices.length];
			
			idx = [newIndices indexLessThanIndex: idx];
		}
		
		// update the visibleCell index range
		_visibleIndices.length += [newIndices count];
		_visibleIndices.location = [newVisibleIndices firstIndex];
		
		// get the range of the new items
		NSRange newCellRange = NSMakeRange([newIndices firstIndex], [newIndices lastIndex] - [newIndices firstIndex] + 1);
		
		// map this range onto the current visible cell array
		newCellRange.location = MIN(newCellRange.location - _visibleIndices.location, 0);
		
		// now update their locations
		[self layoutCellsInVisibleCellRange: newCellRange];
	}
	else if ( (NSLocationInRange(afterTest, _visibleIndices) == NO) && ([newVisibleIndices containsIndex: afterTest]) )
	{
		// moving forwards
		NSMutableIndexSet * newIndices = [[newVisibleIndices mutableCopy] autorelease];
		
		// prune the ones we know about already, so we have a list of only the new ones
		[newIndices removeIndexesInRange: _visibleIndices];
		
		// insert any new cells in growing order, so we can always append
		NSUInteger idx = [newIndices firstIndex];
		while ( idx != NSNotFound )
		{
			AQGridViewCell * cell = [self createPreparedCellForIndex: idx];
			[self delegateWillDisplayCell: cell atIndex: idx];
			[_visibleCells addObject: cell];
			
			idx = [newIndices indexGreaterThanIndex: idx];
		}
		
		// update the visibleCell index range
		_visibleIndices.length += [newIndices count];
		_visibleIndices.location = [newVisibleIndices firstIndex];
		
		// get the range of the new items
		NSRange newCellRange = NSMakeRange([newIndices firstIndex], [newIndices lastIndex] - [newIndices firstIndex] + 1);
		
		// map this range onto the current visible cell array
		newCellRange.location -= _visibleIndices.location;
		
		// now update their locations
		[self layoutCellsInVisibleCellRange: newCellRange];
	}
	
	[UIView setAnimationsEnabled: YES];
	_reloadingSuspendedCount--;
}

- (void) layoutCellsInVisibleCellRange: (NSRange) range
{
	NSParameterAssert((range.location >= 0) && (range.location + range.length <= [_visibleCells count]));
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSUInteger idx = _visibleIndices.location + (range.location - _visibleIndices.location);
	NSArray * layoutList = [_visibleCells subarrayWithRange: range];
	for ( AQGridViewCell * cell in layoutList )
	{
		CGRect gridRect = [_gridData cellRectAtIndex: (_visibleIndices.location) + idx];
		CGRect cellFrame = cell.frame;
		
		[self delegateWillDisplayCell: cell atIndex: _visibleIndices.location + idx];
		
		cell.frame = [self fixCellFrame: cellFrame forGridRect: gridRect];
		cell.selected = (_visibleIndices.location + idx == _selectedIndex);
		
		idx++;
	}
	
	[pool drain];
}

- (void) layoutAllCells
{
	NSRange range = NSMakeRange(0, _visibleIndices.length);
	[self layoutCellsInVisibleCellRange: range];
}

- (CGRect) fixCellFrame: (CGRect) cellFrame forGridRect: (CGRect) gridRect
{
	if ( _flags.resizesCellWidths == 1 )
	{
		cellFrame = gridRect;
	}
	else
	{
		if ( cellFrame.size.width > gridRect.size.width )
			cellFrame.size.width = gridRect.size.width;
		if ( cellFrame.size.height > gridRect.size.height )
			cellFrame.size.height = gridRect.size.height;
		cellFrame.origin.x = gridRect.origin.x + floorf( (gridRect.size.width - cellFrame.size.width) * 0.5 );
		cellFrame.origin.y = gridRect.origin.y + floorf( (gridRect.size.height - cellFrame.size.height) * 0.5 );
	}
	
	// let the delegate update it if appropriate
	if ( _flags.delegateAdjustGridCellFrame )
		cellFrame = [self.delegate gridView: self adjustCellFrame: cellFrame withinGridCellFrame: gridRect];
	
	return ( cellFrame );
}

- (AQGridViewCell *) createPreparedCellForIndex: (NSUInteger) index usingGridData: (AQGridViewData *) gridData
{
	[UIView setAnimationsEnabled: NO];
	AQGridViewCell * cell = [_dataSource gridView: self cellForItemAtIndex: index];
	cell.separatorStyle = _flags.separatorStyle;
	
	cell.frame = [self fixCellFrame: cell.frame forGridRect: [gridData cellRectAtIndex: index]];
	if ( _backgroundView.superview == self )
		[self insertSubview: cell aboveSubview: _backgroundView];
	else
		[self insertSubview: cell atIndex: 0];
    [UIView setAnimationsEnabled: YES];
	return ( cell );
}

- (AQGridViewCell *) createPreparedCellForIndex: (NSUInteger) index
{
    return ( [self createPreparedCellForIndex: index usingGridData: _gridData] );
}

- (void) insertVisibleCell: (AQGridViewCell *) cell atIndex: (NSUInteger) visibleCellListIndex
{
	if ( visibleCellListIndex >= [_visibleCells count] )
		return;
	
	[_visibleCells insertObject: cell atIndex: visibleCellListIndex];
}

- (void) deleteVisibleCell: (AQGridViewCell *) cell atIndex: (NSUInteger) visibleCellListIndex appendingNewCell: (AQGridViewCell *) newCell
{
	if ( visibleCellListIndex >= [_visibleCells count] )
		return;
	
	[_visibleCells removeObjectAtIndex: visibleCellListIndex];
	[_visibleCells addObject: newCell];
}

- (void) ensureCellInVisibleList: (AQGridViewCell *) cell
{
	if ( [_visibleCells containsObject: cell] == NO )
		[_visibleCells addObject: cell];
	[_visibleCells sortUsingSelector: @selector(compareOriginAgainstCell:)];
}

- (void) animationWillRevealItemsAtIndices: (NSRange) indices
{
	_revealingIndices = indices;
}

@end

@implementation AQGridView (AQGridViewPrivate)

- (void) viewWillRotateToInterfaceOrientation: (UIInterfaceOrientation) orientation
{
	// to avoid cell pop-in or pop-out:
	// if we're switching to landscape, don't update cells until after the transition.
	// if we're switching to portrait, update cells first.
	if ( UIInterfaceOrientationIsLandscape(orientation) )
		_reloadingSuspendedCount++;
}

- (void) viewDidRotate
{
	if ( _reloadingSuspendedCount == 0 )
		return;
	
	if ( --_reloadingSuspendedCount == 0 )
		[self updateVisibleGridCellsNow];
}

@end

@implementation AQGridView (CellLocationDelegation)

- (void) delegateWillDisplayCell: (AQGridViewCell *) cell atIndex: (NSUInteger) index
{
	if ( cell.separatorStyle == AQGridViewCellSeparatorStyleSingleLine )
	{
		// determine which edges need a separator
		AQGridViewCellSeparatorEdge edge = 0;
		if ( (index % self.numberOfColumns) != self.numberOfColumns-1 )
		{
			edge |= AQGridViewCellSeparatorEdgeRight;
		}
		//if ( index <= (_gridData.numberOfItems - self.numberOfColumns) )
		{
			edge |= AQGridViewCellSeparatorEdgeBottom;
		}
		
		cell.separatorEdge = edge;
	}
	
	if ( _flags.delegateWillDisplayCell == 0 )
		return;
	
	[self.delegate gridView: self willDisplayCell: cell forItemAtIndex: index];
}

@end
