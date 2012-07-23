//
//  AQGridView+Hackery.m
//  AQGridView
//
//  Created by Evadne Wu on 7/23/12.
//
//

#import "AQGridView+Hackery.h"


@interface UIScrollView (AQGridView_Hackery)

- (UIView *) aqBasicHitTest:(CGPoint)point withEvent:(UIEvent *)event;

@end


@implementation UIScrollView (AQGridView_Hackery)

- (UIView *) aqBasicHitTest:(CGPoint)point withEvent:(UIEvent *)event {

	return [super hitTest:point withEvent:event];

}

@end


@implementation AQGridView (Hackery)

- (UIView *) aqBasicHitTest:(CGPoint)point withEvent:(UIEvent *)event {

	return [super aqBasicHitTest:point withEvent:event];

}

@end
