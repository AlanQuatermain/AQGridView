//
//  ImageDemoAppDelegate.h
//  ImageDemo
//
//  Created by Jim Dovey on 10-04-17.
//  Copyright Kobo Inc 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImageDemoViewController;

@interface ImageDemoAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    ImageDemoViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ImageDemoViewController *viewController;

@end

