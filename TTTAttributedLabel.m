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

#define kTTTLineBreakWordWrapTextWidthScalingFactor (M_PI / M_E)

NSString * const kTTTStrikeOutAttributeName = @"TTTStrikeOutAttribute";

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
    NSTextCheckingType textCheckingType = 0;
    if (dataDetectorType & UIDataDetectorTypeAddress) {
        textCheckingType |= NSTextCheckingTypeAddress;
    }
    
    if (dataDetectorType & UIDataDetectorTypeCalendarEvent) {
        textCheckingType |= NSTextCheckingTypeDate;
    }
    
    if (dataDetectorType & UIDataDetectorTypeLink) {
        textCheckingType |= NSTextCheckingTypeLink;
    }
    
    if (dataDetectorType & UIDataDetectorTypePhoneNumber) {
        textCheckingType |= NSTextCheckingTypePhoneNumber;
    }
    
    return textCheckingType;
}

static inline NSDictionary * NSAttributedStringAttributesFromLabel(TTTAttributedLabel *label) {
    NSMutableDictionary *mutableAttributes = [NSMutableDictionary dictionary]; 
    
    CTFontRef font = CTFontCreateWithName((CFStringRef)label.font.fontName, label.font.pointSize, NULL);
    [mutableAttributes setObject:(id)font forKey:(NSString *)kCTFontAttributeName];
    CFRelease(font);
    
    [mutableAttributes setObject:(id)[label.textColor CGColor] forKey:(NSString *)kCTForegroundColorAttributeName];
    
    CTTextAlignment alignment = CTTextAlignmentFromUITextAlignment(label.textAlignment);
    CGFloat lineSpacing = label.leading;
    CGFloat lineHeightMultiple = label.lineHeightMultiple;
    CGFloat topMargin = label.textInsets.top;
    CGFloat bottomMargin = label.textInsets.bottom;
    CGFloat leftMargin = label.textInsets.left;
    CGFloat rightMargin = label.textInsets.right;
    CGFloat firstLineIndent = label.firstLineIndent + leftMargin;

    CTLineBreakMode lineBreakMode;
    if (label.numberOfLines != 1) {
        lineBreakMode = CTLineBreakModeFromUILineBreakMode(UILineBreakModeWordWrap);
    }
    else {
        lineBreakMode = CTLineBreakModeFromUILineBreakMode(label.lineBreakMode);
    }
	
    CTParagraphStyleSetting paragraphStyles[9] = {
		{.spec = kCTParagraphStyleSpecifierAlignment, .valueSize = sizeof(CTTextAlignment), .value = (const void *)&alignment},
		{.spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(CTLineBreakMode), .value = (const void *)&lineBreakMode},
        {.spec = kCTParagraphStyleSpecifierLineSpacing, .valueSize = sizeof(CGFloat), .value = (const void *)&lineSpacing},
        {.spec = kCTParagraphStyleSpecifierLineHeightMultiple, .valueSize = sizeof(CGFloat), .value = (const void *)&lineHeightMultiple},
        {.spec = kCTParagraphStyleSpecifierFirstLineHeadIndent, .valueSize = sizeof(CGFloat), .value = (const void *)&firstLineIndent},
        {.spec = kCTParagraphStyleSpecifierParagraphSpacingBefore, .valueSize = sizeof(CGFloat), .value = (const void *)&topMargin},
        {.spec = kCTParagraphStyleSpecifierParagraphSpacing, .valueSize = sizeof(CGFloat), .value = (const void *)&bottomMargin},
        {.spec = kCTParagraphStyleSpecifierHeadIndent, .valueSize = sizeof(CGFloat), .value = (const void *)&leftMargin},
        {.spec = kCTParagraphStyleSpecifierTailIndent, .valueSize = sizeof(CGFloat), .value = (const void *)&rightMargin}
	};

    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphStyles, 9);
	[mutableAttributes setObject:(id)paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];
	CFRelease(paragraphStyle);
    
    return [NSDictionary dictionaryWithDictionary:mutableAttributes];
}

