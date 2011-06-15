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

static inline CTTextAlignment CTTextAlignmentFromUITextAlignment(UITextAlignment alignment) {
	switch (alignment) {
		case UITextAlignmentLeft: return kCTLeftTextAlignment;
		case UITextAlignmentCenter: return kCTCenterTextAlignment;
		case UITextAlignmentRight: return kCTRightTextAlignment;
		default: return kCTNaturalTextAlignment;
	}
}

static inline CTLineBreakMode CTLineBreakModeFromUILineBreakMode(UILineBreakMode lineBreakMode) {
	switch (lineBreakMode) {
		case UILineBreakModeWordWrap: return kCTLineBreakByWordWrapping;
		case UILineBreakModeCharacterWrap: return kCTLineBreakByCharWrapping;
		case UILineBreakModeClip: return kCTLineBreakByClipping;
		case UILineBreakModeHeadTruncation: return kCTLineBreakByTruncatingHead;
		case UILineBreakModeTailTruncation: return kCTLineBreakByTruncatingTail;
		case UILineBreakModeMiddleTruncation: return kCTLineBreakByTruncatingMiddle;
		default: return 0;
	}
}

static inline NSTextCheckingType NSTextCheckingTypeFromUIDataDetectorType(UIDataDetectorTypes dataDetectorType) {
    switch (dataDetectorType) {
        case UIDataDetectorTypeAll: return NSTextCheckingTypeAddress | NSTextCheckingTypeDate | NSTextCheckingTypeLink | NSTextCheckingTypePhoneNumber;
        case UIDataDetectorTypeAddress: return NSTextCheckingTypeAddress;
        case UIDataDetectorTypeCalendarEvent: return NSTextCheckingTypeDate;
        case UIDataDetectorTypeLink: return NSTextCheckingTypeLink;
        case UIDataDetectorTypePhoneNumber: return NSTextCheckingTypePhoneNumber;
        default: return 0;
    }
}

static inline NSDictionary * NSAttributedStringAttributesFromLabel(UILabel *label) {
    NSMutableDictionary *mutableAttributes = [NSMutableDictionary dictionary]; 
    
    CTFontRef font = CTFontCreateWithName((CFStringRef)label.font.fontName, label.font.pointSize, NULL);
    [mutableAttributes setObject:(id)font forKey:(NSString *)kCTFontAttributeName];
    CFRelease(font);
    
    [mutableAttributes setObject:(id)[label.textColor CGColor] forKey:(NSString*)kCTForegroundColorAttributeName];
    
    CTTextAlignment alignment = CTTextAlignmentFromUITextAlignment(label.textAlignment);
    CTLineBreakMode lineBreakMode = CTLineBreakModeFromUILineBreakMode(label.lineBreakMode);
    CTParagraphStyleSetting paragraphStyles[2] = {
		{.spec = kCTParagraphStyleSpecifierAlignment, .valueSize = sizeof(CTTextAlignment), .value = (const void*)&alignment},
		{.spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(CTLineBreakMode), .value = (const void*)&lineBreakMode},
	};
	CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphStyles, 2);
	[mutableAttributes setObject:(id)paragraphStyle forKey:(NSString*)kCTParagraphStyleAttributeName];
	CFRelease(paragraphStyle);
    
    return [NSDictionary dictionaryWithDictionary:mutableAttributes];
}

@interface TTTAttributedLabel ()
@property (readwrite, nonatomic, copy) NSAttributedString *attributedText;
@property (readwrite, nonatomic, assign) CTFramesetterRef framesetter;
@property (readwrite, nonatomic, retain) NSArray *links;

- (NSArray *)detectedLinksInString:(NSString *)string range:(NSRange)range error:(NSError **)error;
- (NSTextCheckingResult *)linkAtCharacterIndex:(CFIndex)idx;
- (NSTextCheckingResult *)linkAtPoint:(CGPoint)p;
- (NSUInteger)characterIndexAtPoint:(CGPoint)p;
@end

@implementation TTTAttributedLabel
@dynamic text;
@synthesize attributedText = _attributedText;
@synthesize framesetter = _framesetter;

@synthesize delegate;
@synthesize dataDetectorTypes = _dataDetectorTypes;
@synthesize links = _links;
@synthesize linkAttributes = _linkAttributes;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
        
    self.dataDetectorTypes = UIDataDetectorTypeNone;
    self.links = [NSArray array];
    
    NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
    [mutableLinkAttributes setValue:(id)[[UIColor blueColor] CGColor] forKey:(NSString*)kCTForegroundColorAttributeName];
    [mutableLinkAttributes setValue:[NSNumber numberWithBool:YES] forKey:(NSString *)kCTUnderlineStyleAttributeName];
    self.linkAttributes = [NSDictionary dictionaryWithDictionary:mutableLinkAttributes];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (!self) {
        return nil;
    }
    
    return [self initWithFrame:self.frame];
}

