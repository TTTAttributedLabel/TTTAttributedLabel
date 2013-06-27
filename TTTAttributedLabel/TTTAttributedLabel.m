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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

NSString * const kTTTStrikeOutAttributeName = @"TTTStrikeOutAttribute";
NSString * const kTTTBackgroundFillColorAttributeName = @"TTTBackgroundFillColor";
NSString * const kTTTBackgroundFillPaddingAttributeName = @"TTTBackgroundFillPadding";
NSString * const kTTTBackgroundStrokeColorAttributeName = @"TTTBackgroundStrokeColor";
NSString * const kTTTBackgroundLineWidthAttributeName = @"TTTBackgroundLineWidth";
NSString * const kTTTBackgroundCornerRadiusAttributeName = @"TTTBackgroundCornerRadius";

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

static inline NSDictionary * NSAttributedStringAttributesFromLabel(TTTAttributedLabel *label) {
    NSMutableDictionary *mutableAttributes = [NSMutableDictionary dictionary]; 

    if ([NSMutableParagraphStyle class]) {
        [mutableAttributes setObject:label.font forKey:(NSString *)kCTFontAttributeName];
        [mutableAttributes setObject:label.textColor forKey:(NSString *)kCTForegroundColorAttributeName];

        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = label.textAlignment;
        paragraphStyle.lineSpacing = label.leading;
        paragraphStyle.lineHeightMultiple = label.lineHeightMultiple;
        paragraphStyle.firstLineHeadIndent = label.firstLineIndent;
        paragraphStyle.paragraphSpacingBefore = label.textInsets.top;
        paragraphStyle.paragraphSpacing = label.textInsets.bottom;
        paragraphStyle.headIndent = label.textInsets.left;
        paragraphStyle.tailIndent = -label.textInsets.right;

        if (label.numberOfLines == 1) {
            paragraphStyle.lineBreakMode = label.lineBreakMode;
        } else {
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        }

        [mutableAttributes setObject:paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];
    } else {
        CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)label.font.fontName, label.font.pointSize, NULL);
        [mutableAttributes setObject:(__bridge id)font forKey:(NSString *)kCTFontAttributeName];
        CFRelease(font);

        [mutableAttributes setObject:(id)[label.textColor CGColor] forKey:(NSString *)kCTForegroundColorAttributeName];

        CTTextAlignment alignment = CTTextAlignmentFromUITextAlignment(label.textAlignment);
        CGFloat lineSpacing = label.leading;
        CGFloat lineSpacingAdjustment = ceilf(label.font.lineHeight - label.font.ascender + label.font.descender);
        CGFloat lineHeightMultiple = label.lineHeightMultiple;
        CGFloat topMargin = label.textInsets.top;
        CGFloat bottomMargin = label.textInsets.bottom;
        CGFloat leftMargin = label.textInsets.left;
        CGFloat rightMargin = -label.textInsets.right;
        CGFloat firstLineIndent = label.firstLineIndent + leftMargin;

        CTLineBreakMode lineBreakMode;
        if (label.numberOfLines != 1) {
            lineBreakMode = CTLineBreakModeFromUILineBreakMode(UILineBreakModeWordWrap);
        } else {
            lineBreakMode = CTLineBreakModeFromUILineBreakMode(label.lineBreakMode);
        }

        CTParagraphStyleSetting paragraphStyles[10] = {
            {.spec = kCTParagraphStyleSpecifierAlignment, .valueSize = sizeof(CTTextAlignment), .value = (const void *)&alignment},
            {.spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(CTLineBreakMode), .value = (const void *)&lineBreakMode},
            {.spec = kCTParagraphStyleSpecifierLineSpacing, .valueSize = sizeof(CGFloat), .value = (const void *)&lineSpacing},
            {.spec = kCTParagraphStyleSpecifierLineSpacingAdjustment, .valueSize = sizeof (CGFloat), .value = (const void *)&lineSpacingAdjustment},
            {.spec = kCTParagraphStyleSpecifierLineHeightMultiple, .valueSize = sizeof(CGFloat), .value = (const void *)&lineHeightMultiple},
            {.spec = kCTParagraphStyleSpecifierFirstLineHeadIndent, .valueSize = sizeof(CGFloat), .value = (const void *)&firstLineIndent},
            {.spec = kCTParagraphStyleSpecifierParagraphSpacingBefore, .valueSize = sizeof(CGFloat), .value = (const void *)&topMargin},
            {.spec = kCTParagraphStyleSpecifierParagraphSpacing, .valueSize = sizeof(CGFloat), .value = (const void *)&bottomMargin},
            {.spec = kCTParagraphStyleSpecifierHeadIndent, .valueSize = sizeof(CGFloat), .value = (const void *)&leftMargin},
            {.spec = kCTParagraphStyleSpecifierTailIndent, .valueSize = sizeof(CGFloat), .value = (const void *)&rightMargin}
        };

        CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphStyles, 10);
        
        [mutableAttributes setObject:(__bridge id)paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];
        
        CFRelease(paragraphStyle);
    }
    
    return [NSDictionary dictionaryWithDictionary:mutableAttributes];
}

