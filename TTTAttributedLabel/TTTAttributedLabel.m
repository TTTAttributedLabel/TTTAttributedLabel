// TTTAttributedLabel.m
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

#import "TTTAttributedLabel.h"

#import <QuartzCore/QuartzCore.h>
#import <Availability.h>
#import <objc/runtime.h>

#define kTTTLineBreakWordWrapTextWidthScalingFactor (M_PI / M_E)

static inline CGFLOAT_TYPE CGFloat_sqrt(CGFLOAT_TYPE cgfloat) {
#if CGFLOAT_IS_DOUBLE
    return sqrt(cgfloat);
#else
    return sqrtf(cgfloat);
#endif
}

@interface TTTAccessibilityElement : UIAccessibilityElement
@property (nonatomic, weak) UIView *superview;
@property (nonatomic, assign) CGRect boundingRect;
@end

@implementation TTTAccessibilityElement

- (CGRect)accessibilityFrame {
    return UIAccessibilityConvertFrameToScreenCoordinates(self.boundingRect, self.superview);
}

@end

@interface TTTAttributedLabel ()
@property (readwrite, nonatomic, copy) NSAttributedString *inactiveAttributedText;
@property (readwrite, atomic, strong) NSDataDetector *dataDetector;
@property (readwrite, nonatomic, strong) NSArray *linkModels;
@property (readwrite, nonatomic, strong) TTTAttributedLabelLink *activeLink;
@property (readwrite, nonatomic, strong) NSArray *accessibilityElements;

@property (nonatomic, strong) NSTextStorage *textStorage;
@property (nonatomic, strong) NSLayoutManager *layoutManager;
@property (nonatomic, strong) NSTextContainer *textContainer;

- (void) longPressGestureDidFire:(UILongPressGestureRecognizer *)sender;
@end

@implementation TTTAttributedLabel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    [self commonInit];

    return self;
}

- (void)commonInit {
    self.userInteractionEnabled = YES;
#if !TARGET_OS_TV
    self.multipleTouchEnabled = NO;
#endif

    self.linkModels = @[];

    self.textStorage = [[NSTextStorage alloc] init];
    self.layoutManager = [[NSLayoutManager alloc] init];
    [self.textStorage addLayoutManager:self.layoutManager];
    self.textContainer = [[NSTextContainer alloc] initWithSize:self.bounds.size];
    self.textContainer.lineFragmentPadding  = 0;
    self.textContainer.maximumNumberOfLines = self.numberOfLines;
    self.textContainer.lineBreakMode = self.lineBreakMode;

    [self.layoutManager addTextContainer:self.textContainer];

    self.linkAttributes = @{NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle), NSForegroundColorAttributeName : [UIColor blueColor]};
    self.activeLinkAttributes = @{NSUnderlineStyleAttributeName : @(NSUnderlineStyleNone), NSForegroundColorAttributeName : [UIColor redColor]};
    self.inactiveLinkAttributes = @{NSUnderlineStyleAttributeName : @(NSUnderlineStyleNone), NSForegroundColorAttributeName : [UIColor purpleColor]};
    
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(longPressGestureDidFire:)];
    self.longPressGestureRecognizer.delegate = self;
    [self addGestureRecognizer:self.longPressGestureRecognizer];
}

#pragma mark -

- (NSArray *) links {
    return [_linkModels valueForKey:@"result"];
}

- (void)setLinkModels:(NSArray *)linkModels {
    _linkModels = linkModels;
    
    self.accessibilityElements = nil;
}

#pragma mark -

- (NSTextCheckingTypes)dataDetectorTypes {
    return self.enabledTextCheckingTypes;
}

- (void)setDataDetectorTypes:(NSTextCheckingTypes)dataDetectorTypes {
    self.enabledTextCheckingTypes = dataDetectorTypes;
}

- (void)setEnabledTextCheckingTypes:(NSTextCheckingTypes)enabledTextCheckingTypes {
    if (self.enabledTextCheckingTypes == enabledTextCheckingTypes) {
        return;
    }
    
    _enabledTextCheckingTypes = enabledTextCheckingTypes;

    // one detector instance per type (combination), fast reuse e.g. in cells
    static NSMutableDictionary *dataDetectorsByType = nil;

    if (!dataDetectorsByType) {
        dataDetectorsByType = [NSMutableDictionary dictionary];
    }
    
    if (enabledTextCheckingTypes) {
        if (!dataDetectorsByType[@(enabledTextCheckingTypes)]) {
            NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:enabledTextCheckingTypes
                                                                       error:nil];
            if (detector) {
                dataDetectorsByType[@(enabledTextCheckingTypes)] = detector;
            }
        }
        self.dataDetector = dataDetectorsByType[@(enabledTextCheckingTypes)];
    } else {
        self.dataDetector = nil;
    }
}

