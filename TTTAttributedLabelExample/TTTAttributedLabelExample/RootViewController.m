// RootViewController.m
//
// Copyright (c) 2011 Mattt Thompson (http://mattt.me)
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

#import "RootViewController.h"

static CGFloat const kSummaryTextFontSize = 17;

@implementation RootViewController

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (!self) {
        return nil;
    }
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"espressos" ofType:@"txt"];
    NSArray *espressoTexts = [[NSString stringWithContentsOfFile:filePath usedEncoding:nil error:nil] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *espressos = [NSMutableArray arrayWithCapacity:[espressoTexts count]];
    
    static NSRegularExpression *nameRegularExpression;
    static NSRegularExpression *parenthesisRegularExpression;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nameRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"^\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
        parenthesisRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"\\([^\\(\\)]+\\)" options:NSRegularExpressionCaseInsensitive error:nil];
    });
    
    [espressoTexts enumerateObjectsUsingBlock:^(id string, NSUInteger idx, BOOL *stop) {
        NSMutableAttributedString *mutableAttributedString = [[[NSMutableAttributedString alloc] initWithString:string] autorelease];
        NSRange stringRange = NSMakeRange(0, [mutableAttributedString length]);
        
        UIFont *systemFont = [UIFont systemFontOfSize:kSummaryTextFontSize]; 
        CTFontRef plainFont = CTFontCreateWithName((CFStringRef)systemFont.fontName, systemFont.pointSize, NULL);
        if (plainFont) {
            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)plainFont range:stringRange];
        }
        
        NSRange nameRange = [nameRegularExpression rangeOfFirstMatchInString:[mutableAttributedString string] options:0 range:stringRange];
        UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:kSummaryTextFontSize]; 
        CTFontRef boldFont = CTFontCreateWithName((CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
        if (boldFont) {
            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)boldFont range:nameRange];
            CFRelease(boldFont);
        }
        
        [mutableAttributedString replaceCharactersInRange:nameRange withString:[[[mutableAttributedString string] substringWithRange:nameRange] uppercaseString]];
        
        [parenthesisRegularExpression enumerateMatchesInString:[mutableAttributedString string] options:0 range:stringRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {            
            UIFont *italicSystemFont = [UIFont italicSystemFontOfSize:kSummaryTextFontSize];
            CTFontRef italicFont = CTFontCreateWithName((CFStringRef)italicSystemFont.fontName, italicSystemFont.pointSize, NULL);
            if (italicFont) {
                [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)italicFont range:result.range];
                CFRelease(italicFont);
                
                [mutableAttributedString addAttribute:(NSString*)kCTForegroundColorAttributeName value:(id)[[UIColor grayColor] CGColor] range:result.range];
            }
        }];
        
        [espressos addObject:mutableAttributedString];
    }];
    
    _espressos = [espressos copy];
    _checkedIndexPaths = [[NSMutableSet alloc] init];
    
    _sizingCell = [[TTTAttributedTableViewCell alloc] initWithReuseIdentifier:nil];
    _sizingCell.attributedLabel.font = [UIFont systemFontOfSize:17.0];
    
    return self;
}

- (void)dealloc {
    [_espressos release];
    [_checkedIndexPaths release];
    [_sizingCell release];
    [super dealloc];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Espressos", nil);
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_espressos count];
}

- (void)updateCell:(TTTAttributedTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.attributedLabel.text = [_espressos objectAtIndex:indexPath.row];
    cell.accessoryType = [_checkedIndexPaths containsObject:indexPath] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateCell:_sizingCell forRowAtIndexPath:indexPath];
    return [_sizingCell heightForTableView:tableView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    TTTAttributedTableViewCell *cell = (TTTAttributedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[TTTAttributedTableViewCell alloc] initWithReuseIdentifier:CellIdentifier] autorelease];
        cell.attributedLabel.font = [UIFont systemFontOfSize:17.0];
        cell.attributedLabel.delegate = self;
        cell.attributedLabel.userInteractionEnabled = YES;
    }
    
    [self updateCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Since setting the accessory may change the cell's height, wrap these
    // changes in beginUpdates/endUpdates.
    [tableView beginUpdates];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([_checkedIndexPaths containsObject:indexPath]) {
        [_checkedIndexPaths removeObject:indexPath];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    } else {
        [_checkedIndexPaths addObject:indexPath];
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    [tableView endUpdates];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [[[[UIActionSheet alloc] initWithTitle:[url absoluteString] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Open in Link Safari", nil), nil] autorelease] showInView:self.view];
}

#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:actionSheet.title]];
}

@end
