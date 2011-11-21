// TTTAttributedTableViewCell.h
//
// Copyright (c) 2011 Adam Ernst (http://adamernst.com)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <UIKit/UIKit.h>
// Directly import the label; usually if you use the cell, you need to use the
// label as well.
#import "TTTAttributedLabel.h"

/**
 `TTTAttributedTableViewCell` is a `UITableViewCell` subclass that manages a `TTTAttributedLabel`.
 
 If you want to have dynamic row heights in your table, the most efficient approach is to keep one `TTTAttributedTableViewCell` instance for use as a sizing template, separate from the cells that are created for the table itself. Use `heightForTableView:` to find the appropriate height, given the attributes of the table and cell.
 */
@interface TTTAttributedTableViewCell : UITableViewCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

/**
 The `TTTAttributedLabel` that is managed by this cell.
 */
@property (nonatomic, retain, readonly) TTTAttributedLabel *attributedLabel;

/**
 A `UIEdgeInsets` object that defines the margin around the attributed label. Defaults to an inset of 12 pixels on each side.
 */
@property (nonatomic) UIEdgeInsets attributedLabelEdgeInsets;

/**
 Call to determine the ideal height for a cell in the given `UITableView`. Respects this cell's `accessoryType` property and the size of `tableView`.
 
 @param tableView The `UITableView` used for sizing the cell. The table view's width and style attributes are accessed.
 */
- (CGFloat)heightForTableView:(UITableView *)tableView;

@end
