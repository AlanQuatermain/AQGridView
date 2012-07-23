//
//  AQGridView+Hackery.h
//  AQGridView
//
//  Created by Evadne Wu on 7/23/12.
//
//

#import "AQGridView.h"

@interface AQGridView (Hackery)

- (UIView *) aqBasicHitTest:(CGPoint)point withEvent:(UIEvent *)event;
//	Works without additional stuff in UIScrollView

@end
