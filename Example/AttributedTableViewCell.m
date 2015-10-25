// AttributedTableViewCell.m
//
// Copyright (c) 2011 Mattt Thompson (http://mattt.me)
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

#import <QuartzCore/QuartzCore.h>
#import "AttributedTableViewCell.h"
#import "TTTAttributedLabel.h"

static CGFloat const kEspressoDescriptionTextFontSize = 17;

static inline NSRegularExpression * NameRegularExpression() {
    static NSRegularExpression *_nameRegularExpression = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _nameRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"^\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
    });
    
    return _nameRegularExpression;
}

static inline NSRegularExpression * ParenthesisRegularExpression() {
    static NSRegularExpression *_parenthesisRegularExpression = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _parenthesisRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"\\([^\\(\\)]+\\)" options:NSRegularExpressionCaseInsensitive error:nil];
    });
    
    return _parenthesisRegularExpression;
}

@implementation AttributedTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    
    self.summaryLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    self.summaryLabel.font = [UIFont systemFontOfSize:kEspressoDescriptionTextFontSize];
    self.summaryLabel.textColor = [UIColor darkGrayColor];
    self.summaryLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.summaryLabel.numberOfLines = 0;
    self.summaryLabel.linkAttributes = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleDouble)};
    
    NSMutableDictionary *mutableActiveLinkAttributes = [NSMutableDictionary dictionary];
    mutableActiveLinkAttributes[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleThick);
    mutableActiveLinkAttributes[NSForegroundColorAttributeName] = [UIColor blueColor];
    mutableActiveLinkAttributes[NSBackgroundColorAttributeName] = [UIColor yellowColor];
    self.summaryLabel.activeLinkAttributes = mutableActiveLinkAttributes;
    
    self.summaryLabel.highlightedTextColor = [UIColor whiteColor];
    self.summaryLabel.shadowColor = [UIColor colorWithWhite:0.87f alpha:1.0f];
    self.summaryLabel.shadowOffset = CGSizeMake(0.5f, 1.0f);
    
    [self.contentView addSubview:self.summaryLabel];
    
    self.isAccessibilityElement = NO;
    
    return self;
}

- (void)setSummaryText:(NSString *)text {
    _summaryText = [text copy];
    
    self.summaryLabel.attributedText = [self attributedSummaryText];
    
    NSRegularExpression *regexp = NameRegularExpression();
    NSRange linkRange = [regexp rangeOfFirstMatchInString:_summaryText options:0 range:NSMakeRange(0, self.summaryText.length)];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://en.wikipedia.org/wiki/%@", [self.summaryText substringWithRange:linkRange]]];
    [self.summaryLabel addLinkToURL:url withRange:linkRange];
}

- (NSAttributedString *) attributedSummaryText {
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:_summaryText];
    
    NSRange stringRange = NSMakeRange(0, [mutableAttributedString length]);

    NSRegularExpression *regexp = NameRegularExpression();
    NSRange nameRange = [regexp rangeOfFirstMatchInString:[mutableAttributedString string] options:0 range:stringRange];
    UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:kEspressoDescriptionTextFontSize];

    [mutableAttributedString removeAttribute:NSFontAttributeName range:nameRange];
    [mutableAttributedString addAttribute:NSFontAttributeName value:boldSystemFont range:nameRange];

    [mutableAttributedString replaceCharactersInRange:nameRange withString:[[[mutableAttributedString string] substringWithRange:nameRange] uppercaseString]];

    regexp = ParenthesisRegularExpression();
    [regexp enumerateMatchesInString:[mutableAttributedString string] options:0 range:stringRange usingBlock:^(NSTextCheckingResult *result, __unused NSMatchingFlags flags, __unused BOOL *stop) {
        UIFont *italicSystemFont = [UIFont italicSystemFontOfSize:kEspressoDescriptionTextFontSize];
        [mutableAttributedString removeAttribute:NSFontAttributeName range:result.range];
        [mutableAttributedString addAttribute:NSFontAttributeName value:italicSystemFont range:result.range];

        [mutableAttributedString removeAttribute:(NSString *)NSForegroundColorAttributeName range:result.range];
        [mutableAttributedString addAttribute:(NSString *)NSForegroundColorAttributeName value:[UIColor grayColor] range:result.range];
    }];

    return mutableAttributedString;
}

+ (CGFloat)heightForCellWithText:(NSString *)text availableWidth:(CGFloat)availableWidth {
    static CGFloat padding = 10.0;

    UIFont *systemFont = [UIFont systemFontOfSize:kEspressoDescriptionTextFontSize];
    CGSize textSize = CGSizeMake(availableWidth - (2 * padding) - 26, CGFLOAT_MAX); // rough accessory size
    CGSize sizeWithFont = [text sizeWithFont:systemFont constrainedToSize:textSize lineBreakMode:NSLineBreakByWordWrapping];

#if defined(__LP64__) && __LP64__
    return ceil(sizeWithFont.height) + padding;
#else
    return ceilf(sizeWithFont.height) + padding;
#endif
}

#pragma mark - UIView

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.hidden = YES;
    self.detailTextLabel.hidden = YES;
        
    self.summaryLabel.frame = CGRectOffset(CGRectInset(self.bounds, 20.0f, 5.0f), -10.0f, 0.0f);
    
    [self setNeedsDisplay];
}

#pragma mark - UIAccessibilityContainer

- (NSInteger)accessibilityElementCount {
    return 1;
}

- (id)accessibilityElementAtIndex:(__unused NSInteger)index {
    return self.summaryLabel;
}

- (NSInteger)indexOfAccessibilityElement:(__unused id)element {
    return 0;
}

@end
