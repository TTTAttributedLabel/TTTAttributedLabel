//
//  VerticalAlignment.m
//  TTTAttributedLabelTests
//
//  Created by Mark Makdad on 12/16/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "VerticalAlignment.h"

@implementation VerticalAlignment
@synthesize topLabel;
@synthesize middleLabel;
@synthesize bottomLabel;
@synthesize twoLineTopLabel;
@synthesize twoLineMiddleLabel;
@synthesize twoLineBottomLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
  
    self.topLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    self.twoLineTopLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
  
    self.middleLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentCenter;
    self.twoLineMiddleLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentCenter;
  
    self.bottomLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentBottom;
    self.twoLineBottomLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentBottom;
}

#pragma mark - Class Plumbing

- (void)viewDidUnload
{
    [self setTopLabel:nil];
    [self setMiddleLabel:nil];
    [self setBottomLabel:nil];
    [self setTwoLineTopLabel:nil];
    [self setTwoLineMiddleLabel:nil];
    [self setTwoLineBottomLabel:nil];
    [super viewDidUnload];
}

- (void)dealloc {
    [topLabel release];
    [middleLabel release];
    [bottomLabel release];
    [twoLineTopLabel release];
    [twoLineMiddleLabel release];
    [twoLineBottomLabel release];
    [super dealloc];
}
@end
