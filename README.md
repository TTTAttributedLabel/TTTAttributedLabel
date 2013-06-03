# TTTAttributedLabel

**A drop-in replacement for `UILabel` that supports attributes, data detectors, links, and more**

`TTTAttributedLabel` is a drop-in replacement for `UILabel`, which provides a simple way to performantly render [attributed strings](http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSAttributedString_Class/Reference/Reference.html). As a bonus, it also supports link embedding, both automatically with `UIDataDetectorTypes` and manually by specifying a range for a URL, address, phone number, event, or transit information.

Even though `NSAttributedString` support was added for UILabel in iOS 6, `TTTAttributedLabel` has several unique features:

- Compatibility with iOS >= 4.3
- Automatic data detection
- Manual link embedding
- Label style inheritance for attributed strings

It also includes advanced paragraph style properties:

- `verticalAlignment`
- `textInsets`
- `firstLineIndent`
- `leading`
- `lineHeightMultiple`
- `shadowRadius`
- `highlightedShadowRadius` / `highlightedShadowOffset` / `highlightedShadowColor`
- `truncationTokenString`

## Installation

[CocoaPods](http://cocoapods.org) is the recommended method of installing TTTAttributedLabel. Simply add the following line to your `Podfile`:

#### Podfile

```ruby
pod 'TTTAttributedLabel'
```

## Usage

``` objective-c
TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
label.font = [UIFont systemFontOfSize:14];
label.textColor = [UIColor darkGrayColor];
label.lineBreakMode = UILineBreakModeWordWrap;
label.numberOfLines = 0;

NSString *text = @"Lorem ipsum dolar sit amet";
[label setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
  NSRange boldRange = [[mutableAttributedString string] rangeOfString:@"ipsum dolar" options:NSCaseInsensitiveSearch];
  NSRange strikeRange = [[mutableAttributedString string] rangeOfString:@"sit amet" options:NSCaseInsensitiveSearch];

  // Core Text APIs use C functions without a direct bridge to UIFont. See Apple's "Core Text Programming Guide" to learn how to configure string attributes.
  UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:14];
  CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
  if (font) {
    [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)font range:boldRange];
    [mutableAttributedString addAttribute:kTTTStrikeOutAttributeName value:[NSNumber numberWithBool:YES] range:strikeRange];
    CFRelease(font);
  }

  return mutableAttributedString;
}];
```

First, we create and configure the label, the same way you would instantiate `UILabel`. Any text properties that are set on the label are inherited as the base attributes when using the `-setText:afterInheritingLabelAttributesAndConfiguringWithBlock:` method. In this example, the substring "ipsum dolar", would appear in bold, such that the label would read "Lorem **ipsum dolar** sit amet", in size 14 Helvetica, with a dark gray color.

The normal `setText:` setter accepts both `NSString` and `NSAttributedString`; in the latter case, the attributed string is directly set, without inheriting the base style of the label.

### Links and Data Detection

In addition to supporting rich text, `TTTAttributedLabel` allows you to automatically detect links for dates, addresses, links, phone numbers, transit information, or allow you to embed your own.

``` objective-c
label.dataDetectorTypes = NSTextCheckingTypeLink; // Automatically detect links when the label text is subsequently changed
label.delegate = self; // Delegate methods are called when the user taps on a link (see `TTTAttributedLabelDelegate` protocol)

label.text = @"Fork me on GitHub! (http://github.com/mattt/TTTAttributedLabel/)"; // Repository URL will be automatically detected and linked

NSRange range = [label.text rangeOfString:@"me"];
[label addLinkToURL:[NSURL URLWithString:@"http://github.com/mattt/"] withRange:range]; // Embedding a custom link in a substring
```

## Demo

Build and run the `TTTAttributedLabelExample` project in Xcode to see `TTTAttributedLabel` in action.

## Requirements

`TTTAttributedLabel` is compatible with iOS 4.3+ as a deployment target, but must be compiled using the iOS 6 SDK. If you get compiler errors for undefined constants, try upgrading to the latest version of Xcode, and updating your project to the recommended build settings.

`TTTAttributedLabel` also requires the `CoreText` and `Core Graphics` frameworks. If you're installing with CocoaPods these frameworks will automatically be linked for you, otherwise you will have to add them to your project.

## Contact

Mattt Thompson

- http://github.com/mattt
- http://twitter.com/mattt
- m@mattt.me

## License

TTTAttributedLabel is available under the MIT license. See the LICENSE file for more info.
