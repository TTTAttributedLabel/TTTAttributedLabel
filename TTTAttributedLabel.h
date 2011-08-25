// TTTAttributedLabel.h
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

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

typedef enum {
    TTTAttributedLabelVerticalAlignmentCenter   = 0,
    TTTAttributedLabelVerticalAlignmentTop      = 1,
    TTTAttributedLabelVerticalAlignmentBottom   = 2,
} TTTAttributedLabelVerticalAlignment;

@class TTTAttributedLabel;

@protocol TTTAttributedLabelDelegate <NSObject>
@optional
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url;
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithAddress:(NSDictionary *)addressComponents;
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber;
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithDate:(NSDate *)date;
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithDate:(NSDate *)date timeZone:(NSTimeZone *)timeZone duration:(NSTimeInterval)duration;
@end

// Override UILabel @property to accept both NSString and NSAttributedString
@protocol TTTAttributedLabel <NSObject>
@property (nonatomic, copy) id text;
@end

@interface TTTAttributedLabel : UILabel <TTTAttributedLabel> {
@private
    NSAttributedString *_attributedText;
    CTFramesetterRef _framesetter;
    BOOL _needsFramesetter;
    
    id _delegate;
    UIDataDetectorTypes _dataDetectorTypes;
    NSArray *_links;
    NSDictionary *_linkAttributes;
    TTTAttributedLabelVerticalAlignment _verticalAlignment;
    BOOL _userInteractionDisabled;
}

@property (nonatomic, assign) id <TTTAttributedLabelDelegate> delegate;
@property (nonatomic, assign) UIDataDetectorTypes dataDetectorTypes;
@property (nonatomic, retain) NSDictionary *linkAttributes;
@property (nonatomic, assign) TTTAttributedLabelVerticalAlignment verticalAlignment;
@property (readonly, nonatomic, retain) NSArray *links;

- (void)setText:(id)text afterInheritingLabelAttributesAndConfiguringWithBlock:(NSMutableAttributedString *(^)(NSMutableAttributedString *mutableAttributedString))block;
- (void)setNeedsFramesetter;

- (void)addLinkToURL:(NSURL *)url withRange:(NSRange)range;
- (void)addLinkToAddress:(NSDictionary *)addressComponents withRange:(NSRange)range;
- (void)addLinkToPhoneNumber:(NSString *)phoneNumber withRange:(NSRange)range;
- (void)addLinkToDate:(NSDate *)date withRange:(NSRange)range;
- (void)addLinkToDate:(NSDate *)date timeZone:(NSTimeZone *)timeZone duration:(NSTimeInterval)duration withRange:(NSRange)range;

@end

