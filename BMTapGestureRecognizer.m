//
//  BMTapGestureRecognizer.m
//  tinyreview
//
//  Created by Adrian Cheng Bing Jie on 6/6/12.
//  Copyright (c) 2012 Beeem Inc. All rights reserved.
//

#import "BMTapGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation BMTapGestureRecognizer

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    // turn highlighted text back to original color
    [[NSNotificationCenter defaultCenter] postNotificationName:kCommentedLabelDidMove object:nil];
}

@end
