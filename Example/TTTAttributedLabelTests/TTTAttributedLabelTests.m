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
#import <Expecta.h>
#import <OCMock.h>
#import <KIF.h>

static NSString * const kTestLabelText = @"Pallando, Merlyn, and Melisandre were walking one day...";
static CGSize const kTestLabelSize = (CGSize) { 90, CGFLOAT_MAX };

static inline NSDictionary * TTTAttributedTestAttributesDictionary() {
    return @{NSForegroundColorAttributeName : [UIColor redColor],
             NSFontAttributeName : [UIFont boldSystemFontOfSize:16.f]};
}

static inline NSAttributedString * TTTAttributedTestString() {
    return [[NSAttributedString alloc] initWithString:kTestLabelText
                                           attributes:TTTAttributedTestAttributesDictionary()];
}

static inline void TTTSizeAttributedLabel(TTTAttributedLabel *label) {
    CGSize size = [TTTAttributedLabel sizeThatFitsAttributedString:label.attributedText
                                                   withConstraints:kTestLabelSize
                                            limitedToNumberOfLines:0];
    [label setFrame:CGRectMake(0, 0, size.width, size.height)];
};

static inline void TTTSimulateTapOnLabelAtPoint(TTTAttributedLabel *label, CGPoint point) {
    UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
    [window addSubview:label];
    [label tapAtPoint:point];
};

static inline void TTTSimulateLongPressOnLabelAtPointWithDuration(TTTAttributedLabel *label, CGPoint point, NSTimeInterval duration) {
    UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
    [window addSubview:label];
    [label longPressAtPoint:point duration:duration];
};


@interface TTTAttributedLabelTests : FBSnapshotTestCase

@end

@implementation TTTAttributedLabelTests
{
    TTTAttributedLabel *label; // system under test
    NSURL *testURL;
    OCMockObject *TTTDelegateMock;
}

- (void)setUp {
    [super setUp];
    
    label = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
    label.numberOfLines = 0;
    
    testURL = [NSURL URLWithString:@"http://helios.io"];
    
    TTTDelegateMock = OCMProtocolMock(@protocol(TTTAttributedLabelDelegate));
    label.delegate = (id <TTTAttributedLabelDelegate>)TTTDelegateMock;

    // Enable recording mode to record and save reference images for tests
//    self.recordMode = YES;
}

- (void)tearDown {
    [super tearDown];
    
    label.delegate = nil;
    label = nil;
}

#pragma mark - Logic tests

- (void)testInitializable {
    XCTAssertNotNil(label, @"Label should be initializable");
}

- (void)testContentSize {
    label.text = TTTAttributedTestString();
    expect([label intrinsicContentSize]).to.equal([label sizeThatFits:CGSizeZero]);
    label.text = kTestLabelText;
    expect([label intrinsicContentSize]).to.equal([label sizeThatFits:CGSizeZero]);
}

- (void)testHighlighting {
    label.text = TTTAttributedTestString();
    [label setHighlighted:YES];
    expect(label.highlighted).to.beTruthy();
}

- (void)testAttributedTextAccess {
    label.text = TTTAttributedTestString();
    XCTAssertTrue([label.attributedText isEqualToAttributedString:TTTAttributedTestString()], @"Attributed strings should match");
}

- (void)testLinkTintColor {
    label.tintColor = [UIColor whiteColor];
    
    label.inactiveLinkAttributes = @{ kTTTBackgroundFillColorAttributeName : (id)[UIColor grayColor].CGColor };
    label.activeLinkAttributes = @{ kTTTBackgroundFillColorAttributeName : (id)[UIColor redColor].CGColor };
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(0, 4)];

    // Set active
    label.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
    label.tintColor = [UIColor redColor];
    
    expect([label.attributedText attribute:kTTTBackgroundFillColorAttributeName atIndex:0 effectiveRange:NULL]).to.beNil();
}

- (void)testDerivedAttributedString {
    label.font = [UIFont italicSystemFontOfSize:15.f];
    label.textColor = [UIColor purpleColor];
    label.kern = 0.f;
    label.text = kTestLabelText;
    
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.lineHeightMultiple = label.lineHeightMultiple;
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.lineSpacing = label.lineSpacing;
    style.alignment = label.textAlignment;
    style.minimumLineHeight = label.font.lineHeight * label.lineHeightMultiple;
    style.maximumLineHeight = label.font.lineHeight * label.lineHeightMultiple;
    style.firstLineHeadIndent = label.firstLineIndent;
    
    NSAttributedString *derivedString = [[NSAttributedString alloc] initWithString:kTestLabelText
                                                                        attributes:@{
                                                                            (id)kCTFontAttributeName : label.font,
                                                                            (id)kCTForegroundColorAttributeName : label.textColor,
                                                                            (id)kCTKernAttributeName : @(label.kern),
                                                                            (id)kCTParagraphStyleAttributeName : style
                                                                        }];
    
    XCTAssertTrue([label.attributedText isEqualToAttributedString:derivedString],
                  @"Should properly derive an attributed string");
}

