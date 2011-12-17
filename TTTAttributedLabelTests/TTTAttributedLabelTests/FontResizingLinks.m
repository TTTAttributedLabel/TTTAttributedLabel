//
//  FontResizingLinks.m
//  TTTAttributedLabelTests
//
//  Created by Mark Makdad on 12/16/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "FontResizingLinks.h"

@implementation FontResizingLinks
@synthesize linkLabel;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
  
  // We have to set this programmatically.  Ideally, 
    self.linkLabel.dataDetectorTypes = UIDataDetectorTypeLink;
  self.linkLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentCenter;
  //   self.linkLabel.text = self.linkLabel.text;
}

- (void)viewDidUnload
{
  [self setLinkLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
  [linkLabel release];
  [super dealloc];
}
@end
