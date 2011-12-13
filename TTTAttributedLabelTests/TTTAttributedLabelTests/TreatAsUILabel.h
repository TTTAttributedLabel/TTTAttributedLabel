//
//  TTTDetailViewController.h
//  TTTAttributedLabelTests
//
//  Created by Mark Makdad on 12/13/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TreatAsUILabel : UIViewController

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