static inline NSAttributedString * NSAttributedStringByScalingFontSize(NSAttributedString *attributedString, CGFloat scale, CGFloat minimumFontSize) {    
    NSMutableAttributedString *mutableAttributedString = [attributedString mutableCopy];
    [mutableAttributedString enumerateAttribute:(NSString *)kCTFontAttributeName inRange:NSMakeRange(0, [mutableAttributedString length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        UIFont *font = (UIFont *)value;
        if (font) {
            NSString *fontName;
            CGFloat pointSize;
            
            if ([font isKindOfClass:[UIFont class]]) {
                fontName = font.fontName;
                pointSize = font.pointSize;
            } else {
                fontName = (NSString *)CFBridgingRelease(CTFontCopyName((__bridge CTFontRef)font, kCTFontPostScriptNameKey));
                pointSize = CTFontGetSize((__bridge CTFontRef)font);
            }
            
            [mutableAttributedString removeAttribute:(NSString *)kCTFontAttributeName range:range];
            CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)fontName, floorf(pointSize * scale), NULL);
            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)fontRef range:range];
            CFRelease(fontRef);
        }
    }];
    
    return mutableAttributedString;
}

static inline NSAttributedString * NSAttributedStringBySettingColorFromContext(NSAttributedString *attributedString, UIColor *color) {
    if (!color) {
        return attributedString;
    }
    
    NSMutableAttributedString *mutableAttributedString = [attributedString mutableCopy];    
    [mutableAttributedString enumerateAttribute:(NSString *)kCTForegroundColorFromContextAttributeName inRange:NSMakeRange(0, [mutableAttributedString length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        BOOL usesColorFromContext = (BOOL)value;
        if (usesColorFromContext) {
            [mutableAttributedString setAttributes:[NSDictionary dictionaryWithObject:color forKey:(NSString *)kCTForegroundColorAttributeName] range:range];
            [mutableAttributedString removeAttribute:(NSString *)kCTForegroundColorFromContextAttributeName range:range];
        }
    }];
    
    return mutableAttributedString;    
}

@interface TTTAttributedLabel ()
@property (readwrite, nonatomic, copy) NSAttributedString *inactiveAttributedText;
@property (readwrite, nonatomic, copy) NSAttributedString *renderedAttributedText;
@property (readwrite, nonatomic, assign) CTFramesetterRef framesetter;
@property (readwrite, nonatomic, assign) CTFramesetterRef highlightFramesetter;
@property (readwrite, nonatomic, strong) NSDataDetector *dataDetector;
@property (readwrite, nonatomic, strong) NSArray *links;
@property (readwrite, nonatomic, strong) NSTextCheckingResult *activeLink;

- (void)commonInit;
- (void)setNeedsFramesetter;
- (void)addLinksWithTextCheckingResults:(NSArray *)results
                             attributes:(NSDictionary *)attributes;
- (NSTextCheckingResult *)linkAtCharacterIndex:(CFIndex)idx;
- (NSTextCheckingResult *)linkAtPoint:(CGPoint)p;
- (CFIndex)characterIndexAtPoint:(CGPoint)p;
- (void)drawFramesetter:(CTFramesetterRef)framesetter
       attributedString:(NSAttributedString *)attributedString
              textRange:(CFRange)textRange
                 inRect:(CGRect)rect
                context:(CGContextRef)c;
- (void)drawStrike:(CTFrameRef)frame
            inRect:(CGRect)rect
           context:(CGContextRef)c;
@end

@implementation TTTAttributedLabel {
@private
    BOOL _needsFramesetter;
}

@dynamic text;
@synthesize attributedText = _attributedText;
@synthesize inactiveAttributedText = _inactiveAttributedText;
@synthesize renderedAttributedText = _renderedAttributedText;
@synthesize framesetter = _framesetter;
@synthesize highlightFramesetter = _highlightFramesetter;
@synthesize delegate = _delegate;
@synthesize dataDetectorTypes = _dataDetectorTypes;
@synthesize dataDetector = _dataDetector;
@synthesize links = _links;
@synthesize linkAttributes = _linkAttributes;
@synthesize activeLinkAttributes = _activeLinkAttributes;
@synthesize shadowRadius = _shadowRadius;
@synthesize highlightedShadowRadius = _highlightedShadowRadius;
@synthesize highlightedShadowOffset = _highlightedShadowOffset;
@synthesize highlightedShadowColor = _highlightedShadowColor;
@synthesize leading = _leading;
@synthesize lineHeightMultiple = _lineHeightMultiple;
@synthesize firstLineIndent = _firstLineIndent;
@synthesize textInsets = _textInsets;
@synthesize verticalAlignment = _verticalAlignment;
@synthesize truncationTokenString = _truncationTokenString;
@synthesize activeLink = _activeLink;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (void)commonInit {
    self.userInteractionEnabled = YES;
    self.multipleTouchEnabled = NO;
        
    self.textInsets = UIEdgeInsetsZero;
    
    self.links = [NSArray array];

    NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
    [mutableLinkAttributes setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCTUnderlineStyleAttributeName];
    
    NSMutableDictionary *mutableActiveLinkAttributes = [NSMutableDictionary dictionary];
    [mutableActiveLinkAttributes setObject:[NSNumber numberWithBool:NO] forKey:(NSString *)kCTUnderlineStyleAttributeName];

    if ([NSMutableParagraphStyle class]) {
        [mutableLinkAttributes setObject:[UIColor blueColor] forKey:(NSString *)kCTForegroundColorAttributeName];
        [mutableActiveLinkAttributes setObject:[UIColor redColor] forKey:(NSString *)kCTForegroundColorAttributeName];

        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        
        [mutableLinkAttributes setObject:paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];
        [mutableActiveLinkAttributes setObject:paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];
    } else {
        [mutableLinkAttributes setObject:(__bridge id)[[UIColor blueColor] CGColor] forKey:(NSString *)kCTForegroundColorAttributeName];
        [mutableActiveLinkAttributes setObject:(__bridge id)[[UIColor redColor] CGColor] forKey:(NSString *)kCTForegroundColorAttributeName];

        CTLineBreakMode lineBreakMode = CTLineBreakModeFromUILineBreakMode(UILineBreakModeWordWrap);
        CTParagraphStyleSetting paragraphStyles[1] = {
            {.spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(CTLineBreakMode), .value = (const void *)&lineBreakMode}
        };
        CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphStyles, 1);
        
        [mutableLinkAttributes setObject:(__bridge id)paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];
        [mutableActiveLinkAttributes setObject:(__bridge id)paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];
        
        CFRelease(paragraphStyle);
    }
	    
    self.linkAttributes = [NSDictionary dictionaryWithDictionary:mutableLinkAttributes];
    self.activeLinkAttributes = [NSDictionary dictionaryWithDictionary:mutableActiveLinkAttributes];
    
}

