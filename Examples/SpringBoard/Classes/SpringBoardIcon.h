//
//  SpringBoardIcon.h
//  SpringBoard
//
//  Created by Evadne Wu on 8/18/12.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SpringBoardIcon : NSObject

+ (id) iconWithColor:(UIColor *)color;
- (id) initWithColor:(UIColor *)color;

@property (nonatomic, readonly, strong) UIColor *color;

@end