static inline NSAttributedString * NSAttributedStringByScalingFontSize(NSAttributedString *attributedString, CGFloat scale, CGFloat minimumFontSize) {    
    NSMutableAttributedString *mutableAttributedString = [[attributedString mutableCopy] autorelease];
    [mutableAttributedString enumerateAttribute:(NSString *)kCTFontAttributeName inRange:NSMakeRange(0, [mutableAttributedString length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        CTFontRef font = (CTFontRef)value;
        if (font) {
            CGFloat scaledFontSize = floorf(CTFontGetSize(font) * scale);
            CTFontRef scaledFont = CTFontCreateCopyWithAttributes(font, fmaxf(scaledFontSize, minimumFontSize), NULL, NULL);
            CFAttributedStringSetAttribute((CFMutableAttributedStringRef)mutableAttributedString, CFRangeMake(range.location, range.length), kCTFontAttributeName, scaledFont);
            CFRelease(scaledFont);
        }
    }];
    
    return mutableAttributedString;
}

@interface TTTAttributedLabel ()
@property (readwrite, nonatomic, copy) NSAttributedString *attributedText;
@property (readwrite, nonatomic, assign) CTFramesetterRef framesetter;
@property (readwrite, nonatomic, assign) CTFramesetterRef highlightFramesetter;
@property (readwrite, nonatomic, retain) NSDataDetector *dataDetector;
@property (readwrite, nonatomic, retain) NSArray *links;
@property (readwrite, nonatomic, retain) UITapGestureRecognizer *tapGestureRecognizer;

- (void)commonInit;
- (void)setNeedsFramesetter;
- (NSArray *)detectedLinksInString:(NSString *)string range:(NSRange)range error:(NSError **)error;
- (NSTextCheckingResult *)linkAtCharacterIndex:(CFIndex)idx;
- (NSTextCheckingResult *)linkAtPoint:(CGPoint)p;
- (NSUInteger)characterIndexAtPoint:(CGPoint)p;
- (void)drawFramesetter:(CTFramesetterRef)framesetter textRange:(CFRange)textRange inRect:(CGRect)rect context:(CGContextRef)c;
- (void)drawStrike:(CTFrameRef)frame inRect:(CGRect)rect context:(CGContextRef)c;
- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer;
@end

@implementation TTTAttributedLabel
@dynamic text;
@synthesize attributedText = _attributedText;
@synthesize framesetter = _framesetter;
@synthesize highlightFramesetter = _highlightFramesetter;
@synthesize delegate = _delegate;
@synthesize dataDetectorTypes = _dataDetectorTypes;
@synthesize dataDetector = _dataDetector;
@synthesize links = _links;
@synthesize linkAttributes = _linkAttributes;
@synthesize shadowRadius = _shadowRadius;
@synthesize leading = _leading;
@synthesize lineHeightMultiple = _lineHeightMultiple;
@synthesize firstLineIndent = _firstLineIndent;
@synthesize textInsets = _textInsets;
@synthesize verticalAlignment = _verticalAlignment;
@synthesize tapGestureRecognizer = _tapGestureRecognizer;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (!self) {
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (void)commonInit {
    self.dataDetectorTypes = UIDataDetectorTypeNone;
    self.links = [NSArray array];
    
    NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
    [mutableLinkAttributes setValue:(id)[[UIColor blueColor] CGColor] forKey:(NSString*)kCTForegroundColorAttributeName];
    [mutableLinkAttributes setValue:[NSNumber numberWithBool:YES] forKey:(NSString *)kCTUnderlineStyleAttributeName];
    self.linkAttributes = [NSDictionary dictionaryWithDictionary:mutableLinkAttributes];
    
    self.textInsets = UIEdgeInsetsZero;
    
    self.userInteractionEnabled = YES;
    self.tapGestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
    [self.tapGestureRecognizer setDelegate:self];
    [self addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)dealloc {
    if (_framesetter) CFRelease(_framesetter);
    if (_highlightFramesetter) CFRelease(_highlightFramesetter);
    
    [_attributedText release];
    [_dataDetector release];
    [_links release];
    [_linkAttributes release];
    [_tapGestureRecognizer release];
    [super dealloc];
}

#pragma mark -

- (void)setAttributedText:(NSAttributedString *)text {
    if ([text isEqualToAttributedString:self.attributedText]) {
        return;
    }
    
    [self willChangeValueForKey:@"attributedText"];
    [_attributedText release];
    _attributedText = [text copy];
    [self didChangeValueForKey:@"attributedText"];
    
    [self setNeedsFramesetter];
}

- (void)setNeedsFramesetter {
    _needsFramesetter = YES;
}

- (CTFramesetterRef)framesetter {
    if (_needsFramesetter) {
        @synchronized(self) {
            if (_framesetter) CFRelease(_framesetter);
            if (_highlightFramesetter) CFRelease(_highlightFramesetter);
            
            self.framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.attributedText);
            self.highlightFramesetter = nil;
            _needsFramesetter = NO;
        }
    }
    
    return _framesetter;
}

#pragma mark -

- (void)setDataDetectorTypes:(UIDataDetectorTypes)dataDetectorTypes {
    [self willChangeValueForKey:@"dataDetectorTypes"];
    _dataDetectorTypes = dataDetectorTypes;
    [self didChangeValueForKey:@"dataDetectorTypes"];
    
    if (self.dataDetectorTypes != UIDataDetectorTypeNone) {
        self.dataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeFromUIDataDetectorType(self.dataDetectorTypes) error:nil];
    }
}

- (NSArray *)detectedLinksInString:(NSString *)string range:(NSRange)range error:(NSError **)error {
    if (!string || !self.dataDetector) {
        return [NSArray array];
    }
    
    NSMutableArray *mutableLinks = [NSMutableArray array];
    [self.dataDetector enumerateMatchesInString:string options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [mutableLinks addObject:result];
    }];
    
    return [NSArray arrayWithArray:mutableLinks];
}

