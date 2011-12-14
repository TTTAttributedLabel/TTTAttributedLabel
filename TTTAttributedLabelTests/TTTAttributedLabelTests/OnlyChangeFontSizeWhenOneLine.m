//
//  RespectMinFontSize.m
//  TTTAttributedLabelTests
//
//  Created by Mark Makdad on 12/13/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "OnlyChangeFontSizeWhenOneLine.h"

@implementation OnlyChangeFontSizeWhenOneLine

@synthesize ourLabel;

- (void) dealloc {
    [ourLabel release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
  
    // Set the attributed string with no attributes
    NSAttributedString *theString = [[[NSAttributedString alloc] initWithString:self.ourLabel.text] autorelease];
  
    // Since our attributable string has no attributes, we would expect drawing
    // to look like the UILabel??
    [self.ourLabel setText:theString afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.ourLabel = nil;
}

@end