- (void)addLink:(TTTAttributedLabelLink *)link {
    [self addLinks:@[link]];
}

- (void)addLinks:(NSArray *)links {
    NSMutableArray *mutableLinkModels = [NSMutableArray arrayWithArray:self.linkModels];
    
    NSMutableAttributedString *mutableAttributedString = [self.attributedText mutableCopy];

    for (TTTAttributedLabelLink *link in links) {
        if (link.attributes) {
            [mutableAttributedString addAttributes:link.attributes range:link.result.range];
        }
    }

    self.attributedText = mutableAttributedString;
    [self setNeedsDisplay];

    [mutableLinkModels addObjectsFromArray:links];
    
    self.linkModels = [NSArray arrayWithArray:mutableLinkModels];
}

- (TTTAttributedLabelLink *)addLinkWithTextCheckingResult:(NSTextCheckingResult *)result
                                               attributes:(NSDictionary *)attributes
{
    return [self addLinksWithTextCheckingResults:@[result] attributes:attributes].firstObject;
}

- (NSArray *)addLinksWithTextCheckingResults:(NSArray *)results
                                  attributes:(NSDictionary *)attributes
{
    NSMutableArray *links = [NSMutableArray array];
    
    for (NSTextCheckingResult *result in results) {
        NSDictionary *activeAttributes = attributes ? self.activeLinkAttributes : nil;
        NSDictionary *inactiveAttributes = attributes ? self.inactiveLinkAttributes : nil;
        
        TTTAttributedLabelLink *link = [[TTTAttributedLabelLink alloc] initWithAttributes:attributes
                                                                         activeAttributes:activeAttributes
                                                                       inactiveAttributes:inactiveAttributes
                                                                       textCheckingResult:result];
        
        [links addObject:link];
    }
    
    [self addLinks:links];
    
    return links;
}

- (TTTAttributedLabelLink *)addLinkWithTextCheckingResult:(NSTextCheckingResult *)result {
    return [self addLinkWithTextCheckingResult:result attributes:self.linkAttributes];
}

- (TTTAttributedLabelLink *)addLinkToURL:(NSURL *)url
                               withRange:(NSRange)range
{
    return [self addLinkWithTextCheckingResult:[NSTextCheckingResult linkCheckingResultWithRange:range URL:url]];
}

- (TTTAttributedLabelLink *)addLinkToAddress:(NSDictionary *)addressComponents
                                   withRange:(NSRange)range
{
    return [self addLinkWithTextCheckingResult:[NSTextCheckingResult addressCheckingResultWithRange:range components:addressComponents]];
}

- (TTTAttributedLabelLink *)addLinkToPhoneNumber:(NSString *)phoneNumber
                                       withRange:(NSRange)range
{
    return [self addLinkWithTextCheckingResult:[NSTextCheckingResult phoneNumberCheckingResultWithRange:range phoneNumber:phoneNumber]];
}

- (TTTAttributedLabelLink *)addLinkToDate:(NSDate *)date
            withRange:(NSRange)range
{
    return [self addLinkWithTextCheckingResult:[NSTextCheckingResult dateCheckingResultWithRange:range date:date]];
}

- (TTTAttributedLabelLink *)addLinkToDate:(NSDate *)date
                                 timeZone:(NSTimeZone *)timeZone
                                 duration:(NSTimeInterval)duration
                                withRange:(NSRange)range
{
    return [self addLinkWithTextCheckingResult:[NSTextCheckingResult dateCheckingResultWithRange:range date:date timeZone:timeZone duration:duration]];
}

- (TTTAttributedLabelLink *)addLinkToTransitInformation:(NSDictionary *)components
                                              withRange:(NSRange)range
{
    return [self addLinkWithTextCheckingResult:[NSTextCheckingResult transitInformationCheckingResultWithRange:range components:components]];
}

#pragma mark -

- (BOOL)containslinkAtPoint:(CGPoint)point {
    return [self linkAtPoint:point] != nil;
}