- (void)addLinkWithTextCheckingResult:(NSTextCheckingResult *)result attributes:(NSDictionary *)attributes {
    self.links = [self.links arrayByAddingObject:result];
    
    if (attributes) {
        NSMutableAttributedString *mutableAttributedString = [[[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText] autorelease];
        [mutableAttributedString addAttributes:attributes range:result.range];
        self.attributedText = mutableAttributedString;        
    }
}

- (void)addLinkWithTextCheckingResult:(NSTextCheckingResult *)result {
    [self addLinkWithTextCheckingResult:result attributes:self.linkAttributes];
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
        if ((CFIndex)range.location <= idx && idx <= (CFIndex)(range.location + range.length)) {
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
    
    // Convert tap coordinates (start at top left) to CT coordinates (start at bottom left)
    p = CGPointMake(p.x, textRect.size.height - p.y);

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, textRect);
    CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(0, [self.attributedText length]), path, NULL);
    if (frame == NULL) {
        CFRelease(path);
        return NSNotFound;
    }

    CFArrayRef lines = CTFrameGetLines(frame);
    NSUInteger numberOfLines = CFArrayGetCount(lines);
    if (numberOfLines == 0) {
        CFRelease(frame);
        CFRelease(path);
        return NSNotFound;
    }

    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);

    NSUInteger lineIndex;
    for (lineIndex = 0; lineIndex < (numberOfLines - 1); lineIndex++) {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        if (lineOrigin.y < p.y) {
            break;
        }
    }

    if (lineIndex >= numberOfLines) {
        CFRelease(frame);
        CFRelease(path);
        return NSNotFound;
    }

    CGPoint lineOrigin = lineOrigins[lineIndex];
    CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
    // Convert CT coordinates to line-relative coordinates
    CGPoint relativePoint = CGPointMake(p.x - lineOrigin.x, p.y - lineOrigin.y);
    CFIndex idx = CTLineGetStringIndexForPosition(line, relativePoint);

    CFRelease(frame);
    CFRelease(path);
        
    return idx;
}

