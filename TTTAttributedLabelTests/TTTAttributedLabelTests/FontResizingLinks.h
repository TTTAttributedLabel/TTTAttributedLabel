//
//  FontResizingLinks.h
//  TTTAttributedLabelTests
//
//  Created by Mark Makdad on 12/16/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"

@interface FontResizingLinks : UIViewController <TTTAttributedLabelDelegate>
@property (retain, nonatomic) IBOutlet TTTAttributedLabel *linkLabel;

@end