- (TTTAttributedLabelLink *)linkAtPoint:(CGPoint)point {
    
    // Stop quickly if none of the points to be tested are in the bounds.
    if (!CGRectContainsPoint(CGRectInset(self.bounds, -15.f, -15.f), point) || self.links.count == 0) {
        return nil;
    }
    
    TTTAttributedLabelLink *result = [self linkAtCharacterIndex:[self characterIndexAtPoint:point]];
    
    if (!result && self.extendsLinkTouchArea) {
        result = [self linkAtRadius:2.5f aroundPoint:point]
              ?: [self linkAtRadius:5.f aroundPoint:point]
              ?: [self linkAtRadius:7.5f aroundPoint:point]
              ?: [self linkAtRadius:12.5f aroundPoint:point]
              ?: [self linkAtRadius:15.f aroundPoint:point];
    }
    
    return result;
}

- (TTTAttributedLabelLink *)linkAtRadius:(const CGFloat)radius aroundPoint:(CGPoint)point {
    const CGFloat diagonal = CGFloat_sqrt(2 * radius * radius);
    const CGPoint deltas[] = {
        CGPointMake(0, -radius), CGPointMake(0, radius), // Above and below
        CGPointMake(-radius, 0), CGPointMake(radius, 0), // Beside
        CGPointMake(-diagonal, -diagonal), CGPointMake(-diagonal, diagonal),
        CGPointMake(diagonal, diagonal), CGPointMake(diagonal, -diagonal) // Diagonal
    };
    const size_t count = sizeof(deltas) / sizeof(CGPoint);
    
    TTTAttributedLabelLink *link = nil;
    
    for (NSInteger i = 0; i < count && link.result == nil; i ++) {
        CGPoint currentPoint = CGPointMake(point.x + deltas[i].x, point.y + deltas[i].y);
        link = [self linkAtCharacterIndex:[self characterIndexAtPoint:currentPoint]];
    }
    
    return link;
}

- (TTTAttributedLabelLink *)linkAtCharacterIndex:(CFIndex)idx {
    // Do not enumerate if the index is outside of the bounds of the text.
    if (!NSLocationInRange((NSUInteger)idx, NSMakeRange(0, self.attributedText.length))) {
        return nil;
    }
    
    NSEnumerator *enumerator = [self.linkModels reverseObjectEnumerator];
    TTTAttributedLabelLink *link = nil;
    while ((link = [enumerator nextObject])) {
        if (NSLocationInRange((NSUInteger)idx, link.result.range)) {
            return link;
        }
    }

    return nil;
}

- (NSUInteger)characterIndexAtPoint:(CGPoint)p {
    CGSize boundingSize = [self sizeThatFits:CGRectIntegral([self.textStorage boundingRectWithSize:CGSizeMake(self.textContainer.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:NULL]).size];
    
    if (boundingSize.height < CGRectGetHeight(self.bounds)) {
        CGFloat topMargin = (CGRectGetHeight(self.bounds) - boundingSize.height) / 2;
        
        if (p.y - topMargin < 0) {
            return NSNotFound;
        }
        
        p = CGPointMake(p.x, p.y - topMargin);
    }
    
    NSUInteger index = [self.layoutManager characterIndexForPoint:p
                                                  inTextContainer:self.textContainer
                         fractionOfDistanceBetweenInsertionPoints:NULL];
    
    
    
    return index;
}

- (CGRect)boundingRectForCharacterRange:(NSRange)range {
    NSMutableAttributedString *mutableAttributedString = [self.attributedText mutableCopy];

    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:mutableAttributedString];

    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];

    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:self.bounds.size];
    [layoutManager addTextContainer:textContainer];

    NSRange glyphRange;
    [layoutManager characterRangeForGlyphRange:range actualGlyphRange:&glyphRange];

    return [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
}

#pragma mark - UILabel

- (void) setAttributedText:(NSAttributedString *)attributedText {
    [super setAttributedText:attributedText];
    [self updateTextStorageFont];
}

- (void) setFont:(UIFont *)font {
    [super setFont:font];
    [self updateTextStorageFont];
}

- (void) updateTextStorageFont {
    if (self.attributedText) {
        NSMutableAttributedString *attributedTextWithFont = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];

        if (self.font) {
            [attributedTextWithFont addAttributes:@{NSFontAttributeName: self.font} range:NSMakeRange(0, self.attributedText.string.length)];
        }
        
        [self.textStorage setAttributedString:attributedTextWithFont];
    }
}

