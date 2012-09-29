//
//  SpringBoardIcon.m
//  SpringBoard
//
//  Created by Evadne Wu on 8/18/12.
//
//

#import "SpringBoardIcon.h"


@implementation SpringBoardIcon
@synthesize color = _color;

+ (id) iconWithColor:(UIColor *)color {

	return [[self alloc] initWithColor:color];

}

- (id) initWithColor:(UIColor *)color {

	self = [super init];
	if (!self)
		return nil;
	
	_color = color;
	
	return self;

}

- (id) init {

	return [self initWithColor:nil];

}

@end