- (void)dealloc {
    if (_framesetter) CFRelease(_framesetter);
    if (_highlightFramesetter) CFRelease(_highlightFramesetter);
}

#pragma mark -

- (void)setAttributedText:(NSAttributedString *)text {
    if ([text isEqualToAttributedString:_attributedText]) {
        return;
    }
    
    _attributedText = [text copy];
    
    [self setNeedsFramesetter];
    [self setNeedsDisplay];
}

- (void)setNeedsFramesetter {
    // Reset the rendered attributed text so it has a chance to regenerate
    self.renderedAttributedText = nil;

    _needsFramesetter = YES;
}

- (CTFramesetterRef)framesetter {
    if (_needsFramesetter) {
        @synchronized(self) {
            if (_framesetter) CFRelease(_framesetter);
            if (_highlightFramesetter) CFRelease(_highlightFramesetter);
            
            self.framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.renderedAttributedText);
            self.highlightFramesetter = nil;
            _needsFramesetter = NO;
        }
    }
    
    return _framesetter;
}

- (NSAttributedString *)renderedAttributedText {
    if (!_renderedAttributedText) {
        self.renderedAttributedText = NSAttributedStringBySettingColorFromContext(self.attributedText, self.textColor);
    }
    
    return _renderedAttributedText;
}

#pragma mark -

- (void)setDataDetectorTypes:(NSTextCheckingTypes)dataDetectorTypes {
    _dataDetectorTypes = dataDetectorTypes;
    
    if (self.dataDetectorTypes) {
        self.dataDetector = [NSDataDetector dataDetectorWithTypes:self.dataDetectorTypes error:nil];
    } else {
        self.dataDetector = nil;
    }
}

- (void)addLinkWithTextCheckingResult:(NSTextCheckingResult *)result
                           attributes:(NSDictionary *)attributes
{
    [self addLinksWithTextCheckingResults:[NSArray arrayWithObject:result] attributes:attributes];
}

- (void)addLinksWithTextCheckingResults:(NSArray *)results
                             attributes:(NSDictionary *)attributes
{
    self.links = [self.links arrayByAddingObjectsFromArray:results];

    if (attributes) {
        NSMutableAttributedString *mutableAttributedString = [self.attributedText mutableCopy];
        for (NSTextCheckingResult *result in results) {
            [mutableAttributedString addAttributes:attributes range:result.range];
        }
        self.attributedText = mutableAttributedString;
        [self setNeedsDisplay];
    }
}

- (void)addLinkWithTextCheckingResult:(NSTextCheckingResult *)result {
    [self addLinkWithTextCheckingResult:result attributes:self.linkAttributes];
}

- (void)addLinkToURL:(NSURL *)url
           withRange:(NSRange)range
{
    [self addLinkWithTextCheckingResult:[NSTextCheckingResult linkCheckingResultWithRange:range URL:url]];
}

- (void)addLinkToAddress:(NSDictionary *)addressComponents
               withRange:(NSRange)range
{
    [self addLinkWithTextCheckingResult:[NSTextCheckingResult addressCheckingResultWithRange:range components:addressComponents]];
}

- (void)addLinkToPhoneNumber:(NSString *)phoneNumber
                   withRange:(NSRange)range
{
    [self addLinkWithTextCheckingResult:[NSTextCheckingResult phoneNumberCheckingResultWithRange:range phoneNumber:phoneNumber]];
}

- (void)addLinkToDate:(NSDate *)date
            withRange:(NSRange)range
{
    [self addLinkWithTextCheckingResult:[NSTextCheckingResult dateCheckingResultWithRange:range date:date]];
}

- (void)addLinkToDate:(NSDate *)date
             timeZone:(NSTimeZone *)timeZone
             duration:(NSTimeInterval)duration
            withRange:(NSRange)range
{
    [self addLinkWithTextCheckingResult:[NSTextCheckingResult dateCheckingResultWithRange:range date:date timeZone:timeZone duration:duration]];
}

- (void)addLinkToTransitInformation:(NSDictionary *)components
                          withRange:(NSRange)range
{
    [self addLinkWithTextCheckingResult:[NSTextCheckingResult transitInformationCheckingResultWithRange:range components:components]];
}