- (void) layoutSubviews {
    [super layoutSubviews];
    self.textContainer.size = self.bounds.size;
}

- (void) setNumberOfLines:(NSInteger)numberOfLines {
    [super setNumberOfLines:numberOfLines];
    self.textContainer.maximumNumberOfLines = numberOfLines;
}

- (void) setLineBreakMode:(NSLineBreakMode)lineBreakMode {
    [super setLineBreakMode:lineBreakMode];
    self.textContainer.lineBreakMode = lineBreakMode;
}

#pragma mark - TTTAttributedLabel

- (void)setActiveLink:(TTTAttributedLabelLink *)activeLink {
    _activeLink = activeLink;
    
    NSDictionary *activeAttributes = activeLink.activeAttributes ?: self.activeLinkAttributes;

    if (_activeLink && activeAttributes.count > 0) {
        if (!self.inactiveAttributedText) {
            self.inactiveAttributedText = [self.attributedText copy];
        }

        NSMutableAttributedString *mutableAttributedString = [self.inactiveAttributedText mutableCopy];
        if (self.activeLink.result.range.length > 0 && NSLocationInRange(NSMaxRange(self.activeLink.result.range) - 1, NSMakeRange(0, (self.inactiveAttributedText).length))) {
            [mutableAttributedString addAttributes:activeAttributes range:self.activeLink.result.range];
        }

        self.attributedText = mutableAttributedString;
        [self setNeedsDisplay];

        [CATransaction flush];
    } else if (self.inactiveAttributedText) {
        self.attributedText = self.inactiveAttributedText;
        self.inactiveAttributedText = nil;

        [self setNeedsDisplay];
    }
}

#pragma mark - UIAccessibilityElement

- (BOOL)isAccessibilityElement {
    return NO;
}