- (void)testEmptyAttributedStringSizing {
    XCTAssertTrue(CGSizeEqualToSize(CGSizeZero, [TTTAttributedLabel sizeThatFitsAttributedString:nil
                                                                                 withConstraints:CGSizeMake(10, CGFLOAT_MAX)
                                                                          limitedToNumberOfLines:0]),
                  @"nil string should size to empty");
    XCTAssertTrue(CGSizeEqualToSize(CGSizeZero, [TTTAttributedLabel sizeThatFitsAttributedString:[[NSAttributedString alloc] initWithString:@""]
                                                                                 withConstraints:CGSizeMake(10, CGFLOAT_MAX)
                                                                          limitedToNumberOfLines:0]),
                  @"empty string should size to zero");
}

- (void)testSingleLineLabelSizing {
    NSAttributedString *testString = TTTAttributedTestString();
    label.text = testString;
    
    CGSize lineSize = [TTTAttributedLabel sizeThatFitsAttributedString:testString
                                                       withConstraints:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                                limitedToNumberOfLines:1];
    
    UIFont *font = [testString attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
    XCTAssertLessThan(lineSize.height, font.pointSize * 2, @"Label should size to less than two lines");
}

- (void)testMultilineLabelSizing {
    NSAttributedString *testString = TTTAttributedTestString();
    
    CGSize size = [TTTAttributedLabel sizeThatFitsAttributedString:testString
                                                   withConstraints:kTestLabelSize
                                            limitedToNumberOfLines:0];
    
    UIFont *font = [testString attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
    XCTAssertGreaterThan(size.height, font.pointSize, @"Text should size to more than one line");
    
    size = [TTTAttributedLabel sizeThatFitsAttributedString:testString
                                            withConstraints:kTestLabelSize
                                     limitedToNumberOfLines:2];
    
    font = [testString attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
    XCTAssertGreaterThan(size.height, font.pointSize, @"Text should size to more than one line");
}

- (void)testContainsLinkAtPoint {
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    XCTAssertTrue([label containslinkAtPoint:CGPointMake(5, 5)], @"Label should contain a link at the start of the string");
    XCTAssertFalse([label containslinkAtPoint:CGPointMake(50, 5)], @"Label should not contain a link elsewhere in the string");
}

- (void)testLinkDetection {
    label.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    label.text = [testURL absoluteString];
    
    // Data detection is performed asynchronously in a background thread
    expect([label.links count]).will.equal(1);
    expect(((NSTextCheckingResult *)label.links[0]).URL).will.equal(testURL);
}

- (void)testAttributedStringLinkDetection {
    label.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    label.text = [[NSAttributedString alloc] initWithString:[testURL absoluteString]];
    
    // Data detection is performed asynchronously in a background thread
    expect([label.links count]).will.equal(1);
    expect(((NSTextCheckingResult *)label.links[0]).URL).will.equal(testURL);
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

- (void)testInheritsAttributesFromLabel {
    UIFont *testFont = [UIFont boldSystemFontOfSize:16.f];
    UIColor *testColor = [UIColor greenColor];
    CGFloat testKern = 3.f;
    
    label.font = testFont;
    label.textColor = testColor;
    label.kern = testKern;
    
    __block NSMutableAttributedString *derivedString;
    
    NSMutableAttributedString * (^configureBlock) (NSMutableAttributedString *) = ^NSMutableAttributedString *(NSMutableAttributedString *inheritedString)
    {
        XCTAssertEqualObjects(testFont,
                              [inheritedString attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL],
                              @"Inherited font should match");
        XCTAssertEqualObjects(testColor,
                              [inheritedString attribute:(NSString *)kCTForegroundColorAttributeName atIndex:0 effectiveRange:NULL],
                              @"Inherited color should match");
        XCTAssertEqualWithAccuracy(testKern,
                                   [[inheritedString attribute:(NSString *)kCTKernAttributeName atIndex:0 effectiveRange:NULL] floatValue],
                                   FLT_EPSILON,
                                   @"Inherited kerning should match");
        
        derivedString = inheritedString;
        
        return inheritedString;
    };
    
    [label setText:@"1.21 GigaWatts!" afterInheritingLabelAttributesAndConfiguringWithBlock:configureBlock];
    
    XCTAssertTrue([label.attributedText isEqualToAttributedString:derivedString],
                  @"Label should ultimately set the derived string as its text");
}

- (void)testSizeToFitRequiresNumberOfLines {
    label.numberOfLines = 0;
    label.attributedTruncationToken = [[NSAttributedString alloc] initWithString:@"[more]"
                                                                      attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:14],
                                                                                    NSForegroundColorAttributeName : [UIColor greenColor] }];
    label.text = [[NSAttributedString alloc] initWithString:@"Test\nString\nWith\nLines"
                                                 attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:15],
                                                               NSForegroundColorAttributeName : [UIColor redColor] }];
    
    [label sizeToFit];
    expect(label.frame.size).to.equal(CGSizeZero);
    
    label.numberOfLines = 2;
    [label sizeToFit];
    expect(label.frame.size).notTo.equal(CGSizeZero);
}