- (void)drawFramesetter:(CTFramesetterRef)framesetter textRange:(CFRange)textRange inRect:(CGRect)rect context:(CGContextRef)c {
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathAddRect(path, NULL, rect);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, textRange, path, NULL);    
    
    if (self.numberOfLines == 0) {
        CTFrameDraw(frame, c);
    } else {
        CFArrayRef lines = CTFrameGetLines(frame);
        NSUInteger numberOfLines = MIN(self.numberOfLines, CFArrayGetCount(lines));
        BOOL truncateLastLine = (self.lineBreakMode == UILineBreakModeHeadTruncation || self.lineBreakMode == UILineBreakModeMiddleTruncation || self.lineBreakMode == UILineBreakModeTailTruncation);

        CGPoint lineOrigins[numberOfLines];
        CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);
        
        for (NSUInteger lineIndex = 0; lineIndex < numberOfLines; lineIndex++) {
            CGPoint lineOrigin = lineOrigins[lineIndex];
            CGContextSetTextPosition(c, lineOrigin.x, lineOrigin.y);
            CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);

            if (lineIndex == numberOfLines - 1 && truncateLastLine) {
                // Check if the range of text in the last line reaches the end of the full attributed string
                CFRange lastLineRange = CTLineGetStringRange(line);
                
                if (lastLineRange.location + lastLineRange.length < textRange.location + textRange.length) {
                    // Get the attributes of the last character in the line and use them to create the truncation token string
                    NSDictionary *tokenAttributes = [self.attributedText attributesAtIndex:(lastLineRange.location + lastLineRange.length - 1) effectiveRange:NULL];
                    NSAttributedString *tokenString = [[[NSAttributedString alloc] initWithString:@"\u2026" attributes:tokenAttributes] autorelease]; // \u2026 is the Unicode horizontal ellipsis character code
                    
                    // Create and draw a truncated line
                    CTLineTruncationType truncationType;
                    switch (self.lineBreakMode) {
                        case UILineBreakModeHeadTruncation:
                            truncationType = kCTLineTruncationStart;
                            break;
                        case UILineBreakModeMiddleTruncation:
                            truncationType = kCTLineTruncationMiddle;
                            break;
                        case UILineBreakModeTailTruncation:
                        default:
                            truncationType = kCTLineTruncationEnd;
                            break;
                    }
                    
                    CTLineRef truncationToken = CTLineCreateWithAttributedString((CFAttributedStringRef)tokenString);
                    CTLineRef truncatedLine = CTLineCreateTruncatedLine(line, CTLineGetImageBounds(line, c).size.width, truncationType, truncationToken);
                    CTLineDraw(truncatedLine, c);
                    
                    CFRelease(truncatedLine);
                    CFRelease(truncationToken);
                }
                else {
                    CTLineDraw(line, c);
                }
            }
            else {
                CTLineDraw(line, c);
            }
        }
    }

    [self drawStrike:frame inRect:rect context:c];
    
    CFRelease(frame);
    CFRelease(path);
}

- (void)drawStrike:(CTFrameRef)frame inRect:(CGRect)rect context:(CGContextRef)c {
    NSArray *lines = (NSArray *)CTFrameGetLines(frame);
    CGPoint origins[[lines count]];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), origins);
    
    NSUInteger lineIndex = 0;
    for (id line in lines) {        
        CGRect lineBounds = CTLineGetImageBounds((CTLineRef)line, c);
        lineBounds.origin.x = origins[lineIndex].x;
        lineBounds.origin.y = origins[lineIndex].y;
        
        for (id glyphRun in (NSArray *)CTLineGetGlyphRuns((CTLineRef)line)) {
            NSDictionary *attributes = (NSDictionary *)CTRunGetAttributes((CTRunRef) glyphRun);
            BOOL strikeOut = [[attributes objectForKey:kTTTStrikeOutAttributeName] boolValue];
            NSInteger superscriptStyle = [[attributes objectForKey:(id)kCTSuperscriptAttributeName] integerValue];
            
            if (strikeOut) {
                CGRect runBounds = CGRectZero;
                CGFloat ascent = 0.0f;
                CGFloat descent = 0.0f;
                
                runBounds.size.width = CTRunGetTypographicBounds((CTRunRef)glyphRun, CFRangeMake(0, 0), &ascent, &descent, NULL);
                runBounds.size.height = ascent + descent;
                
                CGFloat xOffset = CTLineGetOffsetForStringIndex((CTLineRef)line, CTRunGetStringRange((CTRunRef)glyphRun).location, NULL);
                runBounds.origin.x = origins[lineIndex].x + rect.origin.x + xOffset;
                runBounds.origin.y = origins[lineIndex].y + rect.origin.y;
                runBounds.origin.y -= descent;
                
                // Don't draw strikeout too far to the right
                if (CGRectGetWidth(runBounds) > CGRectGetWidth(lineBounds)) {
                    runBounds.size.width = CGRectGetWidth(lineBounds);
                }
                
				switch (superscriptStyle) {
					case 1:
						runBounds.origin.y -= ascent * 0.47f;
						break;
					case -1:
						runBounds.origin.y += ascent * 0.25f;
						break;
					default:
						break;
				}
                
                // Use text color, or default to black
                id color = [attributes objectForKey:(id)kCTForegroundColorAttributeName];

                if (color) {
                    CGContextSetStrokeColorWithColor(c, (CGColorRef)color);
                } else {
                    CGContextSetGrayStrokeColor(c, 0.0f, 1.0);
                }
                
                CTFontRef font = CTFontCreateWithName((CFStringRef)self.font.fontName, self.font.pointSize, NULL);
                CGContextSetLineWidth(c, CTFontGetUnderlineThickness(font));
                CGFloat y = roundf(runBounds.origin.y + runBounds.size.height / 2.0f);
                CGContextMoveToPoint(c, runBounds.origin.x, y);
                CGContextAddLineToPoint(c, runBounds.origin.x + runBounds.size.width, y);
                
                CGContextStrokePath(c);
            }
        }
        
        lineIndex++;
    }
}