- (NSInteger)accessibilityElementCount {
    return (NSInteger)self.accessibilityElements.count;
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
    return self.accessibilityElements[(NSUInteger)index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    return (NSInteger)[self.accessibilityElements indexOfObject:element];
}

- (NSArray *)accessibilityElements {
    if (!_accessibilityElements) {
        @synchronized(self) {
            NSMutableArray *mutableAccessibilityItems = [NSMutableArray array];

            for (TTTAttributedLabelLink *link in self.linkModels) {
                
                if (link.result.range.location == NSNotFound) {
                    continue;
                }
                
                NSString *sourceText = [self.text isKindOfClass:[NSString class]] ? self.text : ((NSAttributedString *)self.text).string;

                NSString *accessibilityLabel = [sourceText substringWithRange:link.result.range];
                NSString *accessibilityValue = link.accessibilityValue;

                if (accessibilityLabel) {
                    TTTAccessibilityElement *linkElement = [[TTTAccessibilityElement alloc] initWithAccessibilityContainer:self];
                    linkElement.accessibilityTraits = UIAccessibilityTraitLink;
                    linkElement.boundingRect = [self boundingRectForCharacterRange:link.result.range];
                    linkElement.superview = self;
                    linkElement.accessibilityLabel = accessibilityLabel;

                    if (![accessibilityLabel isEqualToString:accessibilityValue]) {
                        linkElement.accessibilityValue = accessibilityValue;
                    }

                    [mutableAccessibilityItems addObject:linkElement];
                }
            }

            TTTAccessibilityElement *baseElement = [[TTTAccessibilityElement alloc] initWithAccessibilityContainer:self];
            baseElement.accessibilityLabel = super.accessibilityLabel;
            baseElement.accessibilityHint = super.accessibilityHint;
            baseElement.accessibilityValue = super.accessibilityValue;
            baseElement.boundingRect = self.bounds;
            baseElement.superview = self;
            baseElement.accessibilityTraits = super.accessibilityTraits;

            [mutableAccessibilityItems addObject:baseElement];

            self.accessibilityElements = [NSArray arrayWithArray:mutableAccessibilityItems];
        }
    }

    return _accessibilityElements;
}

- (void)tintColorDidChange {
    if (!self.inactiveLinkAttributes || (self.inactiveLinkAttributes).count == 0) {
        return;
    }

    BOOL isInactive = (self.tintAdjustmentMode == UIViewTintAdjustmentModeDimmed);

    NSMutableAttributedString *mutableAttributedString = [self.attributedText mutableCopy];
    for (TTTAttributedLabelLink *link in self.linkModels) {
        NSDictionary *attributesToRemove = isInactive ? link.attributes : link.inactiveAttributes;
        NSDictionary *attributesToAdd = isInactive ? link.inactiveAttributes : link.attributes;
        
        [attributesToRemove enumerateKeysAndObjectsUsingBlock:^(NSString *name, __unused id value, __unused BOOL *stop) {
            if (NSMaxRange(link.result.range) <= mutableAttributedString.length) {
                [mutableAttributedString removeAttribute:name range:link.result.range];
            }
        }];

        if (attributesToAdd) {
            if (NSMaxRange(link.result.range) <= mutableAttributedString.length) {
                [mutableAttributedString addAttributes:attributesToAdd range:link.result.range];
            }
        }
    }

    self.attributedText = mutableAttributedString;
}

- (UIView *)hitTest:(CGPoint)point
          withEvent:(UIEvent *)event
{
    if (![self linkAtPoint:point] || !self.userInteractionEnabled || self.hidden || self.alpha < 0.01) {
        return [super hitTest:point withEvent:event];
    }

    return self;
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action
              withSender:(__unused id)sender
{
#if !TARGET_OS_TV
    return (action == @selector(copy:));
#else
    return NO;
#endif
}

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];

    self.activeLink = [self linkAtPoint:[touch locationInView:self]];

    if (!self.activeLink) {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    if (self.activeLink) {
        UITouch *touch = [touches anyObject];

        if (self.activeLink != [self linkAtPoint:[touch locationInView:self]]) {
            self.activeLink = nil;
        }
    } else {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    if (self.activeLink) {
        if (self.activeLink.linkTapBlock) {
            self.activeLink.linkTapBlock(self, self.activeLink);
            self.activeLink = nil;
            return;
        }
        
        NSTextCheckingResult *result = self.activeLink.result;
        self.activeLink = nil;

        switch (result.resultType) {
            case NSTextCheckingTypeLink:
                if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithURL:)]) {
                    [self.delegate attributedLabel:self didSelectLinkWithURL:result.URL];
                    return;
                }
                break;
            case NSTextCheckingTypeAddress:
                if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithAddress:)]) {
                    [self.delegate attributedLabel:self didSelectLinkWithAddress:result.addressComponents];
                    return;
                }
                break;
            case NSTextCheckingTypePhoneNumber:
                if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithPhoneNumber:)]) {
                    [self.delegate attributedLabel:self didSelectLinkWithPhoneNumber:result.phoneNumber];
                    return;
                }
                break;
            case NSTextCheckingTypeDate:
                if (result.timeZone && [self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithDate:timeZone:duration:)]) {
                    [self.delegate attributedLabel:self didSelectLinkWithDate:result.date timeZone:result.timeZone duration:result.duration];
                    return;
                } else if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithDate:)]) {
                    [self.delegate attributedLabel:self didSelectLinkWithDate:result.date];
                    return;
                }
                break;
            case NSTextCheckingTypeTransitInformation:
                if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithTransitInformation:)]) {
                    [self.delegate attributedLabel:self didSelectLinkWithTransitInformation:result.components];
                    return;
                }
            default:
                break;
        }

        // Fallback to `attributedLabel:didSelectLinkWithTextCheckingResult:` if no other delegate method matched.
        if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithTextCheckingResult:)]) {
            [self.delegate attributedLabel:self didSelectLinkWithTextCheckingResult:result];
        }
    } else {
        [super touchesEnded:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet *)touches
               withEvent:(UIEvent *)event
{
    if (self.activeLink) {
        self.activeLink = nil;
    } else {
        [super touchesCancelled:touches withEvent:event];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return [self containslinkAtPoint:[touch locationInView:self]];
}

#pragma mark - UILongPressGestureRecognizer

- (void)longPressGestureDidFire:(UILongPressGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            CGPoint touchPoint = [sender locationInView:self];
            TTTAttributedLabelLink *link = [self linkAtPoint:touchPoint];
            
            if (link) {
                if (link.linkLongPressBlock) {
                    link.linkLongPressBlock(self, link);
                    return;
                }
                
                NSTextCheckingResult *result = link.result;
                
                if (!result) {
                    return;
                }
                
                switch (result.resultType) {
                    case NSTextCheckingTypeLink:
                        if ([self.delegate respondsToSelector:@selector(attributedLabel:didLongPressLinkWithURL:atPoint:)]) {
                            [self.delegate attributedLabel:self didLongPressLinkWithURL:result.URL atPoint:touchPoint];
                            return;
                        }
                        break;
                    case NSTextCheckingTypeAddress:
                        if ([self.delegate respondsToSelector:@selector(attributedLabel:didLongPressLinkWithAddress:atPoint:)]) {
                            [self.delegate attributedLabel:self didLongPressLinkWithAddress:result.addressComponents atPoint:touchPoint];
                            return;
                        }
                        break;
                    case NSTextCheckingTypePhoneNumber:
                        if ([self.delegate respondsToSelector:@selector(attributedLabel:didLongPressLinkWithPhoneNumber:atPoint:)]) {
                            [self.delegate attributedLabel:self didLongPressLinkWithPhoneNumber:result.phoneNumber atPoint:touchPoint];
                            return;
                        }
                        break;
                    case NSTextCheckingTypeDate:
                        if (result.timeZone && [self.delegate respondsToSelector:@selector(attributedLabel:didLongPressLinkWithDate:timeZone:duration:atPoint:)]) {
                            [self.delegate attributedLabel:self didLongPressLinkWithDate:result.date timeZone:result.timeZone duration:result.duration atPoint:touchPoint];
                            return;
                        } else if ([self.delegate respondsToSelector:@selector(attributedLabel:didLongPressLinkWithDate:atPoint:)]) {
                            [self.delegate attributedLabel:self didLongPressLinkWithDate:result.date atPoint:touchPoint];
                            return;
                        }
                        break;
                    case NSTextCheckingTypeTransitInformation:
                        if ([self.delegate respondsToSelector:@selector(attributedLabel:didLongPressLinkWithTransitInformation:atPoint:)]) {
                            [self.delegate attributedLabel:self didLongPressLinkWithTransitInformation:result.components atPoint:touchPoint];
                            return;
                        }
                    default:
                        break;
                }
                
                // Fallback to `attributedLabel:didLongPressLinkWithTextCheckingResult:atPoint:` if no other delegate method matched.
                if ([self.delegate respondsToSelector:@selector(attributedLabel:didLongPressLinkWithTextCheckingResult:atPoint:)]) {
                    [self.delegate attributedLabel:self didLongPressLinkWithTextCheckingResult:result atPoint:touchPoint];
                }
            }
            break;
        }
        default:
            break;
    }
}

