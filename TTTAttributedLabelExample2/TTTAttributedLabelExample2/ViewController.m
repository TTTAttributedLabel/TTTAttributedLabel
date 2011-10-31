#import "ViewController.h"
#import "TTTAttributedLabel.h"


@implementation ViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	CGRect attributedLabelFrame = CGRectMake(20, 20, 280, 200);
	
	NSDictionary *linkAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
	                         (id)[[UIColor blueColor] CGColor], (NSString *)kCTForegroundColorAttributeName,
	                              [NSNumber numberWithBool:NO], (NSString *)kCTUnderlineStyleAttributeName, nil];
	
	attributedLabel = [[TTTAttributedLabel alloc] initWithFrame:attributedLabelFrame];
	attributedLabel.backgroundColor = [UIColor lightGrayColor];
	attributedLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0f];;
	attributedLabel.textColor = [UIColor blackColor];
	attributedLabel.linkAttributes = linkAttributes;
	attributedLabel.lineBreakMode = UILineBreakModeWordWrap;
	attributedLabel.numberOfLines = 0;
	attributedLabel.dataDetectorTypes = UIDataDetectorTypeLink;
	attributedLabel.userInteractionEnabled = YES;
	attributedLabel.delegate = self;
	
	attributedLabel.text = @"Try to click this link\nhttp://www.deusty.com\n\nBehold it does not work!";
	
	[[self view] addSubview:attributedLabel];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
	NSLog(@"attributedLabel:didSelectLinkWithURL: %@", url);
}

@end