#pragma mark -

- (NSTextCheckingResult *)linkAtCharacterIndex:(CFIndex)idx {
    NSEnumerator *enumerator = [self.links reverseObjectEnumerator];
    NSTextCheckingResult *result = nil;
    while ((result = [enumerator nextObject])) {
        if (NSLocationInRange((NSUInteger)idx, result.range)) {
            return result;
        }
    }
    
    return nil;
}

- (NSTextCheckingResult *)linkAtPoint:(CGPoint)p {
    CFIndex idx = [self characterIndexAtPoint:p];
    
    return [self linkAtCharacterIndex:idx];
}

- (CFIndex)characterIndexAtPoint:(CGPoint)p {
    if (!CGRectContainsPoint(self.bounds, p)) {
        return NSNotFound;
    }
    
    CGRect textRect = [self textRectForBounds:self.bounds limitedToNumberOfLines:self.numberOfLines];
    if (!CGRectContainsPoint(textRect, p)) {
        return NSNotFound;
    }
    
    // Offset tap coordinates by textRect origin to make them relative to the origin of frame
    p = CGPointMake(p.x - textRect.origin.x, p.y - textRect.origin.y);
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
    NSInteger numberOfLines = self.numberOfLines > 0 ? MIN(self.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);
    if (numberOfLines == 0) {
        CFRelease(frame);
        CFRelease(path);
        return NSNotFound;
    }
    
    NSUInteger idx = NSNotFound;

    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);

    for (CFIndex lineIndex = 0; lineIndex < numberOfLines; lineIndex++) {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
        // Get bounding information of line
        CGFloat ascent = 0.0f, descent = 0.0f, leading = 0.0f;
        CGFloat width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        CGFloat yMin = floor(lineOrigin.y - descent);
        CGFloat yMax = ceil(lineOrigin.y + ascent);
        
        // Check if we've already passed the line
        if (p.y > yMax) {
            break;
        }
        // Check if the point is within this line vertically
        if (p.y >= yMin) {
            // Check if the point is within this line horizontally
            if (p.x >= lineOrigin.x && p.x <= lineOrigin.x + width) {
                // Convert CT coordinates to line-relative coordinates
                CGPoint relativePoint = CGPointMake(p.x - lineOrigin.x, p.y - lineOrigin.y);
                idx = CTLineGetStringIndexForPosition(line, relativePoint);
                break;
            }
        }
    }
    
    CFRelease(frame);
    CFRelease(path);
        
    return idx;
}

- (void)drawFramesetter:(CTFramesetterRef)framesetter
       attributedString:(NSAttributedString *)attributedString
              textRange:(CFRange)textRange
                 inRect:(CGRect)rect
                context:(CGContextRef)c
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, textRange, path, NULL);    
    
    [self drawBackground:frame inRect:rect context:c];
    
    CFArrayRef lines = CTFrameGetLines(frame);
    NSInteger numberOfLines = self.numberOfLines > 0 ? MIN(self.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);
    BOOL truncateLastLine = (self.lineBreakMode == UILineBreakModeHeadTruncation || self.lineBreakMode == UILineBreakModeMiddleTruncation || self.lineBreakMode == UILineBreakModeTailTruncation);
	
    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);
        
    for (CFIndex lineIndex = 0; lineIndex < numberOfLines; lineIndex++) {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CGContextSetTextPosition(c, lineOrigin.x, lineOrigin.y);
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
        if (lineIndex == numberOfLines - 1 && truncateLastLine) {
            // Check if the range of text in the last line reaches the end of the full attributed string
            CFRange lastLineRange = CTLineGetStringRange(line);
            
            if (!(lastLineRange.length == 0 && lastLineRange.location == 0) && lastLineRange.location + lastLineRange.length < textRange.location + textRange.length) {
                // Get correct truncationType and attribute position
                CTLineTruncationType truncationType;
                NSUInteger truncationAttributePosition = lastLineRange.location;
                UILineBreakMode lineBreakMode = self.lineBreakMode;
                
                // Multiple lines, only use UILineBreakModeTailTruncation
                if (numberOfLines != 1) {
                    lineBreakMode = UILineBreakModeTailTruncation;
                }
                
                switch (lineBreakMode) {
                    case UILineBreakModeHeadTruncation:
                        truncationType = kCTLineTruncationStart;
                        break;
                    case UILineBreakModeMiddleTruncation:
                        truncationType = kCTLineTruncationMiddle;
                        truncationAttributePosition += (lastLineRange.length / 2);
                        break;
                    case UILineBreakModeTailTruncation:
                    default:
                        truncationType = kCTLineTruncationEnd;
                        truncationAttributePosition += (lastLineRange.length - 1);
                        break;
                }
                
                // Get the attributes and use them to create the truncation token string
                NSDictionary *tokenAttributes = [attributedString attributesAtIndex:truncationAttributePosition effectiveRange:NULL];
                NSString *truncationTokenString = self.truncationTokenString;
                if (!truncationTokenString) {
                    truncationTokenString = @"\u2026"; // Unicode Character 'HORIZONTAL ELLIPSIS' (U+2026)
                }

                NSAttributedString *attributedTokenString = [[NSAttributedString alloc] initWithString:truncationTokenString attributes:tokenAttributes];
                CTLineRef truncationToken = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attributedTokenString);
                
                // Append truncationToken to the string
                // because if string isn't too long, CT wont add the truncationToken on it's own
                // There is no change of a double truncationToken because CT only add the token if it removes characters (and the one we add will go first)
                NSMutableAttributedString *truncationString = [[attributedString attributedSubstringFromRange:NSMakeRange(lastLineRange.location, lastLineRange.length)] mutableCopy];
                if (lastLineRange.length > 0) {
                    // Remove any newline at the end (we don't want newline space between the text and the truncation token). There can only be one, because the second would be on the next line.
                    unichar lastCharacter = [[truncationString string] characterAtIndex:lastLineRange.length - 1];
                    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastCharacter]) {
                        [truncationString deleteCharactersInRange:NSMakeRange(lastLineRange.length - 1, 1)];
                    }
                }
                [truncationString appendAttributedString:attributedTokenString];
                CTLineRef truncationLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncationString);

                // Truncate the line in case it is too long.
                CTLineRef truncatedLine = CTLineCreateTruncatedLine(truncationLine, rect.size.width, truncationType, truncationToken);
                if (!truncatedLine) {
                    // If the line is not as wide as the truncationToken, truncatedLine is NULL
                    truncatedLine = CFRetain(truncationToken);
                }

                // Adjust pen offset for flush depending on text alignment
                CGFloat flushFactor = 0.0f;
                switch (self.textAlignment) {
                    case UITextAlignmentCenter:
                        flushFactor = 0.5f;
                        break;
                    case UITextAlignmentRight:
                        flushFactor = 1.0f;
                        break;
                    case UITextAlignmentLeft:
                    default:
                        break;
                }

                CGFloat penOffset = CTLineGetPenOffsetForFlush(truncatedLine, flushFactor, rect.size.width);
                CGContextSetTextPosition(c, penOffset, lineOrigin.y);
                
                CTLineDraw(truncatedLine, c);
                
                CFRelease(truncatedLine);
                CFRelease(truncationLine);
                CFRelease(truncationToken);
            } else {
                CTLineDraw(line, c);
            }
        } else {
            CTLineDraw(line, c);
        }
    }
    
    [self drawStrike:frame inRect:rect context:c];
        
    CFRelease(frame);
    CFRelease(path);    
}

