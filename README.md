# AQGridView

*	Winner of the _Best Developer Tool/Helper_ award at iPadDevCamp 2010 in San Jose.
*	Originally written for the [Kobo iPad Application](http://itunes.apple.com/ca/app/ebooks-by-kobo/id301259483?mt=8).  
*	Latest stable version: Version 1.2 (10 January 2011).


## Introduction

`AQGridView` is an attempt to create something similar to `NSCollectionView` on the iPhone. If `CALayoutManager` were available on the iPhone, specifically the `CAConstraintLayoutManager`, then this would be relatively easy to put together. However, since none of those exist, there’s a lot of work to be done.

`AQGridView` is based around the programming model of `UITableView` and its associated classes. To create this class I looked long and hard at how `UITableView` does what it does, and attempted to replicate it as closely as possible. This means that if you are familiar with table view programming on the iPhone or iPad, you will find `AQGridView` simple to pick up.

### Requirements

*	`AQGridView` requires the iOS 5.0 SDK and is verified to work with iOS 6.0 beta seeds as well.


### Similarities with `UITableView`

*	A subclass of *UIScrollView*.
*	Reusable grid cells, similar to *UITableViewCell*.
*	Data source and delegate very similar to those used with UITableView.
*	Immediate and batched changes to the content list (insert, remove, reorder, reload).
*	Similar change animations (top, bottom, left, right, fade).
*	Simple `AQGridViewController` provided which performs grid view setup for you, similar to `UITableViewController`.
*	Support for custom header and footer views.

### Differences from `UITableView`

*	No sections — uses `NSUInteger` as its index location rather than `NSIndexPath`.
*	Data source can specify a desired minimum size for all grid cells.
*	Cells are not automatically resized to fit in layout grid-- this can be changed via a property.
*	The delegate gets an opportunity to adjust the layout frame for each cell as it is displayed.
*	The grid layout is adjusted to fit the contentSize width. You can specify left and/or right padding to reach a size which can be divided into three, five, etc. cells per row.
*	A customizable “glow” selection style, which places a glow around a cell’s layer, or a specified sublayer, using `-[CALayer shadowRadius]`.


## Overview

`AQGridView` has a number of supporting internal classes. The ones you’ll interact with directly are:

*	`AQGridView`
*	`AQGridViewCell`
*	`AQGridViewController`

###	Adopting AQGridView in your Xcode 4 project

1.	Grab the code.  Either clone the repo, download it as a zip, or add it as a Git sumodule.
	
2.	From Xcode, select “Add Files to ‘MY_PROJECT’”, select “AQGridView.xcodeproj.”  
	Leave **Add to Targets** checked.
	
3.	AQGridView should now appear in the **Project Navigator**.  
	Click on your project in the **Project Navigator**, then find your target.
	
4.	Go to **Build Phases**.  
	Add `AQGridView` to **Target Dependencies.**
	Add `libAQGridView.a` to **Link Binary with Libraries.**
	
5.	Go to **Build Settings**.
	Provide a path to AQGridView headers in **User Header Search Paths**.
	Add `-all_load -ObjC` to **Other Linker Flags**.

6.	Enjoy.

### Basic Setup

Create a subclass of `AQGridViewController`. In `-viewDidLoad`, you can change any properties you desire, add background, header, or footer views, and so on.

Unless you want a grid cell size of 96x128 (the default) you should implement `-[id<AQGridViewDataSource> portraitGridCellSizeForGridView]`, from which you can return a suitable **minimum** size for your cells. This is used as the basis of the layout grid; the grid view will expand the width of this size until it reaches a factor of the current content size, then uses that for its layout.

Cells will be placed in the center of each layout grid rectangle. By default, the cells are not resized to fill this grid rectangle, but you can change this using the `resizesCellWidthToFit` property on `AQGridView`.

If your cell should not be positioned dead center (for example, if your cell contains an image with a shadow on one side, and the *image* should be centered, not the whole thing) then you can implement `-[id<AQGridViewDelegate> gridView:adjustCellFrame:withinGridCellFrame:]` to tweak the auto-centered cell frame calculated by the grid view’s layout code.

For instance, the [Kobo iPad Application](http://itunes.apple.com/ca/app/ebooks-by-kobo-hd/id364742849?mt=8) does this for its shelf view, and uses `resizesCellWidthToFit` for its two-column list view.


##	Future Directions

### Section support

This will need a large amount of refactoring to support moves between sections, and will need a new way of keeping track of visible cell indices (it currently uses an `NSRange`).

###	High-performance rendering

If cells don’t need to update their content after being drawn, each row could be composited into a single view for reduced load on the Core Animation renderer  This would need support in the grid view for displaying these composited rows, and would also need special support in `AQGridViewCell` to mark individual cells as needing dynamic updates, so they could be skipped when compositing and displayed normally on top of the composited row.

KVO would be used to keep track of this. NB: This would also need special handling for the “glow” selection style (or possibly the tracking cell would always be placed on screen, regardless of its dynamism requirements).

### Content adjustments

There are possibly still a couple of deeply-buried bugs in the cell movement code inside `AQGridViewUpdateInfo`.  These are a pain to track down, and the code in that class could possibly use some cleanup. This is also something which would need to change a lot for section support (it makes heavy use of `NSIndexSet` right now).


## Known Bugs

*	Don’t try to pile multiple animations on top of one another. i.e. don't call `-beginUpdates` on a grid view whose `-isAnimatingUpdates` method returns `YES`. Bad things will happen, cells will end up in the wrong places, stacked on top of one another.


##	Examples

All examples are located in the `Examples` folder.

### ImageDemo

This is the demo which was presented at iPad Dev Camp in San Jose. It is primarily a showcase for automatic content reordering and animation, but also includes examples of the two main cell types: centered empty-space bordered cells, and filled line-separated cells.

Rotating the display will change the number of columns in the grid, with the associated animation. In addition, there are two buttons which cause items to be reordered. The top left button will shuffle the image order randomly, and the top right button will return everything to its original position.

The second button at the top right of the screen will pop up a menu which changes from the default empty-space grid style to a UITableView-like “filled cell” grid style. In this version, the cells are automatically resized to fit their grid slots, and the selection style (and the cells’ behavior when selected) will match UITableView more closely.

### SpringBoard

This is a new demo which shows how to use gesture recognizers to implement a manual reordering interface similar to that used by the iPad springboard. If you tap and hold on a cell for half a second, it will pop out of the grid, whereupon you can drag it around and drop it in a new position by letting go. The rest of the cells move out of the way as you drag your chosen cell around.

Additionally, it shows how to use the left and right insets to force the grid view to create the desired number of columns. In portrait mode, we want four columns, and the default width of 768 divides by four nicely, so we leave the insets at zero. In landscape mode we want five columns, and so we inset left & right by two pixels each to reduce the grid’s *layout* width to 1020 pixels, which is cleanly divisible by 5. As a result, rotating to landscape mode results in five columns being visible.

### ExpanderDemo

This demo shows how to make a new grid view instance expand into existence from a single point. The `ExpanderDemoViewController` implements a basic grid view with a single cell. When this cell is tapped, it creates a new instance of `ExpandingGridViewController`, which then expands its image cells into view (only using those cells which would be visible, not ALL cells).

The expansion is triggered by calling `-[ExpandingGridViewController expandCellsFromRect:ofView:]`.  Before calling this, you must set the expanding grid view’s frame (so it can figure out what cells should be visible at what indices) and add it to a superview (so the passed rectangle can be mapped across). Afterward, you should ensure that you call the new controller's `-viewDidAppear:`.  This last function implements the last part of the expansion algorithm.

In `-expandCellsFromRect:ofView:`, the controller converts the source rectangle into its own view's coordinate space and caches it. It also goes through the grid view’s cell list and stores their existing frames ready to animate them later. Lastly, it sets its view's background colour to clear. Then in `-viewDidAppear:` it first moves all the visible cells to the saved starting rectangle, then in an animation block it restores its background colour and moves the cells to their original positions.

Yes, this example contains a memory leak, and doesn't go in reverse. The only exemplary code is in the two methods discussed above.


## Apps using AQGridView

*	**[eBooks by Kobo](http://itunes.apple.com/ca/app/ebooks-by-kobo/id301259483?mt=8)**  
	Bookshelf and multi-column table views, “I’m Reading” overlay view.  
	
*	**[Netflix Actors](http://itunes.apple.com/us/app/actors-for-netflix/id377007136?mt=8)**  
	Source code [here](http://github.com/adrianco/Actors-for-Netflix-on-iPad).  
	Movie and actor chooser views.  
	
*	**[Stocks – The Finance App](http://itunes.apple.com/ca/app/stocks-the-finance-app/id373066200?mt=8)**  
	Portfolio view contents.  
	
*	**[Rivet for iPad](http://itunes.apple.com/ca/app/rivet-for-ipad/id375055319?mt=8)**  
	Media shelves.  
	
*	**[Slide By Slide](http://itunes.apple.com/us/app/slide-by-slide/id387580384?mt=8)**  
	Slideshow picker.  
	
*	**[AppStart for iPad](http://itunes.apple.com/ca/app/appstart-for-ipad/id408984648)**  
	App reviews and guides.
	
*	**[Slippy](http://itunes.apple.com/app/id408254506)**  
	Level chooser.

*	**[Equineline Sales Catalog](http://itunes.apple.com/us/app/equineline-sales-catalog/id440355734?mt=8&ls=1)**  
	Bookshelf view.  
	
* 	**[Completion](http://www.completionapp.com)**  
	Springboard-style home screen.

##	Authors

*	**Jim Dovey** (<mailto:jimdovey@mac.com>)

### Supporting `AQGridView`

People have asked how they can show their support. Other than implementing nice features & pushing them back upstream, you can always take a look at my [Amazon Wish List](http://amzn.com/w/34WILFNNUUDKQ).
