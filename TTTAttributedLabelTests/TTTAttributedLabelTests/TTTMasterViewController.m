//
//  TTTMasterViewController.m
//  TTTAttributedLabelTests
//
//  Created by Mark Makdad on 12/13/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "TTTMasterViewController.h"

@implementation TTTMasterViewController

@synthesize testArray = _testArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"TTTAttributedLabel Tests", @"TTTAttributedLabel Tests");
        _testArray = [[NSArray alloc] initWithObjects:
                      @"TreatAsUILabel",
                      //@"AddNewTestControllerNameHere"
                      nil];
    }
    return self;
}

- (void) dealloc
{
    [_testArray release];
    [super dealloc];
}
							
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_testArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.text = [_testArray objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  Class controller = NSClassFromString([_testArray objectAtIndex:indexPath.row]);
  if (controller != nil) {
    id testController = [[controller alloc] init];
    if ([testController isKindOfClass:[UIViewController class]]) {
      [self.navigationController pushViewController:testController animated:YES];
    }
    [testController release];
  }
}

@end