- (void)drawBackground:(CTFrameRef)frame
                inRect:(CGRect)rect
               context:(CGContextRef)c
{
    NSArray *lines = (__bridge NSArray *)CTFrameGetLines(frame);
    CGPoint origins[[lines count]];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), origins);
    
    // Compensate for y-offset of text rect from vertical positioning
    CGFloat yOffset = 0.0f;
    if (self.verticalAlignment != TTTAttributedLabelVerticalAlignmentTop) {
        yOffset -= [self textRectForBounds:self.bounds limitedToNumberOfLines:self.numberOfLines].origin.y;
    }
    
    CFIndex lineIndex = 0;
    for (id line in lines) {
        CGFloat ascent = 0.0f, descent = 0.0f, leading = 0.0f;
        CGFloat width = CTLineGetTypographicBounds((__bridge CTLineRef)line, &ascent, &descent, &leading) ;
        CGRect lineBounds = CGRectMake(0.0f, 0.0f, width, ascent + descent + leading) ;
        lineBounds.origin.x = origins[lineIndex].x;
        lineBounds.origin.y = origins[lineIndex].y;
        
        for (id glyphRun in (__bridge NSArray *)CTLineGetGlyphRuns((__bridge CTLineRef)line)) {
            NSDictionary *attributes = (__bridge NSDictionary *)CTRunGetAttributes((__bridge CTRunRef) glyphRun);
            CGColorRef strokeColor = (__bridge CGColorRef)[attributes objectForKey:kTTTBackgroundStrokeColorAttributeName];
            CGColorRef fillColor = (__bridge CGColorRef)[attributes objectForKey:kTTTBackgroundFillColorAttributeName];
            UIEdgeInsets fillPadding = [[attributes objectForKey:kTTTBackgroundFillPaddingAttributeName] UIEdgeInsetsValue];
            CGFloat cornerRadius = [[attributes objectForKey:kTTTBackgroundCornerRadiusAttributeName] floatValue];
            CGFloat lineWidth = [[attributes objectForKey:kTTTBackgroundLineWidthAttributeName] floatValue];

            if (strokeColor || fillColor) {
                CGRect runBounds = CGRectZero;
                CGFloat runAscent = 0.0f;
                CGFloat runDescent = 0.0f;
                
                runBounds.size.width = CTRunGetTypographicBounds((__bridge CTRunRef)glyphRun, CFRangeMake(0, 0), &runAscent, &runDescent, NULL) + fillPadding.left + fillPadding.right;
                runBounds.size.height = runAscent + runDescent + fillPadding.top + fillPadding.bottom;
                
                CGFloat xOffset = CTLineGetOffsetForStringIndex((__bridge CTLineRef)line, CTRunGetStringRange((__bridge CTRunRef)glyphRun).location, NULL);
                runBounds.origin.x = origins[lineIndex].x + rect.origin.x + xOffset - fillPadding.left;
                runBounds.origin.y = origins[lineIndex].y + rect.origin.y + yOffset - fillPadding.bottom;
                runBounds.origin.y -= runDescent;
                
                // Don't draw higlightedLinkBackground too far to the right
                if (CGRectGetWidth(runBounds) > CGRectGetWidth(lineBounds)) {
                    runBounds.size.width = CGRectGetWidth(lineBounds);
                }
                
                CGPathRef path = [[UIBezierPath bezierPathWithRoundedRect:CGRectInset(CGRectInset(runBounds, -1.0f, -3.0f), lineWidth, lineWidth) cornerRadius:cornerRadius] CGPath];
                
                CGContextSetLineJoin(c, kCGLineJoinRound);
                
                if (fillColor) {
                    CGContextSetFillColorWithColor(c, fillColor);
                    CGContextAddPath(c, path);
                    CGContextFillPath(c);
                }
                
                if (strokeColor) {
                    CGContextSetStrokeColorWithColor(c, strokeColor);
                    CGContextAddPath(c, path);
                    CGContextStrokePath(c);
                }
            }
        }
        
        lineIndex++;
    }
}

