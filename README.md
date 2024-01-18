# TTTAttributedLabel

[![Circle CI](https://circleci.com/gh/TTTAttributedLabel/TTTAttributedLabel.svg?style=svg)](https://circleci.com/gh/TTTAttributedLabel/TTTAttributedLabel) [![Version Status](https://img.shields.io/cocoapods/v/TTTAttributedLabel.svg)](https://cocoapods.org/pods/TTTAttributedLabel) [![codecov](https://codecov.io/gh/TTTAttributedLabel/TTTAttributedLabel/branch/master/graph/badge.svg)](https://codecov.io/gh/TTTAttributedLabel/TTTAttributedLabel) [![license MIT](https://img.shields.io/cocoapods/l/TTTAttributedLabel.svg)](http://opensource.org/licenses/MIT) [![Platform](https://img.shields.io/cocoapods/p/TTTAttributedLabel.svg)](http://cocoadocs.org/docsets/TTTAttributedLabel/)  [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)


**A drop-in replacement for `UILabel` that supports attributes, data detectors, links, and more**

`TTTAttributedLabel` is a drop-in replacement for `UILabel` providing a simple way to performantly render [attributed strings](https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSAttributedString_Class/Reference/Reference.html). As a bonus, it also supports link embedding, both automatically with `NSTextCheckingTypes` and manually by specifying a range for a URL, address, phone number, event, or transit information.

Even though `UILabel` received support for `NSAttributedString` in iOS 6, `TTTAttributedLabel` has several unique features:

- Automatic data detection
- Manual link embedding
- Label style inheritance for attributed strings
- Custom styling for links within the label
- Long-press gestures in addition to tap gestures for links

It also includes advanced paragraph style properties:

- `attributedTruncationToken`
- `firstLineIndent`
- `highlightedShadowRadius`
- `highlightedShadowOffset`
- `highlightedShadowColor`
- `lineHeightMultiple`
- `lineSpacing`
- `minimumLineHeight`
- `maximumLineHeight`
- `shadowRadius`
- `textInsets`
- `verticalAlignment`

## Requirements

- iOS 8+ / tvOS 9+
- Xcode 7+

### Accessibility

As of version 1.10.0, `TTTAttributedLabel` supports VoiceOver through the  `UIAccessibilityElement` protocol. Each link can be individually selected, with an `accessibilityLabel` equal to its string value, and a corresponding `accessibilityValue` for URL, phone number, and date links.  Developers who wish to change this behavior or provide custom values should create a subclass and override `accessibilityElements`.

## Communication

- If you **need help**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/tttattributedlabel). (Tag `tttattributedlabel`)
- If you'd like to **ask a general question**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/tttattributedlabel).
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Installation

[CocoaPods](https://cocoapods.org/) is the recommended method of installing `TTTAttributedLabel`. Simply add the following line to your `Podfile`:

```ruby
# Podfile

pod 'TTTAttributedLabel'
```

## Usage

`TTTAttributedLabel` can display both plain and attributed text: just pass an `NSString` or `NSAttributedString` to the `setText:` setter. Never assign to the `attributedText` property.

```objc
// NSAttributedString

TTTAttributedLabel *attributedLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];

NSAttributedString *attString = [[NSAttributedString alloc] initWithString:@"Tom Bombadil"
                                                                attributes:@{
        (id)kCTForegroundColorAttributeName : (id)[UIColor redColor].CGColor,
        NSFontAttributeName : [UIFont boldSystemFontOfSize:16],
        NSKernAttributeName : [NSNull null],
        (id)kTTTBackgroundFillColorAttributeName : (id)[UIColor greenColor].CGColor
}];

// The attributed string is directly set, without inheriting any other text
// properties of the label.
attributedLabel.text = attString;
```

```objc
// NSString

TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
label.font = [UIFont systemFontOfSize:14];
label.textColor = [UIColor darkGrayColor];
label.lineBreakMode = NSLineBreakByWordWrapping;
label.numberOfLines = 0;

// If you're using a simple `NSString` for your text,
// assign to the `text` property last so it can inherit other label properties.
NSString *text = @"Lorem ipsum dolor sit amet";
[label setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
  NSRange boldRange = [[mutableAttributedString string] rangeOfString:@"ipsum dolor" options:NSCaseInsensitiveSearch];
  NSRange strikeRange = [[mutableAttributedString string] rangeOfString:@"sit amet" options:NSCaseInsensitiveSearch];

  // Core Text APIs use C functions without a direct bridge to UIFont. See Apple's "Core Text Programming Guide" to learn how to configure string attributes.
  UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:14];
  CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
  if (font) {
    [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
    [mutableAttributedString addAttribute:kTTTStrikeOutAttributeName value:@YES range:strikeRange];
    CFRelease(font);
  }

  return mutableAttributedString;
}];
```

First, we create and configure the label, the same way you would instantiate `UILabel`. Any text properties that are set on the label are inherited as the base attributes when using the `-setText:afterInheritingLabelAttributesAndConfiguringWithBlock:` method. In this example, the substring "ipsum dolar", would appear in bold, such that the label would read "Lorem **ipsum dolar** sit amet", in size 14 Helvetica, with a dark gray color.

## `IBDesignable`

`TTTAttributedLabel` includes `IBInspectable` and `IB_DESIGNABLE` annotations to enable configuring the label inside Interface Builder. However, if you see these warnings when building...

```
IB Designables: Failed to update auto layout status: Failed to load designables from path (null)
IB Designables: Failed to render instance of TTTAttributedLabel: Failed to load designables from path (null)
```

...then you are likely using `TTTAttributedLabel` as a static library, which does not support IB annotations. Some workarounds include:

- Install `TTTAttributedLabel` as a dynamic framework using CocoaPods with `use_frameworks!` in your `Podfile`, or with Carthage
- Install `TTTAttributedLabel` by dragging its source files to your project

### Links and Data Detection

In addition to supporting rich text, `TTTAttributedLabel` can automatically detect links for dates, addresses, URLs, phone numbers, transit information, and allows you to embed your own links.

``` objective-c
label.enabledTextCheckingTypes = NSTextCheckingTypeLink; // Automatically detect links when the label text is subsequently changed
label.delegate = self; // Delegate methods are called when the user taps on a link (see `TTTAttributedLabelDelegate` protocol)

label.text = @"Fork me on GitHub! (https://github.com/mattt/TTTAttributedLabel/)"; // Repository URL will be automatically detected and linked

NSRange range = [label.text rangeOfString:@"me"];
[label addLinkToURL:[NSURL URLWithString:@"http://github.com/mattt/"] withRange:range]; // Embedding a custom link in a substring
```

## Demo

```bash
pod try TTTAttributedLabel
```

...or clone this repo and build and run/test the `Espressos` project in Xcode to see `TTTAttributedLabel` in action. If you don't have [CocoaPods](http://cocoapods.org) installed, grab it with `[sudo] gem install cocoapods`.

```bash
cd Example
pod install
open Espressos.xcworkspace
```

## License

`TTTAttributedLabel` is available under the MIT license. See the LICENSE file for more info.
