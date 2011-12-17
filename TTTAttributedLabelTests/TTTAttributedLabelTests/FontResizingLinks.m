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
    
    // Turn link detection "on" in the label.  There's no way to set this in the XIB.
    self.linkLabel.dataDetectorTypes = UIDataDetectorTypeLink;
  
    // So we can confirm link tapping is working
    self.linkLabel.delegate = self;
}

#pragma mark - TTTAttributedLabelDelegate

- (void) attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"URL Tapped"
                                                     message:[url description]
                                                    delegate:nil
                                           cancelButtonTitle:nil
                                           otherButtonTitles:@"OK", nil] autorelease];
    [alert show];
}

#pragma mark - Class Plumbing

- (void)viewDidUnload
{
    [self setLinkLabel:nil];
    [super viewDidUnload];
}

- (void)dealloc {
    [linkLabel release];
    [super dealloc];
}
@end