- (void)drawStrike:(CTFrameRef)frame
            inRect:(CGRect)rect
           context:(CGContextRef)c
{
    NSArray *lines = (__bridge NSArray *)CTFrameGetLines(frame);
    CGPoint origins[[lines count]];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), origins);
    
    CFIndex lineIndex = 0;
    for (id line in lines) {        
        CGFloat ascent = 0.0f, descent = 0.0f, leading = 0.0f;
        CGFloat width = CTLineGetTypographicBounds((__bridge CTLineRef)line, &ascent, &descent, &leading) ;
        CGRect lineBounds = CGRectMake(0.0f, 0.0f, width, ascent + descent + leading) ;
        lineBounds.origin.x = origins[lineIndex].x;
        lineBounds.origin.y = origins[lineIndex].y;
        
        for (id glyphRun in (__bridge NSArray *)CTLineGetGlyphRuns((__bridge CTLineRef)line)) {
            NSDictionary *attributes = (__bridge NSDictionary *)CTRunGetAttributes((__bridge CTRunRef) glyphRun);
            BOOL strikeOut = [[attributes objectForKey:kTTTStrikeOutAttributeName] boolValue];
            NSInteger superscriptStyle = [[attributes objectForKey:(id)kCTSuperscriptAttributeName] integerValue];
            
            if (strikeOut) {
                CGRect runBounds = CGRectZero;
                CGFloat runAscent = 0.0f;
                CGFloat runDescent = 0.0f;
                
                runBounds.size.width = CTRunGetTypographicBounds((__bridge CTRunRef)glyphRun, CFRangeMake(0, 0), &runAscent, &runDescent, NULL);
                runBounds.size.height = runAscent + runDescent;
                
                CGFloat xOffset = CTLineGetOffsetForStringIndex((__bridge CTLineRef)line, CTRunGetStringRange((__bridge CTRunRef)glyphRun).location, NULL);
                runBounds.origin.x = origins[lineIndex].x + xOffset;
                runBounds.origin.y = origins[lineIndex].y;
                runBounds.origin.y -= runDescent;
                
                // Don't draw strikeout too far to the right
                if (CGRectGetWidth(runBounds) > CGRectGetWidth(lineBounds)) {
                    runBounds.size.width = CGRectGetWidth(lineBounds);
                }
                
				switch (superscriptStyle) {
					case 1:
						runBounds.origin.y -= runAscent * 0.47f;
						break;
					case -1:
						runBounds.origin.y += runAscent * 0.25f;
						break;
					default:
						break;
				}
                
                // Use text color, or default to black
                id color = [attributes objectForKey:(id)kCTForegroundColorAttributeName];
                if (color) {
                    if ([color isKindOfClass:[UIColor class]]) {
                        CGContextSetStrokeColorWithColor(c, [color CGColor]);
                    } else {
                        CGContextSetStrokeColorWithColor(c, (__bridge CGColorRef)color);
                    }
                } else {
                    CGContextSetGrayStrokeColor(c, 0.0f, 1.0);
                }
                
                CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)self.font.fontName, self.font.pointSize, NULL);
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
        return;
    }
    
    self.attributedText = text;
    self.activeLink = nil;

    self.links = [NSArray array];
    if (self.attributedText && self.dataDetectorTypes) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSArray *results = [self.dataDetector matchesInString:[text string] options:0 range:NSMakeRange(0, [text length])];
            if ([results count] > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([[self.attributedText string] isEqualToString:[text string]]) {
                        [self addLinksWithTextCheckingResults:results attributes:self.linkAttributes];
                    }
                });
            }
        });
    }
        
    [super setText:[self.attributedText string]];
}

- (void)setText:(id)text
afterInheritingLabelAttributesAndConfiguringWithBlock:(NSMutableAttributedString *(^)(NSMutableAttributedString *mutableAttributedString))block
{
    NSMutableAttributedString *mutableAttributedString = nil;
    if ([text isKindOfClass:[NSString class]]) {
        mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:NSAttributedStringAttributesFromLabel(self)];
    } else {
        mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:text];
        [mutableAttributedString addAttributes:NSAttributedStringAttributesFromLabel(self) range:NSMakeRange(0, [mutableAttributedString length])];
    }
    
    if (block) {
        mutableAttributedString = block(mutableAttributedString);
    }
    
    [self setText:mutableAttributedString];
}

