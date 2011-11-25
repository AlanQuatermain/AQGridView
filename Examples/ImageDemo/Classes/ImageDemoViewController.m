/*
 * ImageDemoViewController.m
 * Classes
 * 
 * Created by Jim Dovey on 17/4/2010.
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

#import "ImageDemoViewController.h"
#import "ImageDemoGridViewCell.h"
#import "ImageDemoFilledCell.h"

enum
{
    ImageDemoCellTypePlain,
    ImageDemoCellTypeFill,
    ImageDemoCellTypeOffset
};

@implementation ImageDemoViewController

@synthesize gridView=_gridView;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.gridView.autoresizesSubviews = YES;
	self.gridView.delegate = self;
	self.gridView.dataSource = self;
    
    ImageDemoCellChooser * chooser = [[ImageDemoCellChooser alloc] initWithItemTitles: [NSArray arrayWithObjects: NSLocalizedString(@"Plain", @""), NSLocalizedString(@"Filled", @""), nil]];
    chooser.delegate = self;
    _menuPopoverController = [[UIPopoverController alloc] initWithContentViewController: chooser];
    
    if ( _orderedImageNames != nil )
        return;
    
    NSArray * paths = [NSBundle pathsForResourcesOfType: @"png" inDirectory: [[NSBundle mainBundle] bundlePath]];
    NSMutableArray * allImageNames = [[NSMutableArray alloc] init];
    
    for ( NSString * path in paths )
    {
        if ( [[path lastPathComponent] hasPrefix: @"AQ"] )
            continue;
        
        [allImageNames addObject: [path lastPathComponent]];
    }
    
    // sort alphabetically
    _orderedImageNames = [[allImageNames sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)] copy];
    _imageNames = [_orderedImageNames copy];
    
    
    [self.gridView reloadData];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
    return YES;
}

- (void) viewDidUnload
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
    self.gridView = nil;
     _menuPopoverController = nil;
}


- (IBAction) shuffle
{
    NSMutableArray * sourceArray = [_imageNames mutableCopy];
    NSMutableArray * destArray = [[NSMutableArray alloc] initWithCapacity: [sourceArray count]];
    
    [self.gridView beginUpdates];
    
    srandom( time(NULL) );
    while ( [sourceArray count] != 0 )
    {
        NSUInteger index = (NSUInteger)(random() % [sourceArray count]);
        id item = [sourceArray objectAtIndex: index];
        
        // queue the animation
        [self.gridView moveItemAtIndex: [_imageNames indexOfObject: item]
                               toIndex: [destArray count]
                         withAnimation: AQGridViewItemAnimationFade];
        
        // modify source & destination arrays
        [destArray addObject: item];
        [sourceArray removeObjectAtIndex: index];
    }
    
    _imageNames = [destArray copy];
    
    [self.gridView endUpdates];
    
}

- (IBAction) resetOrder
{
    [self.gridView beginUpdates];
    
    NSUInteger index, count = [_orderedImageNames count];
    for ( index = 0; index < count; index++ )
    {
        NSUInteger oldIndex = [_imageNames indexOfObject: [_orderedImageNames objectAtIndex: index]];
        if ( oldIndex == index )
            continue;       // no changes for this item
        
        [self.gridView moveItemAtIndex: oldIndex toIndex: index withAnimation: AQGridViewItemAnimationFade];
    }
    
    [self.gridView endUpdates];
    
    _imageNames = [_orderedImageNames copy];
}

- (IBAction) displayCellTypeMenu: (UIBarButtonItem *) sender
{
    if ( [_menuPopoverController isPopoverVisible] )
        [_menuPopoverController dismissPopoverAnimated: YES];
    
    [_menuPopoverController presentPopoverFromBarButtonItem: sender
                                   permittedArrowDirections: UIPopoverArrowDirectionUp
                                                   animated: YES];
}

- (IBAction) toggleLayoutDirection: (UIBarButtonItem *) sender
{
	switch ( _gridView.layoutDirection )
	{
		default:
		case AQGridViewLayoutDirectionVertical:
			sender.title = NSLocalizedString(@"Horizontal Layout", @"");
			_gridView.layoutDirection = AQGridViewLayoutDirectionHorizontal;
			break;
			
		case AQGridViewLayoutDirectionHorizontal:
			sender.title = NSLocalizedString(@"Vertical Layout", @"");
			_gridView.layoutDirection = AQGridViewLayoutDirectionVertical;
			break;
	}
	
	// force the grid view to reflow
	CGRect bounds = CGRectZero;
	bounds.size = _gridView.frame.size;
	_gridView.bounds = bounds;
	[_gridView setNeedsLayout];
}

- (void) cellChooser: (ImageDemoCellChooser *) chooser selectedItemAtIndex: (NSUInteger) index
{
    if ( index != _cellType )
    {
        _cellType = index;
        switch ( _cellType )
        {
            case ImageDemoCellTypePlain:
                self.gridView.separatorStyle = AQGridViewCellSeparatorStyleEmptySpace;
                self.gridView.resizesCellWidthToFit = NO;
                self.gridView.separatorColor = nil;
                break;
                
            case ImageDemoCellTypeFill:
                self.gridView.separatorStyle = AQGridViewCellSeparatorStyleSingleLine;
                self.gridView.resizesCellWidthToFit = YES;
                self.gridView.separatorColor = [UIColor colorWithWhite: 0.85 alpha: 1.0];
                break;
                
            default:
                break;
        }
        
        [self.gridView reloadData];
    }
    
    [_menuPopoverController dismissPopoverAnimated: YES];
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
    static NSString * FilledCellIdentifier = @"FilledCellIdentifier";
    //static NSString * OffsetCellIdentifier = @"OffsetCellIdentifier";
    
    AQGridViewCell * cell = nil;
    
    switch ( _cellType )
    {
        case ImageDemoCellTypePlain:
        {
            ImageDemoGridViewCell * plainCell = (ImageDemoGridViewCell *)[aGridView dequeueReusableCellWithIdentifier: PlainCellIdentifier];
            if ( plainCell == nil )
            {
                plainCell = [[ImageDemoGridViewCell alloc] initWithFrame: CGRectMake(0.0, 0.0, 200.0, 150.0)
                                                     reuseIdentifier: PlainCellIdentifier];
                plainCell.selectionGlowColor = [UIColor blueColor];
            }
            
            plainCell.image = [UIImage imageNamed: [_imageNames objectAtIndex: index]];
            
            cell = plainCell;
            break;
        }
            
        case ImageDemoCellTypeFill:
        {
            ImageDemoFilledCell * filledCell = (ImageDemoFilledCell *)[aGridView dequeueReusableCellWithIdentifier: FilledCellIdentifier];
            if ( filledCell == nil )
            {
                filledCell = [[ImageDemoFilledCell alloc] initWithFrame: CGRectMake(0.0, 0.0, 200.0, 150.0)
                                                         reuseIdentifier: FilledCellIdentifier];
                filledCell.selectionStyle = AQGridViewCellSelectionStyleBlueGray;
            }
            
            filledCell.image = [UIImage imageNamed: [_imageNames objectAtIndex: index]];
            filledCell.title = [[_imageNames objectAtIndex: index] stringByDeletingPathExtension];
            
            cell = filledCell;
            break;
        }
            
        default:
            break;
    }
    
    return ( cell );
}

- (CGSize) portraitGridCellSizeForGridView: (AQGridView *) aGridView
{
    return ( CGSizeMake(224.0, 168.0) );
}

#pragma mark -
#pragma mark Grid View Delegate

// nothing here yet

@end
