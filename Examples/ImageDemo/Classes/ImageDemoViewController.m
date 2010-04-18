//
//  ImageDemoViewController.m
//  ImageDemo
//
//  Created by Jim Dovey on 10-04-17.
//  Copyright Kobo Inc 2010. All rights reserved.
//

#import "ImageDemoViewController.h"
#import "ImageDemoGridViewCell.h"

static const int kImageViewTag = 'imgv';

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
    
    [allImageNames release];
    
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
}

- (void) dealloc
{
    [_gridView release];
    [_imageNames release];
    [_orderedImageNames release];
    [super dealloc];
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
    
    [_imageNames release];
    _imageNames = [destArray copy];
    
    [self.gridView endUpdates];
    
    [sourceArray release];
    [destArray release];
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
    
    [_imageNames release];
    _imageNames = [_orderedImageNames copy];
}

#pragma mark -
#pragma mark Grid View Data Source

- (NSUInteger) numberOfItemsInGridView: (AQGridView *) aGridView
{
    return ( [_imageNames count] );
}

- (AQGridViewCell *) gridView: (AQGridView *) aGridView cellForItemAtIndex: (NSUInteger) index
{
    static NSString * CellIdentifier = @"CellIdentifier";
    
    ImageDemoGridViewCell * cell = (ImageDemoGridViewCell *)[aGridView dequeueReusableCellWithIdentifier: CellIdentifier];
    if ( cell == nil )
    {
        cell = [[[ImageDemoGridViewCell alloc] initWithFrame: CGRectMake(0.0, 0.0, 200.0, 150.0)
                                             reuseIdentifier: CellIdentifier] autorelease];
        cell.selectionGlowColor = [UIColor blueColor];
    }
    
    cell.image = [UIImage imageNamed: [_imageNames objectAtIndex: index]];
    
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
