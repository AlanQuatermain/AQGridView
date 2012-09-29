/*
 * SpringBoardIconCell.m
 * SpringBoard
 * 
 * Created by Jim Dovey on 23/4/2010.
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

#import <QuartzCore/QuartzCore.h>
#import "SpringBoardIconCell.h"
#import "SpringBoardIcon.h"


@interface SpringBoardIconCell ()
@property (nonatomic, readonly, weak) UIView *iconView;
@end


@implementation SpringBoardIconCell
@synthesize icon = _icon;
@synthesize iconView = _iconView;

- (id) initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {

	self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier];
	if (!self)
		return nil;
	
	[self iconView];
	
	self.backgroundColor = [UIColor clearColor];
	self.contentView.backgroundColor = [UIColor clearColor];
	self.contentView.opaque = NO;
	self.opaque = NO;
	self.selectionStyle = AQGridViewCellSelectionStyleNone;
	
	return self;
	
}

- (UIView *) iconView {

	if (!_iconView) {
	
		UIView *iconView = [[UIView  alloc] initWithFrame:CGRectMake(0.0, 0.0, 72.0, 72.0)];
		iconView.backgroundColor = [UIColor clearColor];
		iconView.opaque = NO;
		
		UIBezierPath * path = [UIBezierPath bezierPathWithRoundedRect:iconView.bounds cornerRadius:18.0f];
		
		iconView.layer.cornerRadius = 20.0f;
		iconView.layer.shadowPath = path.CGPath;
		iconView.layer.shadowRadius = 20.0;
		iconView.layer.shadowOpacity = 0.4;
		iconView.layer.shadowOffset = (CGSize){ 20.0f, 20.0f };

		[self.contentView addSubview:iconView];
	
		_iconView = iconView;
	
	}
	
	return _iconView;

}

- (void) setIcon:(SpringBoardIcon *)icon {

	if (_icon == icon)
		return;
		
	_icon = icon;
	
	self.iconView.backgroundColor = _icon.color;

}

@end