#pragma mark - FBSnapshotTestCase tests

- (void)testAdjustsFontSizeToFitWidth {
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.25f;
    label.numberOfLines = 1;
    label.text = TTTAttributedTestString();
    [label setFrame:CGRectMake(0, 0, 150, 50)];
    FBSnapshotVerifyView(label, nil);
}

- (void)testNumberOfLines {
    label.numberOfLines = 1;
    label.text = TTTAttributedTestString();
    FBSnapshotVerifyView(label, nil);
}

- (void)testAttributedTruncationToken {
    label.attributedTruncationToken = [[NSAttributedString alloc] initWithString:@"[DOTDOTDOT]"
                                                                      attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:12],
                                                                                    NSForegroundColorAttributeName : [UIColor blueColor] }];
    label.text = TTTAttributedTestString();
    [label setFrame:CGRectMake(0, 0, 120, 60)];
    FBSnapshotVerifyView(label, nil);
}

- (void)testAttributedTruncationTokenLinks {
    label.attributedTruncationToken = [[NSAttributedString alloc] initWithString:@"[more]"
                                                                      attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:12],
                                                                                    NSForegroundColorAttributeName : [UIColor blueColor],
                                                                                    NSLinkAttributeName : [NSURL URLWithString:@"http://ytmnd.com"] }];
    label.text = TTTAttributedTestString();
    [label setFrame:CGRectMake(0, 0, 120, 60)];
    FBSnapshotVerifyView(label, nil);
}

- (void)testAttributedTruncationTokenLinksUnderline {
    label.attributedTruncationToken = [[NSAttributedString alloc] initWithString:@"[more]"
                                                                      attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:12],
                                                                                    NSForegroundColorAttributeName : [UIColor blueColor],
                                                                                    NSLinkAttributeName : [NSURL URLWithString:@"http://ytmnd.com"],
                                                                                    NSUnderlineStyleAttributeName : @YES }];
    label.text = TTTAttributedTestString();
    [label setFrame:CGRectMake(0, 0, 120, 60)];
    FBSnapshotVerifyView(label, nil);
}

- (void)testAttributedTruncationTokenLinksUnderlineColor {
    label.attributedTruncationToken = [[NSAttributedString alloc] initWithString:@"[more]"
                                                                      attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:12],
                                                                                    NSForegroundColorAttributeName : [UIColor blueColor],
                                                                                    NSLinkAttributeName : [NSURL URLWithString:@"http://ytmnd.com"],
                                                                                    NSUnderlineStyleAttributeName : @YES,
                                                                                    NSUnderlineColorAttributeName : [UIColor redColor] }];
    label.text = TTTAttributedTestString();
    [label setFrame:CGRectMake(0, 0, 120, 60)];
    FBSnapshotVerifyView(label, nil);
}

- (void)testHighlightedLabel {
    label.highlighted = YES;
    label.highlightedTextColor = [UIColor greenColor];
    label.highlightedShadowColor = [UIColor redColor];
    label.highlightedShadowOffset = CGSizeMake(1, 1);
    label.text = @"Test text";
    FBSnapshotVerifyView(label, nil);
}

- (void)testRightAlignedSimpleText {
    label.textAlignment = NSTextAlignmentRight;
    label.text = @"Test text";
    FBSnapshotVerifyView(label, nil);
}

- (void)testCenterAlignedSimpleText {
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"Test text";
    FBSnapshotVerifyView(label, nil);
}

- (void)testVerticalAlignment {
    label.verticalAlignment = TTTAttributedLabelVerticalAlignmentBottom;
    label.text = TTTAttributedTestString();
    [label setFrame:CGRectMake(0, 0, 90, 300)];
    FBSnapshotVerifyView(label, nil);
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
    label.linkAttributes = @{ NSForegroundColorAttributeName : (id)[UIColor greenColor].CGColor };
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(10, 6)];
    TTTSizeAttributedLabel(label);
    FBSnapshotVerifyView(label, nil);
}

