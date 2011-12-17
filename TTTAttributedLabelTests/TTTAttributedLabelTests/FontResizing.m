//
//  FontResizing.m
//  TTTAttributedLabelTests
//
//  Created by Mark Makdad on 12/16/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "FontResizing.h"

@interface FontResizing ()
- (void) runAnimationOnView:(UIView *)labelView expand:(BOOL)isExpanding;
@property CGSize oldSize;
@end

@implementation FontResizing
@synthesize attributedLabel;
@synthesize normalLabel;
@synthesize oldSize;

#define TTT_EXPAND 4
#define TTT_CONTRACT 1/TTT_EXPAND
#define TTT_DURATION 3

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction) runAnimations:(id)sender
{
  // Animate both labels repeatedly so we can observer its auto-font-resizing behavior.
  [self runAnimationOnView:self.attributedLabel expand:YES];
  [self runAnimationOnView:self.normalLabel expand:YES];
}


- (void) runAnimationOnView:(UIView *)labelView expand:(BOOL)isExpanding
{
  // This stops the block from causing a retain cycle
  __block FontResizing *blockSelf = self;
  
  [UIView animateWithDuration:TTT_DURATION animations:^ {
      blockSelf.oldSize = labelView.frame.size;
      CGFloat n = (isExpanding) ? TTT_EXPAND : TTT_CONTRACT;
      labelView.frame = CGRectMake(labelView.frame.origin.x, labelView.frame.origin.y,
                                   labelView.frame.size.width * n, labelView.frame.size.height);
  } completion:^(BOOL finished) {
      if (finished) {
        CGRect newFrame = labelView.frame;
        newFrame.size = blockSelf.oldSize;
        labelView.frame = newFrame;
      }
  }];
}

#pragma mark - Class Plumbing

- (void)viewDidUnload
{
    [self setAttributedLabel:nil];
    [self setNormalLabel:nil];
    [super viewDidUnload];
}

- (void)dealloc {
    [attributedLabel release];
    [normalLabel release];
    [super dealloc];
}
@end