#if !TARGET_OS_TV
#pragma mark - UIResponderStandardEditActions

- (void)copy:(__unused id)sender {
    [UIPasteboard generalPasteboard].string = self.text;
}
#endif

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];

    [coder encodeObject:@(self.enabledTextCheckingTypes) forKey:NSStringFromSelector(@selector(enabledTextCheckingTypes))];

    [coder encodeObject:self.linkModels forKey:NSStringFromSelector(@selector(linkModels))];
    if ([NSMutableParagraphStyle class]) {
        [coder encodeObject:self.linkAttributes forKey:NSStringFromSelector(@selector(linkAttributes))];
        [coder encodeObject:self.activeLinkAttributes forKey:NSStringFromSelector(@selector(activeLinkAttributes))];
        [coder encodeObject:self.inactiveLinkAttributes forKey:NSStringFromSelector(@selector(inactiveLinkAttributes))];
    }
//    [coder encodeObject:@(self.shadowRadius) forKey:NSStringFromSelector(@selector(shadowRadius))];
//    [coder encodeObject:@(self.highlightedShadowRadius) forKey:NSStringFromSelector(@selector(highlightedShadowRadius))];
//    [coder encodeCGSize:self.highlightedShadowOffset forKey:NSStringFromSelector(@selector(highlightedShadowOffset))];
//    [coder encodeObject:self.highlightedShadowColor forKey:NSStringFromSelector(@selector(highlightedShadowColor))];
//    [coder encodeObject:@(self.kern) forKey:NSStringFromSelector(@selector(kern))];
//    [coder encodeObject:@(self.firstLineIndent) forKey:NSStringFromSelector(@selector(firstLineIndent))];
//    [coder encodeObject:@(self.lineSpacing) forKey:NSStringFromSelector(@selector(lineSpacing))];
//    [coder encodeObject:@(self.lineHeightMultiple) forKey:NSStringFromSelector(@selector(lineHeightMultiple))];
//    [coder encodeUIEdgeInsets:self.textInsets forKey:NSStringFromSelector(@selector(textInsets))];
//    [coder encodeInteger:self.verticalAlignment forKey:NSStringFromSelector(@selector(verticalAlignment))];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [coder encodeObject:self.truncationTokenString forKey:NSStringFromSelector(@selector(truncationTokenString))];
#pragma clang diagnostic pop