- (void)testLinkBackgroundLabelView {
    label.linkAttributes = @{ kTTTBackgroundFillColorAttributeName : (id)[UIColor greenColor].CGColor };
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(40, 5)];
    FBSnapshotVerifyView(label, nil);
}

- (void)testMultipleLineLinkBackgroundLabelView {
    label.linkAttributes = @{ kTTTBackgroundFillColorAttributeName : (id)[UIColor greenColor].CGColor };
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(20, 25)];
    FBSnapshotVerifyView(label, nil);
}

- (void)testLabelTextInsets {
    label.textInsets = UIEdgeInsetsMake(10, 40, 10, 40);
    label.text = TTTAttributedTestString();
    FBSnapshotVerifyView(label, nil);
}

- (void)testLabelShadowRadius {
    label.shadowRadius = 3.f;
    label.shadowColor = [UIColor greenColor];
    label.shadowOffset = CGSizeMake(1, 3);
    label.text = TTTAttributedTestString();
    FBSnapshotVerifyView(label, nil);
}

- (void)testCenteredMultilineAttributedString {
    label.textAlignment = NSTextAlignmentCenter;
    label.verticalAlignment = TTTAttributedLabelVerticalAlignmentBottom;
    label.text = TTTAttributedTestString();
    [label setFrame:CGRectMake(0, 0, 200, 400)];
    FBSnapshotVerifyView(label, nil);
}

- (void)testRightAlignedMultilineAttributedString {
    label.textAlignment = NSTextAlignmentRight;
    label.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    label.text = TTTAttributedTestString();
    [label setFrame:CGRectMake(0, 0, 200, 400)];
    FBSnapshotVerifyView(label, nil);
}

- (void)testComplexAttributedString {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:kTestLabelText];
    [string addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:16.f] range:NSMakeRange(0, [kTestLabelText length])];
    [string addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Menlo" size:18.f] range:NSMakeRange(0, 10)];
    [string addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Courier" size:20.f] range:NSMakeRange(10, 10)];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:NSMakeRange(5, 10)];
    [string addAttribute:kTTTStrikeOutAttributeName value:@1 range:NSMakeRange(15, 5)];
    [string addAttribute:kTTTBackgroundFillColorAttributeName value:(id)[UIColor blueColor].CGColor range:NSMakeRange(23, 8)];
    [string addAttribute:kTTTBackgroundCornerRadiusAttributeName value:@4 range:NSMakeRange(23, 8)];
    [string addAttribute:kTTTBackgroundStrokeColorAttributeName value:(id)[UIColor orangeColor].CGColor range:NSMakeRange(34, 4)];
    [string addAttribute:kTTTBackgroundLineWidthAttributeName value:@2 range:NSMakeRange(34, 4)];
    
    label.text = string;
    TTTSizeAttributedLabel(label);
    FBSnapshotVerifyView(label, nil);
}

- (void)testCenteredTextSizeSmallerThanLabel {
    label.textAlignment = NSTextAlignmentCenter;
    label.text = TTTAttributedTestString();
    [label setFrame:CGRectMake(0, 0, 600, 200)];
    FBSnapshotVerifyView(label, nil);
}

- (void)testRightAlignedTextSizeSmallerThanLabel {
    label.textAlignment = NSTextAlignmentRight;
    label.text = TTTAttributedTestString();
    [label setFrame:CGRectMake(0, 0, 600, 200)];
    FBSnapshotVerifyView(label, nil);
}

- (void)testSizeToFitWithTruncationToken {
    label.numberOfLines = 3;
    label.attributedTruncationToken = [[NSAttributedString alloc] initWithString:@"[more]"
                                                                      attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:14],
                                                                                    NSForegroundColorAttributeName : [UIColor greenColor] }];
    label.text = [[NSAttributedString alloc] initWithString:@"Test\nString\nWith\nLines"
                                                 attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:15],
                                                               NSForegroundColorAttributeName : [UIColor redColor] }];
    
    [label sizeToFit];
    FBSnapshotVerifyView(label, nil);
}

- (void)testOversizedAttributedFontSize {
    CGFloat fontSize = 13.f;
    
    label.font = [UIFont boldSystemFontOfSize:fontSize];
    label.text = [[NSAttributedString alloc] initWithString:kTestLabelText
                                                 attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:fontSize + 10] }];
    [label setFrame:CGRectMake(0, 0, 150, 60)];
    FBSnapshotVerifyView(label, nil);
}

#pragma mark - UIAccessibility

