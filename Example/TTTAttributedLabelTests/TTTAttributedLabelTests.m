//
//  TTTAttributedLabelTests.m
//  TTTAttributedLabelTests
//
//  Created by Jonathan Hersh on 12/5/14.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <TTTAttributedLabel.h>
#import <FBSnapshotTestCase.h>

static NSString * const kTestLabelText = @"Pallando, Merlyn, and Melisandre were walking one day...";
static CGSize const kTestLabelSize = (CGSize) { 90, CGFLOAT_MAX };

static inline NSAttributedString * TTTAttributedTestString() {
    return [[NSAttributedString alloc] initWithString:kTestLabelText
                                           attributes:@{
                                                    NSForegroundColorAttributeName : [UIColor redColor],
                                                    NSFontAttributeName : [UIFont boldSystemFontOfSize:16.f],
                                           }];
}

static inline void TTTSizeAttributedLabel(TTTAttributedLabel *label) {
    CGSize size = [TTTAttributedLabel sizeThatFitsAttributedString:label.attributedText
                                                   withConstraints:kTestLabelSize
                                            limitedToNumberOfLines:0];
    
    [label setFrame:CGRectMake(0, 0, size.width, size.height)];
};

@interface TTTAttributedLabelTests : FBSnapshotTestCase

@end

@implementation TTTAttributedLabelTests
{
    TTTAttributedLabel *label; // system under test
    NSURL *testURL;
}

- (void)setUp {
    [super setUp];
    
    label = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
    label.numberOfLines = 0;
    label.textColor = [UIColor redColor];
    label.font = [UIFont boldSystemFontOfSize:16.f];
    
    testURL = [NSURL URLWithString:@"http://helios.io"];
    
    // Compatibility fix for intermittently non-rendering images
    self.renderAsLayer = YES;
    
    // Enable recording mode to record and save reference images for tests
//    self.recordMode = YES;
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInitializable {
    XCTAssertNotNil(label, @"Label should be initializable");
}

- (void)testAttributedTextAccess {
    label.text = TTTAttributedTestString();
    XCTAssertTrue([label.attributedText isEqualToAttributedString:TTTAttributedTestString()], @"Attributed strings should match");
}

- (void)testMultilineLabelSizing {
    NSAttributedString *testString = TTTAttributedTestString();
    
    CGSize size = [TTTAttributedLabel sizeThatFitsAttributedString:testString
                                                   withConstraints:kTestLabelSize
                                            limitedToNumberOfLines:0];
    
    UIFont *font = [testString attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
    XCTAssertGreaterThan(size.height, font.pointSize, @"Text should size to more than one line");
}

- (void)testContainsLinkAtPoint {
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    XCTAssertTrue([label containslinkAtPoint:CGPointMake(5, 5)], @"Label should contain a link at the start of the string");
}

- (void)testLinkArray {
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(0, 1)];
    
    XCTAssertNotNil(label.links, @"Label should have a links array");
    
    NSTextCheckingResult *result = label.links[0];
    XCTAssertEqual(result.resultType, NSTextCheckingTypeLink, @"Should be a link checking result");
    XCTAssertTrue(result.range.location == 0 && result.range.length == 1, @"Link range should match");
    XCTAssertEqualObjects(result.URL, testURL, @"Should set and retrieve test URL");
}

- (void)testMultilineLabelView {
    label.text = TTTAttributedTestString();
    TTTSizeAttributedLabel(label);
    FBSnapshotVerifyView(label, nil);
}

- (void)testLinkifiedLabelView {
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(1, 3)];
    TTTSizeAttributedLabel(label);
    FBSnapshotVerifyView(label, nil);
}

- (void)testLinkAttributeLabelView {
    label.linkAttributes = @{ kTTTBackgroundFillColorAttributeName : (id)[UIColor greenColor].CGColor };
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(10, 6)];
    TTTSizeAttributedLabel(label);
    FBSnapshotVerifyView(label, nil);
}

@end
