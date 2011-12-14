//
//  RespectMinFontSize.h
//  TTTAttributedLabelTests
//
//  Created by Mark Makdad on 12/13/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"

@interface OnlyChangeFontSizeWhenOneLine : UIViewController

@property (nonatomic, retain) IBOutlet TTTAttributedLabel *twoLineLabel;
@property (nonatomic, retain) IBOutlet TTTAttributedLabel *oneLineLabel;

@end
