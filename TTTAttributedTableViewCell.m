// TTTAttributedTableViewCell.m
//
// Copyright (c) 2011 Adam Ernst (http://adamernst.com)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "TTTAttributedTableViewCell.h"
#import "TTTAttributedLabel.h"

@implementation TTTAttributedTableViewCell

@synthesize attributedLabel=_attributedLabel;
@synthesize attributedLabelEdgeInsets=_attributedLabelEdgeInsets;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        _attributedLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        [_attributedLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [_attributedLabel setLineBreakMode:UILineBreakModeWordWrap];
        [_attributedLabel setBackgroundColor:[self backgroundColor]];
        [_attributedLabel setNumberOfLines:0];
        // If the label clips to its bounds, it looks weird when animating a row
        // to a new height (such as on an accessory change).
        [_attributedLabel setClipsToBounds:NO];
        [[self contentView] addSubview:_attributedLabel];
        
        _attributedLabelEdgeInsets = UIEdgeInsetsMake(12, 12, 12, 12);
    }
    return self;
}

- (void)dealloc {
    [_attributedLabel release];
    [super dealloc];
}

- (void)prepareForReuse {
    [[self attributedLabel] setText:nil];
}

- (void)setAttributedLabelEdgeInsets:(UIEdgeInsets)attributedLabelEdgeInsets {
    _attributedLabelEdgeInsets = attributedLabelEdgeInsets;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [_attributedLabel setFrame:UIEdgeInsetsInsetRect([[self contentView] bounds], [self attributedLabelEdgeInsets])];
    NSLog(@"Layout subviews, frame is %@", NSStringFromCGRect(_attributedLabel.frame));
}

- (CGFloat)heightForTableView:(UITableView *)tableView {
    CGFloat styleMargin = ([tableView style] == UITableViewStyleGrouped) ? 10.0f : 0.0f;
    
    [self setEditing:[tableView isEditing] animated:NO];
    [self setFrame:CGRectMake(0, 0, [tableView bounds].size.width - styleMargin * 2, 44)];
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    CGFloat height = [_attributedLabel sizeThatFits:CGSizeMake([_attributedLabel bounds].size.width, CGFLOAT_MAX)].height;
    height += [self attributedLabelEdgeInsets].top + [self attributedLabelEdgeInsets].bottom;
    // Grouped style does not respect UITableViewCellSeparatorStyleNone.
    if ([tableView separatorStyle] != UITableViewCellSeparatorStyleNone || [tableView style] == UITableViewStyleGrouped) {
        height += 1.0f;
    }
    return height;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    [_attributedLabel setBackgroundColor:backgroundColor];
}

@end