- (void)setActiveLink:(NSTextCheckingResult *)activeLink {
    _activeLink = activeLink;

    if (_activeLink && [self.activeLinkAttributes count] > 0) {
        if (!self.inactiveAttributedText) {
            self.inactiveAttributedText = [self.attributedText copy];
        }

        NSMutableAttributedString *mutableAttributedString = [self.inactiveAttributedText mutableCopy];
        [mutableAttributedString addAttributes:self.activeLinkAttributes range:_activeLink.range];
        self.attributedText = mutableAttributedString;

        [self setNeedsDisplay];
    } else if (self.inactiveAttributedText) {
        self.attributedText = self.inactiveAttributedText;
        self.inactiveAttributedText = nil;

        [self setNeedsDisplay];
    }
}

#pragma mark - UILabel

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

// Fixes crash when loading from a UIStoryboard
- (UIColor *)textColor {
	UIColor *color = [super textColor];
	if (!color) {
		color = [UIColor blackColor];
	}
	
	return color;
}

- (void)setTextColor:(UIColor *)textColor {
    UIColor *oldTextColor = self.textColor;
    [super setTextColor:textColor];

    // Redraw to allow any ColorFromContext attributes a chance to update
    if (textColor != oldTextColor) {
        [self setNeedsFramesetter];
        [self setNeedsDisplay];
    }
}

- (CGRect)textRectForBounds:(CGRect)bounds
     limitedToNumberOfLines:(NSInteger)numberOfLines
{
    if (!self.attributedText) {
        return [super textRectForBounds:bounds limitedToNumberOfLines:numberOfLines];
    }
        
    CGRect textRect = bounds;

    // Calculate height with a minimum of double the font pointSize, to ensure that CTFramesetterSuggestFrameSizeWithConstraints doesn't return CGSizeZero, as it would if textRect height is insufficient.
    textRect.size.height = fmaxf(self.font.pointSize * 2.0f, bounds.size.height);

    // Adjust the text to be in the center vertically, if the text size is smaller than bounds
    CGSize textSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, CFRangeMake(0, [self.attributedText length]), NULL, textRect.size, NULL);
    textSize = CGSizeMake(ceilf(textSize.width), ceilf(textSize.height)); // Fix for iOS 4, CTFramesetterSuggestFrameSizeWithConstraints sometimes returns fractional sizes
    
    if (textSize.height < textRect.size.height) {
        CGFloat yOffset = 0.0f;
        switch (self.verticalAlignment) {
            case TTTAttributedLabelVerticalAlignmentCenter:
                yOffset = floorf((bounds.size.height - textSize.height) / 2.0f);
                break;
            case TTTAttributedLabelVerticalAlignmentBottom:
                yOffset = bounds.size.height - textSize.height;
                break;
            case TTTAttributedLabelVerticalAlignmentTop:
            default:
                break;
        }
        
        textRect.origin.y += yOffset;
    }
    
    return textRect;
}

- (void)drawTextInRect:(CGRect)rect {
    if (!self.attributedText) {
        [super drawTextInRect:rect];
        return;
    }
        
    NSAttributedString *originalAttributedText = nil;
    
    // Adjust the font size to fit width, if necessarry 
    if (self.adjustsFontSizeToFitWidth && self.numberOfLines > 0) {
        // Use infinite width to find the max width, which will be compared to availableWidth if needed.
        CGSize maxSize = (self.numberOfLines > 1) ? CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) : CGSizeZero;
        
        CGFloat textWidth = [self sizeThatFits:maxSize].width;
        CGFloat availableWidth = self.frame.size.width * self.numberOfLines;
        if (self.numberOfLines > 1 && self.lineBreakMode == UILineBreakModeWordWrap) {
            textWidth *= kTTTLineBreakWordWrapTextWidthScalingFactor;
        }
        
        if (textWidth > availableWidth && textWidth > 0.0f) {
            originalAttributedText = [self.attributedText copy];
            self.attributedText = NSAttributedStringByScalingFontSize(self.attributedText, availableWidth / textWidth, self.minimumFontSize);
        }
    }
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSaveGState(c); {
        CGContextSetTextMatrix(c, CGAffineTransformIdentity);

        // Inverts the CTM to match iOS coordinates (otherwise text draws upside-down; Mac OS's system is different)
        CGContextTranslateCTM(c, 0.0f, rect.size.height);
        CGContextScaleCTM(c, 1.0f, -1.0f);
        
        CFRange textRange = CFRangeMake(0, [self.attributedText length]);

        // First, get the text rect (which takes vertical centering into account)
        CGRect textRect = [self textRectForBounds:rect limitedToNumberOfLines:self.numberOfLines];

        // CoreText draws it's text aligned to the bottom, so we move the CTM here to take our vertical offsets into account
        CGContextTranslateCTM(c, rect.origin.x, rect.size.height - textRect.origin.y - textRect.size.height);

        // Second, trace the shadow before the actual text, if we have one
        if (self.shadowColor && !self.highlighted) {
            CGContextSetShadowWithColor(c, self.shadowOffset, self.shadowRadius, [self.shadowColor CGColor]);
        } else if (self.highlightedShadowColor) {
            CGContextSetShadowWithColor(c, self.highlightedShadowOffset, self.highlightedShadowRadius, [self.highlightedShadowColor CGColor]);
        }
        
        // Finally, draw the text or highlighted text itself (on top of the shadow, if there is one)
        if (self.highlightedTextColor && self.highlighted) {
            NSMutableAttributedString *highlightAttributedString = [self.renderedAttributedText mutableCopy];
            [highlightAttributedString addAttribute:(__bridge NSString *)kCTForegroundColorAttributeName value:(id)[self.highlightedTextColor CGColor] range:NSMakeRange(0, highlightAttributedString.length)];
            
            if (!self.highlightFramesetter) {
                self.highlightFramesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)highlightAttributedString);
            }
            
            [self drawFramesetter:self.highlightFramesetter attributedString:highlightAttributedString textRange:textRange inRect:textRect context:c];
        } else {
            [self drawFramesetter:self.framesetter attributedString:self.renderedAttributedText textRange:textRange inRect:textRect context:c];
        }  
        
        // If we adjusted the font size, set it back to its original size
        if (originalAttributedText) {
            self.attributedText = originalAttributedText;
        }
    } CGContextRestoreGState(c);
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
        CGPathAddRect(path, NULL, CGRectMake(0.0f, 0.0f, constraints.width, CGFLOAT_MAX));
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