- (void)dealloc {
    if (_framesetter) CFRelease(_framesetter);
    [_attributedText release];
    [_links release];
    [_linkAttributes release];
    [super dealloc];
}

#pragma mark -

- (void)setAttributedText:(NSAttributedString *)text {
    if (![text isEqualToAttributedString:self.attributedText]) {
        [self setNeedsFramesetter];
    }
    
    [self willChangeValueForKey:@"attributedText"];
    [_attributedText release];
    _attributedText = [text copy];
    [self didChangeValueForKey:@"attributedText"];
}

- (void)setNeedsFramesetter {
    _needsFramesetter = YES;
}

- (CTFramesetterRef)framesetter {
    if (_needsFramesetter) {
        @synchronized(self) {
            if (_framesetter) CFRelease(_framesetter);
            
            self.framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.attributedText);
            _needsFramesetter = NO;
        }
    }
    
    return _framesetter;
}

- (BOOL)isUserInteractionEnabled {
    return !_userInteractionDisabled && [self.links count] > 0;
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled {
    _userInteractionDisabled = !userInteractionEnabled;
}

#pragma mark -

- (NSArray *)detectedLinksInString:(NSString *)string range:(NSRange)range error:(NSError **)error {
    NSMutableArray *mutableLinks = [NSMutableArray array];
    NSDataDetector *dataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeFromUIDataDetectorType(self.dataDetectorTypes) error:error];
    [dataDetector enumerateMatchesInString:string options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [mutableLinks addObject:result];
    }];
    
    return [NSArray arrayWithArray:mutableLinks];
}

- (void)addLinkWithTextCheckingResult:(NSTextCheckingResult *)result {
    self.links = [self.links arrayByAddingObject:result];
    
    if (self.linkAttributes) {
        NSMutableAttributedString *mutableAttributedString = [[[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText] autorelease];
        [mutableAttributedString addAttributes:self.linkAttributes range:result.range];
        self.attributedText = mutableAttributedString;        
    }
}

- (void)addLinkToURL:(NSURL *)url withRange:(NSRange)range {
    [self addLinkWithTextCheckingResult:[NSTextCheckingResult linkCheckingResultWithRange:range URL:url]];
}

- (void)addLinkToAddress:(NSDictionary *)addressComponents withRange:(NSRange)range {
    [self addLinkWithTextCheckingResult:[NSTextCheckingResult addressCheckingResultWithRange:range components:addressComponents]];
}

- (void)addLinkToPhoneNumber:(NSString *)phoneNumber withRange:(NSRange)range {
    [self addLinkWithTextCheckingResult:[NSTextCheckingResult phoneNumberCheckingResultWithRange:range phoneNumber:phoneNumber]];
}

- (void)addLinkToDate:(NSDate *)date withRange:(NSRange)range {
    [self addLinkWithTextCheckingResult:[NSTextCheckingResult dateCheckingResultWithRange:range date:date]];
}

- (void)addLinkToDate:(NSDate *)date timeZone:(NSTimeZone *)timeZone duration:(NSTimeInterval)duration withRange:(NSRange)range {
    [self addLinkWithTextCheckingResult:[NSTextCheckingResult dateCheckingResultWithRange:range date:date timeZone:timeZone duration:duration]];
}

#pragma mark -

- (NSTextCheckingResult *)linkAtCharacterIndex:(CFIndex)idx {
    for (NSTextCheckingResult *result in self.links) {
        NSRange range = result.range;
        if (range.location <= idx && idx <= range.location + range.length) {
            return result;
        }
    }
    
    return nil;
}

- (NSTextCheckingResult *)linkAtPoint:(CGPoint)p {
    CFIndex idx = [self characterIndexAtPoint:p];
    return [self linkAtCharacterIndex:idx];
}

- (NSUInteger)characterIndexAtPoint:(CGPoint)p {
    if (!CGRectContainsPoint(self.bounds, p)) {
        return NSNotFound;
    }
    
    CGRect textRect = [self textRectForBounds:self.bounds limitedToNumberOfLines:self.numberOfLines];
    if (!CGRectContainsPoint(textRect, p)) {
        return NSNotFound;
    }
    
    CFIndex idx = NSNotFound;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, textRect);
    CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(0, [self.attributedText length]), path, NULL);
    CFArrayRef lines = CTFrameGetLines(frame);
    NSUInteger numberOfLines = CFArrayGetCount(lines);
    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);
    NSUInteger lineIndex = numberOfLines - 1;
    
    CGPoint lineOrigin = CGPointZero;
    for (NSUInteger i = 0; i < numberOfLines; i++) {
        CGPoint lineOrigin = lineOrigins[i];
        if(lineOrigin.y > p.y) {
            lineIndex--;
        }            
    }
    
    lineOrigin = lineOrigins[lineIndex];
    CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
    CGPoint relativePoint = CGPointMake(p.x - lineOrigin.x, p.y - lineOrigin.y);
    idx = CTLineGetStringIndexForPosition(line, relativePoint);
    
    CFRelease(frame);
    CFRelease(path);
        
    return idx;
}

