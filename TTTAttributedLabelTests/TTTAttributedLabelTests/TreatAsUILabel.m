//
//  TTTDetailViewController.m
//  TTTAttributedLabelTests
//
//  Created by Mark Makdad on 12/13/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "TreatAsUILabel.h"

@implementation TreatAsUILabel

@synthesize label;

- (void)dealloc
{
    [label release];
    [super dealloc];
}
							
@end