#pragma mark - TTTAttributedLabel

- (void)setText:(id)text {
    if ([text isKindOfClass:[NSString class]]) {
        [self setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
    } else {
        self.attributedText = text;
    }

    self.links = [NSArray array];
    if (self.dataDetectorTypes != UIDataDetectorTypeNone) {
        for (NSTextCheckingResult *result in [self detectedLinksInString:[self.attributedText string] range:NSMakeRange(0, [text length]) error:nil]) {
            [self addLinkWithTextCheckingResult:result];
        }
    }
        
    [super setText:[self.attributedText string]];
}

- (void)setText:(id)text afterInheritingLabelAttributesAndConfiguringWithBlock:(NSMutableAttributedString *(^)(NSMutableAttributedString *mutableAttributedString))block {    
    NSMutableAttributedString *mutableAttributedString = nil;
    if ([text isKindOfClass:[NSString class]]) {
        mutableAttributedString = [[[NSMutableAttributedString alloc] initWithString:text attributes:NSAttributedStringAttributesFromLabel(self)] autorelease];
    } else {
        mutableAttributedString = [[[NSMutableAttributedString alloc] initWithAttributedString:text] autorelease];
        [mutableAttributedString addAttributes:NSAttributedStringAttributesFromLabel(self) range:NSMakeRange(0, [mutableAttributedString length])];
    }
    
    if (block) {
        mutableAttributedString = block(mutableAttributedString);
    }
    
    [self setText:mutableAttributedString];
}

#pragma mark - UILabel

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

- (void)drawTextInRect:(CGRect)rect {
    if (!self.attributedText) {
        [super drawTextInRect:rect];
        return;
    }
    
    NSAttributedString *originalAttributedText = nil;
    // Adjust the font size to fit width, if necessarry 
    if (self.adjustsFontSizeToFitWidth && self.numberOfLines > 0) {
        CGFloat textWidth = [self sizeThatFits:CGSizeZero].width;
        CGFloat availableWidth = self.frame.size.width * self.numberOfLines;
        if (self.numberOfLines > 1 && self.lineBreakMode == UILineBreakModeWordWrap) {
            textWidth *= kTTTLineBreakWordWrapTextWidthScalingFactor;
        }
        
        if (textWidth > availableWidth && textWidth > 0.0f) {
            originalAttributedText = [[self.attributedText copy] autorelease];
            self.text = NSAttributedStringByScalingFontSize(self.attributedText, availableWidth / textWidth, self.minimumFontSize);
        }
    }
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(c, CGAffineTransformIdentity);

    // Inverts the CTM to match iOS coordinates (otherwise text draws upside-down; Mac OS's system is different)
    CGRect textRect = rect;
    CGContextTranslateCTM(c, 0.0f, textRect.size.height);
    CGContextScaleCTM(c, 1.0f, -1.0f);
    
    CFRange textRange = CFRangeMake(0, [self.attributedText length]);
    CFRange fitRange;

    // First, adjust the text to be in the center vertically, if the text size is smaller than the drawing rect
    CGSize textSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, textRange, NULL, textRect.size, &fitRange);
    textSize = CGSizeMake(ceilf(textSize.width), ceilf(textSize.height)); // Fix for iOS 4, CTFramesetterSuggestFrameSizeWithConstraints sometimes returns fractional sizes
    
    if (textSize.height < textRect.size.height) {
        CGFloat yOffset = 0.0f;
        CGFloat heightChange = (textRect.size.height - textSize.height);
        switch (self.verticalAlignment) {
            case TTTAttributedLabelVerticalAlignmentTop:
                heightChange = 0.0f;
                break;
            case TTTAttributedLabelVerticalAlignmentCenter:
                yOffset = floorf((textRect.size.height - textSize.height) / 2.0f);
                break;
            case TTTAttributedLabelVerticalAlignmentBottom:
                break;
        }
        
        textRect.origin = CGPointMake(textRect.origin.x, textRect.origin.y + yOffset);
        textRect.size = CGSizeMake(textRect.size.width, textRect.size.height - heightChange + yOffset);
    }

    // Second, trace the shadow before the actual text, if we have one
    if (self.shadowColor && !self.highlighted) {
        CGContextSetShadowWithColor(c, self.shadowOffset, self.shadowRadius, [self.shadowColor CGColor]);
    }
    
    // Finally, draw the text or highlighted text itself (on top of the shadow, if there is one)
    if (self.highlightedTextColor && self.highlighted) {
        if (!self.highlightFramesetter) {
            NSMutableAttributedString *mutableAttributedString = [[self.attributedText mutableCopy] autorelease];
            [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[self.highlightedTextColor CGColor] range:NSMakeRange(0, mutableAttributedString.length)];
            self.highlightFramesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)mutableAttributedString);
        }
        
        [self drawFramesetter:self.highlightFramesetter textRange:textRange inRect:textRect context:c];
    } else {
        [self drawFramesetter:self.framesetter textRange:textRange inRect:textRect context:c];
    }  
    
    // If we adjusted the font size, set it back to its original size
    if (originalAttributedText) {
        self.text = originalAttributedText;
    }
}