#pragma mark -
#pragma mark TTTAttributedLabel

- (void)setText:(id)text {
    if ([text isKindOfClass:[NSString class]]) {
        [self setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
    }
    
    self.attributedText = text;
    self.links = [NSArray array];
    if (self.dataDetectorTypes != UIDataDetectorTypeNone) {
        for (NSTextCheckingResult *result in [self detectedLinksInString:[text string] range:NSMakeRange(0, [text length]) error:nil]) {
            [self addLinkWithTextCheckingResult:result];
        }
    }
        
    [super setText:[(NSAttributedString *)text string]];
}

- (void)setText:(id)text afterInheritingLabelAttributesAndConfiguringWithBlock:(TTTMutableAttributedStringBlock)block {
    if ([text isKindOfClass:[NSString class]]) {
        text = [[[NSAttributedString alloc] initWithString:text] autorelease];
    }
    
    NSMutableAttributedString *mutableAttributedString = [[[NSMutableAttributedString alloc] initWithAttributedString:text] autorelease];
    [mutableAttributedString addAttributes:NSAttributedStringAttributesFromLabel(self) range:NSMakeRange(0, [mutableAttributedString length])];
    
    if (block) {
        [self setText:block(mutableAttributedString)];
    } else {
        [self setText:mutableAttributedString];
    }
}

#pragma mark -
#pragma mark UILabel

- (void)drawTextInRect:(CGRect)rect {
    if (!self.attributedText) {
        [super drawTextInRect:rect];
    }
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(c, CGAffineTransformIdentity);
    CGContextTranslateCTM(c, 0, self.bounds.size.height);
    CGContextScaleCTM(c, 1.0, -1.0);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);
    CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(0, [self.attributedText length]), path, NULL);
    CTFrameDraw(frame, c);
    
    CFRelease(frame);
    CFRelease(path);
}

#pragma mark -
#pragma mark UIControl

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return [self linkAtPoint:point] != nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];	
	NSTextCheckingResult *result = [self linkAtPoint:[touch locationInView:self]];
    
    if (result && self.delegate) {
        switch (result.resultType) {
            case NSTextCheckingTypeLink:
                if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithURL:)]) {
                    [self.delegate attributedLabel:self didSelectLinkWithURL:result.URL];
                }
                break;
            case NSTextCheckingTypeAddress:
                if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithAddress:)]) {
                    [self.delegate attributedLabel:self didSelectLinkWithAddress:result.addressComponents];
                }
                break;
            case NSTextCheckingTypePhoneNumber:
                if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithPhoneNumber::)]) {
                    [self.delegate attributedLabel:self didSelectLinkWithPhoneNumber:result.phoneNumber];
                }
                break;
            case NSTextCheckingTypeDate:
                if (result.timeZone && [self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithDate:timeZone:duration:)]) {
                    [self.delegate attributedLabel:self didSelectLinkWithDate:result.date timeZone:result.timeZone duration:result.duration];
                } else if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithDate:)]) {
                    [self.delegate attributedLabel:self didSelectLinkWithDate:result.date];
                }
                break;
        }
    }
}

#pragma mark -
#pragma mark UIView

- (CGSize)sizeThatFits:(CGSize)size {
    if (!self.attributedText) {
        return [super sizeThatFits:size];
    }
    
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, CFRangeMake(0, [self.attributedText length]), NULL, CGSizeMake(size.width, CGFLOAT_MAX), NULL);
        
    return CGSizeMake(ceilf(suggestedSize.width), ceilf(suggestedSize.height));
}

@end