- (CGSize)intrinsicContentSize {
    // There's an implicit width from the original UILabel implementation
    return [self sizeThatFits:[super intrinsicContentSize]];
}

#pragma mark - UIResponder

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
        NSTextCheckingResult *result = self.activeLink;
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

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];

    [coder encodeInteger:self.dataDetectorTypes forKey:@"dataDetectorTypes"];
    [coder encodeObject:self.links forKey:@"links"];
    if ([NSMutableParagraphStyle class]) {
        [coder encodeObject:self.linkAttributes forKey:@"linkAttributes"];
        [coder encodeObject:self.activeLinkAttributes forKey:@"activeLinkAttributes"];
    }
    [coder encodeFloat:self.shadowRadius forKey:@"shadowRadius"];
    [coder encodeFloat:self.highlightedShadowRadius forKey:@"highlightedShadowRadius"];
    [coder encodeCGSize:self.highlightedShadowOffset forKey:@"highlightedShadowOffset"];
    [coder encodeObject:self.highlightedShadowColor forKey:@"highlightedShadowColor"];
    [coder encodeFloat:self.firstLineIndent forKey:@"firstLineIndent"];
    [coder encodeFloat:self.leading forKey:@"leading"];
    [coder encodeFloat:self.lineHeightMultiple forKey:@"lineHeightMultiple"];
    [coder encodeUIEdgeInsets:self.textInsets forKey:@"textInsets"];
    [coder encodeInteger:self.verticalAlignment forKey:@"verticalAlignment"];
    [coder encodeObject:self.truncationTokenString forKey:@"truncationTokenString"];
    [coder encodeObject:self.attributedText forKey:@"attributedText"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (!self) {
        return nil;
    }

    [self commonInit];

    if ([coder containsValueForKey:@"dataDetectorTypes"]) {
        self.dataDetectorTypes = [coder decodeIntegerForKey:@"dataDetectorTypes"];
    }

    if ([coder containsValueForKey:@"links"]) {
        self.links = [coder decodeObjectForKey:@"links"];
    }

    if ([NSMutableParagraphStyle class]) {
        if ([coder containsValueForKey:@"linkAttributes"]) {
            self.linkAttributes = [coder decodeObjectForKey:@"linkAttributes"];
        }

        if ([coder containsValueForKey:@"activeLinkAttributes"]) {
            self.activeLinkAttributes = [coder decodeObjectForKey:@"activeLinkAttributes"];
        }
    }

    if ([coder containsValueForKey:@"shadowRadius"]) {
        self.shadowRadius = [coder decodeFloatForKey:@"shadowRadius"];
    }

    if ([coder containsValueForKey:@"highlightedShadowRadius"]) {
        self.highlightedShadowRadius = [coder decodeFloatForKey:@"highlightedShadowRadius"];
    }

    if ([coder containsValueForKey:@"highlightedShadowOffset"]) {
        self.highlightedShadowOffset = [coder decodeCGSizeForKey:@"highlightedShadowOffset"];
    }

    if ([coder containsValueForKey:@"highlightedShadowColor"]) {
        self.highlightedShadowColor = [coder decodeObjectForKey:@"highlightedShadowColor"];
    }

    if ([coder containsValueForKey:@"firstLineIndent"]) {
        self.firstLineIndent = [coder decodeFloatForKey:@"firstLineIndent"];
    }

    if ([coder containsValueForKey:@"leading"]) {
        self.leading = [coder decodeFloatForKey:@"leading"];
    }

    if ([coder containsValueForKey:@"lineHeightMultiple"]) {
        self.lineHeightMultiple = [coder decodeFloatForKey:@"lineHeightMultiple"];
    }

    if ([coder containsValueForKey:@"textInsets"]) {
        self.textInsets = [coder decodeUIEdgeInsetsForKey:@"textInsets"];
    }

    if ([coder containsValueForKey:@"verticalAlignment"]) {
        self.verticalAlignment = [coder decodeIntegerForKey:@"verticalAlignment"];
    }

    if ([coder containsValueForKey:@"truncationTokenString"]) {
        self.truncationTokenString = [coder decodeObjectForKey:@"truncationTokenString"];
    }

    if ([coder containsValueForKey:@"attributedText"]) {
        self.attributedText = [coder decodeObjectForKey:@"attributedText"];
    }

    return self;
}

@end

#pragma clang diagnostic pop