//    [coder encodeObject:NSStringFromUIEdgeInsets(self.linkBackgroundEdgeInset) forKey:NSStringFromSelector(@selector(linkBackgroundEdgeInset))];
    [coder encodeObject:self.attributedText forKey:NSStringFromSelector(@selector(attributedText))];
    [coder encodeObject:self.text forKey:NSStringFromSelector(@selector(text))];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (!self) {
        return nil;
    }

    [self commonInit];

    if ([coder containsValueForKey:NSStringFromSelector(@selector(enabledTextCheckingTypes))]) {
        self.enabledTextCheckingTypes = [[coder decodeObjectForKey:NSStringFromSelector(@selector(enabledTextCheckingTypes))] unsignedLongLongValue];
    }

    if ([NSMutableParagraphStyle class]) {
        if ([coder containsValueForKey:NSStringFromSelector(@selector(linkAttributes))]) {
            self.linkAttributes = [coder decodeObjectForKey:NSStringFromSelector(@selector(linkAttributes))];
        }

        if ([coder containsValueForKey:NSStringFromSelector(@selector(activeLinkAttributes))]) {
            self.activeLinkAttributes = [coder decodeObjectForKey:NSStringFromSelector(@selector(activeLinkAttributes))];
        }

        if ([coder containsValueForKey:NSStringFromSelector(@selector(inactiveLinkAttributes))]) {
            self.inactiveLinkAttributes = [coder decodeObjectForKey:NSStringFromSelector(@selector(inactiveLinkAttributes))];
        }
    }

    if ([coder containsValueForKey:NSStringFromSelector(@selector(links))]) {
        NSArray *oldLinks = [coder decodeObjectForKey:NSStringFromSelector(@selector(links))];
        [self addLinksWithTextCheckingResults:oldLinks attributes:nil];
    }

    if ([coder containsValueForKey:NSStringFromSelector(@selector(linkModels))]) {
        self.linkModels = [coder decodeObjectForKey:NSStringFromSelector(@selector(linkModels))];
    }

//    if ([coder containsValueForKey:NSStringFromSelector(@selector(shadowRadius))]) {
//        self.shadowRadius = [[coder decodeObjectForKey:NSStringFromSelector(@selector(shadowRadius))] floatValue];
//    }
//
//    if ([coder containsValueForKey:NSStringFromSelector(@selector(highlightedShadowRadius))]) {
//        self.highlightedShadowRadius = [[coder decodeObjectForKey:NSStringFromSelector(@selector(highlightedShadowRadius))] floatValue];
//    }
//
//    if ([coder containsValueForKey:NSStringFromSelector(@selector(highlightedShadowOffset))]) {
//        self.highlightedShadowOffset = [coder decodeCGSizeForKey:NSStringFromSelector(@selector(highlightedShadowOffset))];
//    }
//
//    if ([coder containsValueForKey:NSStringFromSelector(@selector(highlightedShadowColor))]) {
//        self.highlightedShadowColor = [coder decodeObjectForKey:NSStringFromSelector(@selector(highlightedShadowColor))];
//    }
//
//    if ([coder containsValueForKey:NSStringFromSelector(@selector(kern))]) {
//        self.kern = [[coder decodeObjectForKey:NSStringFromSelector(@selector(kern))] floatValue];
//    }
//
//    if ([coder containsValueForKey:NSStringFromSelector(@selector(firstLineIndent))]) {
//        self.firstLineIndent = [[coder decodeObjectForKey:NSStringFromSelector(@selector(firstLineIndent))] floatValue];
//    }
//
//    if ([coder containsValueForKey:NSStringFromSelector(@selector(lineSpacing))]) {
//        self.lineSpacing = [[coder decodeObjectForKey:NSStringFromSelector(@selector(lineSpacing))] floatValue];
//    }
//
//    if ([coder containsValueForKey:NSStringFromSelector(@selector(minimumLineHeight))]) {
//        self.minimumLineHeight = [[coder decodeObjectForKey:NSStringFromSelector(@selector(minimumLineHeight))] floatValue];
//    }
//
//    if ([coder containsValueForKey:NSStringFromSelector(@selector(maximumLineHeight))]) {
//        self.maximumLineHeight = [[coder decodeObjectForKey:NSStringFromSelector(@selector(maximumLineHeight))] floatValue];
//    }
//
//    if ([coder containsValueForKey:NSStringFromSelector(@selector(lineHeightMultiple))]) {
//        self.lineHeightMultiple = [[coder decodeObjectForKey:NSStringFromSelector(@selector(lineHeightMultiple))] floatValue];
//    }
//
//    if ([coder containsValueForKey:NSStringFromSelector(@selector(textInsets))]) {
//        self.textInsets = [coder decodeUIEdgeInsetsForKey:NSStringFromSelector(@selector(textInsets))];
//    }
//
//    if ([coder containsValueForKey:NSStringFromSelector(@selector(verticalAlignment))]) {
//        self.verticalAlignment = [coder decodeIntegerForKey:NSStringFromSelector(@selector(verticalAlignment))];
//    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if ([coder containsValueForKey:NSStringFromSelector(@selector(truncationTokenString))]) {
        self.truncationTokenString = [coder decodeObjectForKey:NSStringFromSelector(@selector(truncationTokenString))];
    }