- (void)testAccessibilityElement {
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(0, 4)];
    
    expect(label.isAccessibilityElement).to.beFalsy();
    expect(label.accessibilityElementCount).will.equal(2);
    expect([label accessibilityElementAtIndex:0]).toNot.beNil();
    expect([label indexOfAccessibilityElement:(id)[NSNull null]]).to.equal(NSNotFound);
}

#pragma mark - TTTAttributedLabelLink tests

- (void)testDesignatedInitializer {
    NSTextCheckingResult *textResult = [NSTextCheckingResult spellCheckingResultWithRange:NSMakeRange(0, 4)];
    TTTAttributedLabelLink *link = [[TTTAttributedLabelLink alloc] initWithAttributes:TTTAttributedTestAttributesDictionary()
                                                                     activeAttributes:TTTAttributedTestAttributesDictionary()
                                                                   inactiveAttributes:TTTAttributedTestAttributesDictionary()
                                                                   textCheckingResult:textResult];
    
    XCTAssertEqualObjects(link.attributes, TTTAttributedTestAttributesDictionary());
    XCTAssertEqualObjects(link.activeAttributes, TTTAttributedTestAttributesDictionary());
    XCTAssertEqualObjects(link.inactiveAttributes, TTTAttributedTestAttributesDictionary());
}

- (void)testLabelInitializer {
    NSTextCheckingResult *textResult = [NSTextCheckingResult spellCheckingResultWithRange:NSMakeRange(0, 4)];
    TTTAttributedLabelLink *link = [[TTTAttributedLabelLink alloc] initWithAttributesFromLabel:label textCheckingResult:textResult];
    
    XCTAssertEqualObjects(link.attributes, label.linkAttributes);
    XCTAssertEqualObjects(link.activeAttributes, label.activeLinkAttributes);
    XCTAssertEqualObjects(link.inactiveAttributes, label.inactiveLinkAttributes);
}

- (void)testTextCheckingResultAttributesAreCorrectlyAssigned {
    NSTextCheckingResult *textResult = [NSTextCheckingResult spellCheckingResultWithRange:NSMakeRange(0, 4)];
    TTTAttributedLabelLink *link = [label addLinkWithTextCheckingResult:textResult attributes:TTTAttributedTestAttributesDictionary()];
    
    XCTAssertEqualObjects(link.attributes, TTTAttributedTestAttributesDictionary());
    XCTAssertEqualObjects(link.activeAttributes, label.activeLinkAttributes);
    XCTAssertEqualObjects(link.inactiveAttributes, label.inactiveLinkAttributes);
}

- (void)testTextCheckingResultAttributesAreCorrectlyAssignedWhenAttributesAreNil {
    NSTextCheckingResult *textResult = [NSTextCheckingResult spellCheckingResultWithRange:NSMakeRange(0, 4)];
    TTTAttributedLabelLink *link = [label addLinkWithTextCheckingResult:textResult attributes:nil];
    
    XCTAssertNil(link.attributes);
    XCTAssertNil(link.activeAttributes);
    XCTAssertNil(link.inactiveAttributes);
}

#pragma mark - TTTAttributedLabelDelegate tests

- (void)testDefaultLongPressValues {
    XCTAssertGreaterThan(label.longPressGestureRecognizer.minimumPressDuration, 0, @"Should have a default minimum long press duration");
    XCTAssertGreaterThan(label.longPressGestureRecognizer.allowableMovement, 0, @"Should have a default allowable long press movement distance");
}

- (void)testMinimumLongPressDuration {
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    
    label.longPressGestureRecognizer.minimumPressDuration = 0.4f;
    
    [[TTTDelegateMock expect] attributedLabel:label didSelectLinkWithURL:testURL];
    [[TTTDelegateMock reject] attributedLabel:label didLongPressLinkWithURL:testURL atPoint:CGPointMake(5, 5)];
    
    TTTSimulateLongPressOnLabelAtPointWithDuration(label, CGPointMake(5, 5), 0.2f);
    
    [TTTDelegateMock verify];
}

- (void)testLinkPressCallsDelegate {
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock expect] attributedLabel:label didSelectLinkWithURL:testURL];
    
    TTTSimulateTapOnLabelAtPoint(label, CGPointMake(5, 5));
    
    [TTTDelegateMock verify];
}

- (void)testLinkPressCallsDelegateInExtendedTouchArea {
    label.extendsLinkTouchArea = YES;
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock expect] attributedLabel:label didSelectLinkWithURL:testURL];
    
    TTTSimulateTapOnLabelAtPoint(label, CGPointMake(27, 5));
    
    [TTTDelegateMock verify];
}

- (void)testLinkPressDoesNotCallDelegateInExtendedTouchArea {
    label.extendsLinkTouchArea = NO;
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock reject] attributedLabel:label didSelectLinkWithURL:testURL];
    
    TTTSimulateTapOnLabelAtPoint(label, CGPointMake(27, 5));
    
    [TTTDelegateMock verify];
}

