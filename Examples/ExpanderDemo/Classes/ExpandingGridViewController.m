/*
 * ExpandingGridViewController.h
 * Classes
 * 
 * Created by Jim Dovey on 16/8/2010.
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

#import "ExpandingGridViewController.h"
#import "ImageGridViewCell.h"

@implementation ExpandingGridViewController

- (void) dealloc
{
	[_imageNames release];
	[_expandedLocations release];
	[super dealloc];
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.gridView.autoresizesSubviews = YES;
	
	if ( _imageNames != nil )
		return;
	
	NSArray * paths = [NSBundle pathsForResourcesOfType: @"png" inDirectory: [[NSBundle mainBundle] bundlePath]];
	NSMutableArray * allNames = [[NSMutableArray alloc] init];
	
	for ( NSString * path in paths )
	{
		if ( [[path lastPathComponent] hasPrefix: @"AQ"] )
			continue;
		
		[allNames addObject: [path lastPathComponent]];
	}
	
	// sort alphabetically
	_imageNames = [[allNames sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)] copy];
	[allNames release];
	
	[self.gridView reloadData];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark Expansion Implementation

- (void) expandCellsFromRect: (CGRect) rect ofView: (UIView *) aView
{
	// ensure these bits aren't animated
	[UIView setAnimationsEnabled: NO];
	
	self.gridView.backgroundColor = [UIColor clearColor];
	
	// collect the visible cells' original locations in a new array
	NSArray * cells = [self.gridView visibleCells];
	
	NSMutableArray * locations = [[NSMutableArray alloc] initWithCapacity: [cells count]];
	for ( AQGridViewCell * cell in cells )
	{
		[locations addObject: [NSValue valueWithCGRect: cell.frame]];
	}
	
	_expandedLocations = [locations copy];
	
	// record the starting position
	_startingRect = [aView convertRect: rect toView: self.gridView];
	
	// mark that we'll need to expand
	_readyToExpand = YES;
	
	// re-enable any pending animations
	[UIView setAnimationsEnabled: YES];
}

- (void) viewDidAppear: (BOOL) animated
{
	[super viewDidAppear: animated];
	
	if ( _readyToExpand == NO )
		return;
	
	// move all the cells to their starting places
	NSArray * cells = [self.gridView visibleCells];
	
	for ( AQGridViewCell * cell in cells )
	{
		cell.frame = _startingRect;
	}
	
	[UIView beginAnimations: @"Expansion" context: NULL];
	[UIView setAnimationDuration: 1.0];
	
	self.gridView.backgroundColor = [UIColor blackColor];
	
	for ( NSUInteger i = 0; i < [_expandedLocations count]; i++ )
	{
		AQGridViewCell * cell = [cells objectAtIndex: i];
		CGRect newFrame = [[_expandedLocations objectAtIndex: i] CGRectValue];
		
		NSLog( @"Moving cell from %@ to %@", NSStringFromCGRect(cell.frame), NSStringFromCGRect(newFrame) );
		[cell setFrame: newFrame];
	}
	
	[UIView commitAnimations];
	
	_readyToExpand = NO;
}

#pragma mark -
#pragma mark Grid View Data Source

- (NSUInteger) numberOfItemsInGridView: (AQGridView *) aGridView
{
    return ( [_imageNames count] );
}

- (AQGridViewCell *) gridView: (AQGridView *) aGridView cellForItemAtIndex: (NSUInteger) index
{
    static NSString * PlainCellIdentifier = @"PlainCellIdentifier";
    
    ImageGridViewCell * cell = (ImageGridViewCell *)[self.gridView dequeueReusableCellWithIdentifier: PlainCellIdentifier];
	if ( cell == nil )
	{
		cell = [[[ImageGridViewCell alloc] initWithFrame: CGRectMake(0.0, 0.0, 200.0, 150.0) reuseIdentifier: PlainCellIdentifier] autorelease];
		cell.selectionGlowColor = [UIColor purpleColor];
	}
	
	cell.image = [UIImage imageNamed: [_imageNames objectAtIndex: index]];
    
    return ( cell );
}

- (CGSize) portraitGridCellSizeForGridView: (AQGridView *) aGridView
{
    return ( CGSizeMake(224.0, 168.0) );
}

@end