#pragma clang diagnostic pop

//    if ([coder containsValueForKey:NSStringFromSelector(@selector(linkBackgroundEdgeInset))]) {
//        self.linkBackgroundEdgeInset = UIEdgeInsetsFromString([coder decodeObjectForKey:NSStringFromSelector(@selector(linkBackgroundEdgeInset))]);
//    }

    if ([coder containsValueForKey:NSStringFromSelector(@selector(attributedText))]) {
        self.attributedText = [coder decodeObjectForKey:NSStringFromSelector(@selector(attributedText))];
    } else {
        self.text = super.text;
    }
    
    return self;
}

@end

#pragma mark - TTTAttributedLabelLink

@implementation TTTAttributedLabelLink

- (instancetype)initWithAttributes:(NSDictionary *)attributes
                  activeAttributes:(NSDictionary *)activeAttributes
                inactiveAttributes:(NSDictionary *)inactiveAttributes
                textCheckingResult:(NSTextCheckingResult *)result {
    
    if ((self = [super init])) {
        _result = result;
        _attributes = [attributes copy];
        _activeAttributes = [activeAttributes copy];
        _inactiveAttributes = [inactiveAttributes copy];
    }
    
    return self;
}

- (instancetype)initWithAttributesFromLabel:(TTTAttributedLabel*)label
                         textCheckingResult:(NSTextCheckingResult *)result {
    
    return [self initWithAttributes:label.linkAttributes
                   activeAttributes:label.activeLinkAttributes
                 inactiveAttributes:label.inactiveLinkAttributes
                 textCheckingResult:result];
}

#pragma mark - Accessibility

- (NSString *) accessibilityValue {
    if (_accessibilityValue.length == 0) {
        switch (self.result.resultType) {
            case NSTextCheckingTypeLink:
                _accessibilityValue = self.result.URL.absoluteString;
                break;
            case NSTextCheckingTypePhoneNumber:
                _accessibilityValue = self.result.phoneNumber;
                break;
            case NSTextCheckingTypeDate:
                _accessibilityValue = [NSDateFormatter localizedStringFromDate:self.result.date
                                                                     dateStyle:NSDateFormatterLongStyle
                                                                     timeStyle:NSDateFormatterLongStyle];
                break;
            default:
                break;
        }
    }
    
    return _accessibilityValue;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.result forKey:NSStringFromSelector(@selector(result))];
    [aCoder encodeObject:self.attributes forKey:NSStringFromSelector(@selector(attributes))];
    [aCoder encodeObject:self.activeAttributes forKey:NSStringFromSelector(@selector(activeAttributes))];
    [aCoder encodeObject:self.inactiveAttributes forKey:NSStringFromSelector(@selector(inactiveAttributes))];
    [aCoder encodeObject:self.accessibilityValue forKey:NSStringFromSelector(@selector(accessibilityValue))];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        _result = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(result))];
        _attributes = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(attributes))];
        _activeAttributes = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(activeAttributes))];
        _inactiveAttributes = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(inactiveAttributes))];
        self.accessibilityValue = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(accessibilityValue))];
    }
    
    return self;
}

@end