- (void)testLongPressOffLinkDoesNotCallDelegate {
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock reject] attributedLabel:label didSelectLinkWithURL:testURL];
    [[TTTDelegateMock reject] attributedLabel:label didLongPressLinkWithURL:testURL atPoint:CGPointMake(50, 5)];
    
    TTTSimulateLongPressOnLabelAtPointWithDuration(label, CGPointMake(50, 5), 0.6f);
    
    [TTTDelegateMock verify];
}

- (void)testDragOffLinkDoesNotCallDelegate {
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock reject] attributedLabel:label didSelectLinkWithURL:testURL];
    [[TTTDelegateMock reject] attributedLabel:label didLongPressLinkWithURL:testURL atPoint:CGPointMake(50, 5)];
    
    [[[UIApplication sharedApplication].windows lastObject] addSubview:label];
    [label dragFromPoint:CGPointMake(0, 1) toPoint:CGPointMake(50, 5) steps:30];
    
    [TTTDelegateMock verify];
}

- (void)testLongLinkPressCallsDelegate {
    label.text = TTTAttributedTestString();
    [label addLinkToURL:testURL withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock reject] attributedLabel:label didSelectLinkWithURL:testURL];
    [[TTTDelegateMock expect] attributedLabel:label didLongPressLinkWithURL:testURL atPoint:CGPointMake(5, 5)];
    
    TTTSimulateLongPressOnLabelAtPointWithDuration(label, CGPointMake(5, 5), 0.6f);
    
    [TTTDelegateMock verify];
}

- (void)testPhonePressCallsDelegate {
    label.text = TTTAttributedTestString();
    
    NSString *phone = @"415-555-1212";
    [label addLinkToPhoneNumber:phone withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock expect] attributedLabel:label didSelectLinkWithPhoneNumber:phone];
    
    TTTSimulateTapOnLabelAtPoint(label, CGPointMake(5, 5));
    
    [TTTDelegateMock verify];
}

- (void)testLongPhonePressCallsDelegate {
    label.text = TTTAttributedTestString();
    
    NSString *phone = @"415-555-1212";
    [label addLinkToPhoneNumber:phone withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock reject] attributedLabel:label didSelectLinkWithPhoneNumber:phone];
    [[TTTDelegateMock expect] attributedLabel:label didLongPressLinkWithPhoneNumber:phone atPoint:CGPointMake(5, 5)];
    
    TTTSimulateLongPressOnLabelAtPointWithDuration(label, CGPointMake(5, 5), 0.6f);
    
    [TTTDelegateMock verify];
}

- (void)testDatePressCallsDelegate {
    label.text = TTTAttributedTestString();
    
    NSDate *date = [NSDate date];
    [label addLinkToDate:date withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock expect] attributedLabel:label didSelectLinkWithDate:date];
    
    TTTSimulateTapOnLabelAtPoint(label, CGPointMake(5, 5));
    
    [TTTDelegateMock verify];
}

- (void)testLongDatePressCallsDelegate {
    label.text = TTTAttributedTestString();
    
    NSDate *date = [NSDate date];
    [label addLinkToDate:date withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock reject] attributedLabel:label didSelectLinkWithDate:date];
    [[TTTDelegateMock expect] attributedLabel:label didLongPressLinkWithDate:date atPoint:CGPointMake(5, 5)];
    
    TTTSimulateLongPressOnLabelAtPointWithDuration(label, CGPointMake(5, 5), 0.6f);
    
    [TTTDelegateMock verify];
}

- (void)testLongDateTimeZonePressCallsDelegate {
    label.text = TTTAttributedTestString();
    
    NSDate *date = [NSDate date];
    [label addLinkToDate:date timeZone:[NSTimeZone defaultTimeZone] duration:1 withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock reject] attributedLabel:label didSelectLinkWithDate:date];
    [[TTTDelegateMock expect] attributedLabel:label didLongPressLinkWithDate:date
                                     timeZone:[NSTimeZone defaultTimeZone]
                                     duration:1
                                      atPoint:CGPointMake(5, 5)];
    
    TTTSimulateLongPressOnLabelAtPointWithDuration(label, CGPointMake(5, 5), 0.6f);
    
    [TTTDelegateMock verify];
}

