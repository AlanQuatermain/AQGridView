/*
 * SpringBoardViewController.m
 * SpringBoard
 * 
 * Created by Jim Dovey on 23/4/2010.
 * 
 * Copyright (c) 2010 Jim Dovey
 * All rights reserved.
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

#import "SpringBoardViewController.h"
#import "AQGridView.h"
#import "SpringBoardIconCell.h"
#import "SpringBoardIcon.h"


@interface SpringBoardViewController ()

@property (nonatomic, readwrite, strong) NSArray *icons;
@property (nonatomic, readwrite, weak) AQGridView *gridView;
@property (nonatomic, readwrite, assign) NSUInteger emptyCellIndex;
@property (nonatomic, readwrite, assign) NSUInteger dragOriginIndex;
@property (nonatomic, readwrite, assign) CGPoint dragOriginCellOrigin;
@property (nonatomic, readwrite, strong) SpringBoardIconCell *draggingCell;

- (UIView *) newBackgroundView;

@end


@implementation SpringBoardViewController
@synthesize icons = _icons;
@synthesize gridView = _gridView;
@synthesize emptyCellIndex = _emptyCellIndex;
@synthesize dragOriginIndex = _dragOriginIndex;
@synthesize dragOriginCellOrigin = _dragOriginCellOrigin;
@synthesize draggingCell = _draggingCell;

- (NSArray *) icons {

	if (!_icons) {

		NSUInteger const numberOfColors = 20;
		NSMutableArray *icons = [NSMutableArray arrayWithCapacity:numberOfColors];

		CGFloat const saturation = 0.6f;
		CGFloat const brightness = 0.7f;
		CGFloat const alpha = 1.0f;
		
		for (NSUInteger i = 1; i <= 20; i++) {
		
			CGFloat const hue = (CGFloat)i/20.0f;
		
			UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
			
			[icons addObject:[SpringBoardIcon iconWithColor:color]];
			
		}
		
		_icons = icons;
	
	}
	
	return _icons;

}

- (UIView *) newBackgroundView {

	UIImageView *background = [[UIImageView alloc] initWithFrame: self.view.bounds];
	background.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	background.contentMode = UIViewContentModeCenter;
	background.image = [UIImage imageNamed: @"background.png"];
	
	return background;

}

- (void) viewDidLoad {

	[super viewDidLoad];
    
	_emptyCellIndex = NSNotFound;
    
	self.view.autoresizesSubviews = YES;
  
	[self.view addSubview:[self newBackgroundView]];
	[self gridView];
    
	UILongPressGestureRecognizer *gr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(moveActionGestureRecognizerStateChanged:)];
	gr.minimumPressDuration = 0.5;
	gr.delegate = self;
	[_gridView addGestureRecognizer:gr];
    
	[self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0.0f];
	[_gridView reloadData];

}

- (AQGridView *) gridView {

	if (!_gridView && [self isViewLoaded]) {
		
		AQGridView *gridView = [[AQGridView alloc] initWithFrame:self.view.bounds];
		gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		gridView.backgroundColor = [UIColor clearColor];
		gridView.opaque = NO;
		gridView.dataSource = self;
		gridView.delegate = self;
		gridView.scrollEnabled = NO;
	
		[self.view addSubview:gridView];
		
		_gridView = gridView;
	
	}
  
	return _gridView;

}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation {
	
	return YES;
	
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	AQGridView * const gv = self.gridView;

	if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
		
		//	width will be 768, which divides by four nicely already
		gv.leftContentInset = 0.0;
		gv.rightContentInset = 0.0;
		
	} else {
	
		// width will be 1024, so subtract a little to get a width divisible by five
		gv.leftContentInset = 2.0;
    gv.rightContentInset = 2.0;
		
	}
	
}

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {

	AQGridView * const gv = self.gridView;
	CGPoint const location = [gestureRecognizer locationInView:gv];
	return ([gv indexForItemAtPoint:location] < gv.numberOfItems);

}

- (void) moveActionGestureRecognizerStateChanged: (UIGestureRecognizer *) recognizer {
    switch ( recognizer.state )
    {
        default:
        case UIGestureRecognizerStateFailed:
            // do nothing
            break;
            
        case UIGestureRecognizerStatePossible:
        case UIGestureRecognizerStateCancelled:
        {
            [_gridView beginUpdates];
            
            if ( _emptyCellIndex != _dragOriginIndex )
            {
                [_gridView moveItemAtIndex: _emptyCellIndex toIndex: _dragOriginIndex withAnimation: AQGridViewItemAnimationFade];
            }
            
            _emptyCellIndex = _dragOriginIndex;
						
            // move the cell back to its origin
            [UIView beginAnimations: @"SnapBack" context: NULL];
            [UIView setAnimationCurve: UIViewAnimationCurveEaseOut];
            [UIView setAnimationDuration: 0.5];
            [UIView setAnimationDelegate: self];
            [UIView setAnimationDidStopSelector: @selector(finishedSnap:finished:context:)];
            
            CGRect f = _draggingCell.frame;
            f.origin = _dragOriginCellOrigin;
            _draggingCell.frame = f;
            
            [UIView commitAnimations];
            
            [_gridView endUpdates];
            
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        {
            CGPoint p = [recognizer locationInView: _gridView];
            NSUInteger index = [_gridView indexForItemAtPoint: p];
			if ( index == NSNotFound )
			{
				// index is the last available location
				index = [_icons count] - 1;
			}
            
						SpringBoardIcon *icon = [self.icons objectAtIndex:index];
						NSMutableArray *toIcons = [self.icons mutableCopy];
            [toIcons removeObject:icon];
            [toIcons insertObject:icon atIndex:index];
						self.icons = toIcons;
            
            if ( index != _emptyCellIndex )
            {
                [_gridView beginUpdates];
                [_gridView moveItemAtIndex: _emptyCellIndex toIndex: index withAnimation: AQGridViewItemAnimationFade];
                _emptyCellIndex = index;
                [_gridView endUpdates];
            }
            
            // move the real cell into place
            [UIView beginAnimations: @"SnapToPlace" context: NULL];
            [UIView setAnimationCurve: UIViewAnimationCurveEaseOut];
            [UIView setAnimationDuration: 0.5];
            [UIView setAnimationDelegate: self];
            [UIView setAnimationDidStopSelector: @selector(finishedSnap:finished:context:)];
            
            CGRect r = [_gridView rectForItemAtIndex: _emptyCellIndex];
            CGRect f = _draggingCell.frame;
            f.origin.x = r.origin.x + floorf((r.size.width - f.size.width) * 0.5);
            f.origin.y = r.origin.y + floorf((r.size.height - f.size.height) * 0.5) - _gridView.contentOffset.y;
            NSLog( @"Gesture ended-- moving to %@", NSStringFromCGRect(f) );
            _draggingCell.frame = f;
            
            _draggingCell.transform = CGAffineTransformIdentity;
            _draggingCell.alpha = 1.0;
            
            [UIView commitAnimations];
            break;
        }
            
        case UIGestureRecognizerStateBegan:
        {
            NSUInteger index = [_gridView indexForItemAtPoint: [recognizer locationInView: _gridView]];
            _emptyCellIndex = index;    // we'll put an empty cell here now
            
            // find the cell at the current point and copy it into our main view, applying some transforms
            AQGridViewCell * sourceCell = [_gridView cellForItemAtIndex: index];
            CGRect frame = [self.view convertRect: sourceCell.frame fromView: _gridView];
            _draggingCell = [[SpringBoardIconCell alloc] initWithFrame: frame reuseIdentifier: @""];
            _draggingCell.icon = [_icons objectAtIndex: index];
            [self.view addSubview: _draggingCell];
            
            // grab some info about the origin of this cell
            _dragOriginCellOrigin = frame.origin;
            _dragOriginIndex = index;
						
						[UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseInOut animations:^{
							
							_draggingCell.transform = CGAffineTransformMakeScale( 1.2, 1.2 );
							_draggingCell.alpha = 0.7;
							_draggingCell.center = [recognizer locationInView: self.view];

						} completion:^(BOOL finished) {
						
							if (!finished)
								return;
								
							//	FIXME
							
							[_gridView reloadItemsAtIndices: [NSIndexSet indexSetWithIndex: index]
																withAnimation: AQGridViewItemAnimationNone];
							
						}];
            
            break;
						
        }
            
        case UIGestureRecognizerStateChanged:
        {
            // update draging cell location
            _draggingCell.center = [recognizer locationInView: self.view];
            
            // don't do anything with content if grid view is in the middle of an animation block
            if ( _gridView.isAnimatingUpdates )
                break;
            
            // update empty cell to follow, if necessary
            NSUInteger index = [_gridView indexForItemAtPoint: [recognizer locationInView: _gridView]];
			
			// don't do anything if it's over an unused grid cell
			if ( index == NSNotFound )
			{
				// snap back to the last possible index
				index = [_icons count] - 1;
			}
			
            if ( index != _emptyCellIndex )
            {
                NSLog( @"Moving empty cell from %u to %u", _emptyCellIndex, index );
                
                // batch the movements
                [_gridView beginUpdates];
                
                // move everything else out of the way
                if ( index < _emptyCellIndex )
                {
                    for ( NSUInteger i = index; i < _emptyCellIndex; i++ )
                    {
                        NSLog( @"Moving %u to %u", i, i+1 );
                        [_gridView moveItemAtIndex: i toIndex: i+1 withAnimation: AQGridViewItemAnimationFade];
                    }
                }
                else
                {
                    for ( NSUInteger i = index; i > _emptyCellIndex; i-- )
                    {
                        NSLog( @"Moving %u to %u", i, i-1 );
                        [_gridView moveItemAtIndex: i toIndex: i-1 withAnimation: AQGridViewItemAnimationFade];
                    }
                }
                
                [_gridView moveItemAtIndex: _emptyCellIndex toIndex: index withAnimation: AQGridViewItemAnimationFade];
                _emptyCellIndex = index;
                
                [_gridView endUpdates];
            }
            
            break;
        }
    }
}

- (void) finishedSnap: (NSString *) animationID finished: (NSNumber *) finished context: (void *) context
{
    NSIndexSet * indices = [[NSIndexSet alloc] initWithIndex: _emptyCellIndex];
    _emptyCellIndex = NSNotFound;
    
    // load the moved cell into the grid view
    [_gridView reloadItemsAtIndices: indices withAnimation: AQGridViewItemAnimationNone];
    
    // dismiss our copy of the cell
    [_draggingCell removeFromSuperview];
    _draggingCell = nil;
    
}

#pragma mark -
#pragma mark GridView Data Source

- (NSUInteger) numberOfItemsInGridView:(AQGridView *)gridView {
	
	return [self.icons count];
	
}

- (AQGridViewCell *) gridView:(AQGridView *)gridView cellForItemAtIndex:(NSUInteger)index {

	static NSString * const CellIdentifier = @"CellIdentifier";

	SpringBoardIconCell * cell = (SpringBoardIconCell *)[gridView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (!cell) {

		cell = [[SpringBoardIconCell alloc] initWithFrame: CGRectMake(0.0, 0.0, 72.0, 72.0) reuseIdentifier:CellIdentifier];

	}

	cell.icon = [self.icons objectAtIndex:index];
	cell.alpha = (index == _emptyCellIndex) ? 0.0f : 1.0f;
	
	return cell;
	
}

- (CGSize) portraitGridCellSizeForGridView:(AQGridView *)gridView {
	
	return (CGSize){ 192.0f, 192.0f };
	
}

@end