#pragma mark - UIView

- (CGSize)sizeThatFits:(CGSize)size {
    if (!self.attributedText) {
        return [super sizeThatFits:size];
    }
    
    CFRange rangeToSize = CFRangeMake(0, [self.attributedText length]);
    CGSize constraints = CGSizeMake(size.width, CGFLOAT_MAX);
    
    if (self.numberOfLines == 1) {
        // If there is one line, the size that fits is the full width of the line
        constraints = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
    } else if (self.numberOfLines > 0) {
        // If the line count of the label more than 1, limit the range to size to the number of lines that have been set
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0.0f, 0.0f, self.bounds.size.width, CGFLOAT_MAX));
        CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(0, 0), path, NULL);
        CFArrayRef lines = CTFrameGetLines(frame);
        
        if (CFArrayGetCount(lines) > 0) {
            NSInteger lastVisibleLineIndex = MIN(self.numberOfLines, CFArrayGetCount(lines)) - 1;
            CTLineRef lastVisibleLine = CFArrayGetValueAtIndex(lines, lastVisibleLineIndex);
            
            CFRange rangeToLayout = CTLineGetStringRange(lastVisibleLine);
            rangeToSize = CFRangeMake(0, rangeToLayout.location + rangeToLayout.length);
        }
        
        CFRelease(frame);
        CFRelease(path);
    }
    
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, rangeToSize, NULL, constraints, NULL);
    
    return CGSizeMake(ceilf(suggestedSize.width), ceilf(suggestedSize.height));
}

#pragma mark - UIGestureRecognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return [self linkAtPoint:[touch locationInView:self]] != nil;
}

- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer state] != UIGestureRecognizerStateEnded) {
        return;
    }
    
    NSTextCheckingResult *result = [self linkAtPoint:[gestureRecognizer locationInView:self]];
    if (!result || !self.delegate) {
        return;
    }
    
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
            if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithPhoneNumber:)]) {
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

@end