- (void)testAddressPressCallsDelegate {
    label.text = TTTAttributedTestString();
    
    NSDictionary *address = @{
          NSTextCheckingCityKey     : @"San Fransokyo",
          NSTextCheckingCountryKey  : @"United States of Eurasia",
          NSTextCheckingStateKey    : @"California",
          NSTextCheckingStreetKey   : @"1 Market St",
    };
    [label addLinkToAddress:address withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock expect] attributedLabel:label didSelectLinkWithAddress:address];
    
    TTTSimulateTapOnLabelAtPoint(label, CGPointMake(5, 5));
    
    [TTTDelegateMock verify];
}

- (void)testLongAddressPressCallsDelegate {
    label.text = TTTAttributedTestString();
    
    NSDictionary *address = @{
          NSTextCheckingCityKey     : @"San Fransokyo",
          NSTextCheckingCountryKey  : @"United States of Eurasia",
          NSTextCheckingStateKey    : @"California",
          NSTextCheckingStreetKey   : @"1 Market St",
    };
    [label addLinkToAddress:address withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock reject] attributedLabel:label didSelectLinkWithAddress:address];
    [[TTTDelegateMock expect] attributedLabel:label didLongPressLinkWithAddress:address atPoint:CGPointMake(5, 5)];
    
    TTTSimulateLongPressOnLabelAtPointWithDuration(label, CGPointMake(5, 5), 0.6f);
    
    [TTTDelegateMock verify];
}

- (void)testTransitPressCallsDelegate {
    label.text = TTTAttributedTestString();
    
    NSDictionary *transitDict = @{
          NSTextCheckingAirlineKey  : @"Galactic Spacelines",
          NSTextCheckingFlightKey   : @9876,
    };
    [label addLinkToTransitInformation:transitDict withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock expect] attributedLabel:label didSelectLinkWithTransitInformation:transitDict];
    
    TTTSimulateTapOnLabelAtPoint(label, CGPointMake(5, 5));
    
    [TTTDelegateMock verify];
}

- (void)testLongTransitPressCallsDelegate {
    label.text = TTTAttributedTestString();
    
    NSDictionary *transitDict = @{
          NSTextCheckingAirlineKey  : @"Galactic Spacelines",
          NSTextCheckingFlightKey   : @9876,
    };
    [label addLinkToTransitInformation:transitDict withRange:NSMakeRange(0, 4)];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock reject] attributedLabel:label didSelectLinkWithTransitInformation:transitDict];
    [[TTTDelegateMock expect] attributedLabel:label didLongPressLinkWithTransitInformation:transitDict atPoint:CGPointMake(5, 5)];
    
    TTTSimulateLongPressOnLabelAtPointWithDuration(label, CGPointMake(5, 5), 0.6f);
    
    [TTTDelegateMock verify];
}

- (void)testTextCheckingPressCallsDelegate {
    label.text = TTTAttributedTestString();
    
    NSTextCheckingResult *textResult = [NSTextCheckingResult spellCheckingResultWithRange:NSMakeRange(0, 4)];
    [label addLinkWithTextCheckingResult:textResult];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock expect] attributedLabel:label didSelectLinkWithTextCheckingResult:textResult];
    
    TTTSimulateTapOnLabelAtPoint(label, CGPointMake(5, 5));
    
    [TTTDelegateMock verify];
}

- (void)testLongTextCheckingPressCallsDelegate {
    label.text = TTTAttributedTestString();
    
    NSTextCheckingResult *textResult = [NSTextCheckingResult spellCheckingResultWithRange:NSMakeRange(0, 4)];
    [label addLinkWithTextCheckingResult:textResult];
    TTTSizeAttributedLabel(label);
    
    [[TTTDelegateMock reject] attributedLabel:label didSelectLinkWithTextCheckingResult:textResult];
    [[TTTDelegateMock expect] attributedLabel:label didLongPressLinkWithTextCheckingResult:textResult atPoint:CGPointMake(5, 5)];
    
    TTTSimulateLongPressOnLabelAtPointWithDuration(label, CGPointMake(5, 5), 0.6f);
    
    [TTTDelegateMock verify];
}

