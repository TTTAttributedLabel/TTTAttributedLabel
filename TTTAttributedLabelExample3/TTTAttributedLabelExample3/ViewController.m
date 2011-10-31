#import "ViewController.h"


@implementation ViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section
{
	return 2;
}

- (CGFloat)tableView:(UITableView *)sender heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 150;
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"TTTCell";
	
	UITableViewCell *cell;
	TTTAttributedLabel *attributedLabel;
	
	
	cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
		                               reuseIdentifier:CellIdentifier] autorelease];
		
		CGRect attributedLabelFrame = CGRectMake(10, 25, 300, 100);
		
		NSDictionary *linkAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
										(id)[[UIColor blueColor] CGColor], (NSString *)kCTForegroundColorAttributeName,
										[NSNumber numberWithBool:NO], (NSString *)kCTUnderlineStyleAttributeName, nil];
		
		attributedLabel = [[[TTTAttributedLabel alloc] initWithFrame:attributedLabelFrame] autorelease];
		attributedLabel.backgroundColor = [UIColor lightGrayColor];
		attributedLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0f];;
		attributedLabel.textColor = [UIColor blackColor];
		attributedLabel.linkAttributes = linkAttributes;
		attributedLabel.lineBreakMode = UILineBreakModeWordWrap;
		attributedLabel.numberOfLines = 0;
		attributedLabel.dataDetectorTypes = UIDataDetectorTypeLink;
		attributedLabel.userInteractionEnabled = YES;
		attributedLabel.delegate = self;
		attributedLabel.tag = 1;
		
		[[cell contentView] addSubview:attributedLabel];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	else
	{
		attributedLabel = (TTTAttributedLabel *)[[cell contentView] viewWithTag:1];
	}
	
	
	if (indexPath.row == 0)
	{
		attributedLabel.text = @"Tap anywhere on this cell, and didSelectRow will fire.\n"
		                       @"\n"
		                       @"Notice this cell doesn't have any links...";
	}
	else
	{
		attributedLabel.text = @"Tap anywhere in the GRAY of this cell.\n"
		                       @"Now tap anywhere in the WHITE of this cell.\n"
		                       @"\n"
		                       @"It has a link: http://www.deusty.com";
	}
	
	return cell;
}

- (void)tableView:(UITableView *)sender didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSLog(@"tableView: didSelectRowAtIndexPath: %lu", (unsigned long)indexPath.row);
	
	[sender deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
	NSLog(@"attributedLabel: didSelectLinkWithURL:");
}

@end
