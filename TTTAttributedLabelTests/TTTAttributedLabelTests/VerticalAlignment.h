//
//  VerticalAlignment.h
//  TTTAttributedLabelTests
//
//  Created by Mark Makdad on 12/16/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"

@interface VerticalAlignment : UIViewController
@property (retain, nonatomic) IBOutlet TTTAttributedLabel *topLabel;
@property (retain, nonatomic) IBOutlet TTTAttributedLabel *middleLabel;
@property (retain, nonatomic) IBOutlet TTTAttributedLabel *bottomLabel;
@property (retain, nonatomic) IBOutlet TTTAttributedLabel *twoLineTopLabel;
@property (retain, nonatomic) IBOutlet TTTAttributedLabel *twoLineMiddleLabel;
@property (retain, nonatomic) IBOutlet TTTAttributedLabel *twoLineBottomLabel;

@end
