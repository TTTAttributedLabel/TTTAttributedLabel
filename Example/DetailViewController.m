// EspressoViewController.m
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

#import "DetailViewController.h"
#import "TTTAttributedLabel.h"

static CGFloat const kEspressoDescriptionTextFontSize = 17.0f;

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

@interface DetailViewController () <TTTAttributedLabelDelegate, UIActionSheetDelegate>
@property (nonatomic, copy) NSString *espressoDescription;
@property (nonatomic) TTTAttributedLabel *attributedLabel;
@end

@implementation DetailViewController

- (instancetype)initWithEspressoDescription:(NSString *)espresso {
    self = [super initWithNibName:nil bundle:nil];
    if (!self) {
        return nil;
    }
    
    self.espressoDescription = espresso;
    
    return self;
}

#pragma mark - UIViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.attributedLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectInset(self.view.bounds, 10.0f, 70.0f)];
    self.attributedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.attributedLabel];

    self.title = NSLocalizedString(@"Espresso", nil);
    
    self.attributedLabel.delegate = self;
    UIFont *f = [UIFont systemFontOfSize:kEspressoDescriptionTextFontSize];
    self.attributedLabel.font = f;
    self.attributedLabel.textColor = [UIColor darkGrayColor];
    self.attributedLabel.numberOfLines = 0;
    self.attributedLabel.linkAttributes = @{NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)};
    
    self.attributedLabel.highlightedTextColor = [UIColor whiteColor];
    self.attributedLabel.shadowColor = [UIColor colorWithWhite:0.87f alpha:1.0f];
    self.attributedLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);

    self.attributedLabel.attributedText = [self attributedEspressoDescription];
    
    NSRegularExpression *regexp = NameRegularExpression();
    NSRange linkRange = [regexp rangeOfFirstMatchInString:self.espressoDescription options:0 range:NSMakeRange(0, (self.espressoDescription).length)];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://en.wikipedia.org/wiki/%@", [self.espressoDescription substringWithRange:linkRange]]];
    [self.attributedLabel addLinkToURL:url withRange:linkRange];
}

- (NSAttributedString *) attributedEspressoDescription {
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:self.espressoDescription];
    NSRange stringRange = NSMakeRange(0, [mutableAttributedString length]);
    
    NSRegularExpression *regexp = NameRegularExpression();
    NSRange nameRange = [regexp rangeOfFirstMatchInString:[mutableAttributedString string] options:0 range:stringRange];
    UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:kEspressoDescriptionTextFontSize];
    [mutableAttributedString removeAttribute:NSFontAttributeName range:nameRange];
    [mutableAttributedString addAttribute:NSFontAttributeName value:boldSystemFont range:nameRange];
    
    [mutableAttributedString replaceCharactersInRange:nameRange withString:[[[mutableAttributedString string] substringWithRange:nameRange] uppercaseString]];
    
    regexp = ParenthesisRegularExpression();
    [regexp enumerateMatchesInString:[mutableAttributedString string] options:0 range:stringRange usingBlock:^(NSTextCheckingResult *result, __unused NSMatchingFlags flags, __unused BOOL * stop) {
        UIFont *italicSystemFont = [UIFont italicSystemFontOfSize:kEspressoDescriptionTextFontSize];
        [mutableAttributedString removeAttribute:NSFontAttributeName range:result.range];
        [mutableAttributedString addAttribute:NSFontAttributeName value:italicSystemFont range:result.range];
        
        [mutableAttributedString removeAttribute:NSForegroundColorAttributeName range:result.range];
        [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:result.range];
    }];
    
    return mutableAttributedString;
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(__unused TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)url
{
    [[[UIActionSheet alloc] initWithTitle:url.absoluteString delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Open Link in Safari", nil), nil] showInView:self.view];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:actionSheet.title]];
}

@end
