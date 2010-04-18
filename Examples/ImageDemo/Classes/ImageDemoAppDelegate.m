//
//  ImageDemoAppDelegate.m
//  ImageDemo
//
//  Created by Jim Dovey on 10-04-17.
//  Copyright Kobo Inc 2010. All rights reserved.
//

#import "ImageDemoAppDelegate.h"
#import "ImageDemoViewController.h"

@implementation ImageDemoAppDelegate

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];

	return YES;
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