- (void)testLinkPressCallsLinkBlock {
    label.text = TTTAttributedTestString();
    TTTSizeAttributedLabel(label);
    
    __block BOOL didCallTapBlock = NO;
    __block BOOL didCallLongPressBlock = NO;
    
    NSTextCheckingResult *result = [NSTextCheckingResult linkCheckingResultWithRange:NSMakeRange(0, 4) URL:testURL];
    TTTAttributedLabelLink *link = [[TTTAttributedLabelLink alloc] initWithAttributesFromLabel:label
                                                                            textCheckingResult:result];
    
    __weak typeof (link) weakLink = link;
    __weak typeof (result) weakResult = result;
    link.linkTapBlock = ^(TTTAttributedLabel *aLabel, TTTAttributedLabelLink *aLink) {
        didCallTapBlock = YES;
        
        expect(aLabel).to.equal(label);
        expect(aLink).to.equal(weakLink);
        expect(aLink.result).to.equal(weakResult);
    };
    
    link.linkLongPressBlock = ^(__unused TTTAttributedLabel *aLabel, __unused TTTAttributedLabelLink *aLink) {
        didCallLongPressBlock = YES;
        
        expect(aLabel).to.equal(label);
        expect(aLink).to.equal(weakLink);
        expect(aLink.result).to.equal(weakResult);
    };
    
    [label addLink:link];
    
    TTTSimulateTapOnLabelAtPoint(label, CGPointMake(5, 3));
    
    expect(didCallTapBlock).will.beTruthy();
    expect(didCallLongPressBlock).will.beFalsy();
    
    didCallTapBlock = NO;
    
    TTTSimulateLongPressOnLabelAtPointWithDuration(label, CGPointMake(5, 5), 0.6f);
    
    expect(didCallTapBlock).will.beFalsy();
    expect(didCallLongPressBlock).will.beTruthy();
}

#pragma mark - UIPasteboard

- (void)testCopyingLabelText {
    label.text = kTestLabelText;
    
    [label copy:nil];
    
    expect([UIPasteboard generalPasteboard].string).to.equal(kTestLabelText);
}

- (void)testPerformActions {
    expect([label canPerformAction:@selector(copy:) withSender:nil]).to.beTruthy();
    expect([label canPerformAction:@selector(paste:) withSender:nil]).to.beFalsy();
}

#pragma mark - NSCoding

- (void)testEncodingLabel {
    label.text = TTTAttributedTestString();
    
    NSData *encodedLabel = [NSKeyedArchiver archivedDataWithRootObject:label];

    TTTAttributedLabel *newLabel = [NSKeyedUnarchiver unarchiveObjectWithData:encodedLabel];
    
    expect(newLabel.text).to.equal(label.text);
}

#pragma mark - TTTAttributedLabelLink

- (void)testAddSingleLink {
    TTTAttributedLabelLink *link = [[TTTAttributedLabelLink alloc] initWithAttributesFromLabel:label
                                                                            textCheckingResult:
                                    [NSTextCheckingResult linkCheckingResultWithRange:NSMakeRange(0, 1) URL:testURL]];
    
    [label addLink:link];
    
    expect(label.links.count).to.equal(1);
}

- (void)testEncodingLink {
    TTTAttributedLabelLink *link = [[TTTAttributedLabelLink alloc] initWithAttributesFromLabel:label
                                                                            textCheckingResult:
                                    [NSTextCheckingResult linkCheckingResultWithRange:NSMakeRange(0, 1) URL:testURL]];
    
    NSData *encodedLink = [NSKeyedArchiver archivedDataWithRootObject:link];
    
    TTTAttributedLabelLink *newLink = [NSKeyedUnarchiver unarchiveObjectWithData:encodedLink];
    
    expect(newLink.result.URL).to.equal(link.result.URL);
}

- (void)testLinkAccessibility {
    TTTAttributedLabelLink *link = [[TTTAttributedLabelLink alloc] initWithAttributesFromLabel:label
                                                                            textCheckingResult:
                                    [NSTextCheckingResult linkCheckingResultWithRange:NSMakeRange(0, 1) URL:testURL]];
    
    expect(link.accessibilityValue).to.equal(testURL.absoluteString);
    
    link = [[TTTAttributedLabelLink alloc] initWithAttributesFromLabel:label
                                                    textCheckingResult:
                                    [NSTextCheckingResult phoneNumberCheckingResultWithRange:NSMakeRange(0, 1) phoneNumber:@"415-555-1212"]];
    
    expect(link.accessibilityValue).to.equal(@"415-555-1212");
    
    NSDate *date = [NSDate date];
    
    link = [[TTTAttributedLabelLink alloc] initWithAttributesFromLabel:label
                                                    textCheckingResult:
            [NSTextCheckingResult dateCheckingResultWithRange:NSMakeRange(0, 1) date:date]];
    
    expect(link.accessibilityValue).to.equal([NSDateFormatter localizedStringFromDate:date
                                                                            dateStyle:NSDateFormatterLongStyle
                                                                            timeStyle:NSDateFormatterLongStyle]);
}

#pragma mark - Deprecated Methods

- (void)testLeading {
    // Deprecated
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [label setLeading:1.f];
#pragma clang diagnostic pop
    expect(label.lineSpacing).to.equal(1.f);
}

- (void)testDataDetectorTypes {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    label.dataDetectorTypes = NSTextCheckingTypeLink;
    expect(label.dataDetectorTypes).will.equal(NSTextCheckingTypeLink);
#pragma clang diagnostic pop
}

@end
