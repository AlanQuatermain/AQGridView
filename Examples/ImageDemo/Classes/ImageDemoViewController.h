//
//  ImageDemoViewController.h
//  ImageDemo
//
//  Created by Jim Dovey on 10-04-17.
//  Copyright Kobo Inc 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AQGridView.h"

@interface ImageDemoViewController : UIViewController <AQGridViewDelegate, AQGridViewDataSource>
{
    NSArray * _orderedImageNames;
    NSArray * _imageNames;
    AQGridView * _gridView;
}

@property (nonatomic, retain) IBOutlet AQGridView * gridView;

- (IBAction) shuffle;
- (IBAction) resetOrder;

@end

