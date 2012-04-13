# TTTAttributedLabel
## A drop-in replacement for UILabel that supports NSAttributedStrings

![Screenshot of TTTAttributedLabel](https://github.com/mattt/TTTAttributedLabel/raw/master/TTTAttributedLabelExample/screenshot.png "TTTAttributedLabel Screenshot")

[NSAttributedString](http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSAttributedString_Class/Reference/Reference.html) is pretty rad. When it was ported into iOS 4 from Mac OS, iPhone developers everywhere rejoiced. Unfortunately, as of iOS 4 none of the standard controls in UIKit support it. Bummer.

`TTTAttributedLabel` was created to be a drop-in replacement for `UILabel`, that provided a simple API to styling text with `NSAttributedString` while remaining performant. As a bonus, it also supports link embedding, both automatically with `UIDataDetectorTypes` and manually by specifying a range for a URL, address, phone number, or event.

## Documentation

Online documentation is available at http://mattt.github.com/TTTAttributedLabel/.

To install the docset directly into your local Xcode organizer, first [install `appledoc`](https://github.com/tomaz/appledoc), and then clone this project and run `appledoc -p TTTAttributedLabel -c "Mattt Thompson" --company-id com.mattt TTTAttributedLabel.*`

## Demo

Build and run the `TTTAttributedLabelExample` project in Xcode to see `TTTAttributedLabel` in action.

## Installation

`TTTAttributedLabel` requires the `CoreText` Framework, so the first thing you'll need to do is include the framework into your project. In Xcode 4, go to the project file at the root of your workspace and select your active target. There should be several sections across the top of that window; choose "Build Phases". Next, click "Link Binary With Libraries" to expand that section to see the frameworks currently included in your project. Click the "+" at the bottom left and select "CoreText.framework".

Now that the framework has been linked, all you need to do is drop `TTTAttributedLabel.{h,m}` into your project, and add `#include "TTTAttributedLabel.h"` to the top of classes that will use it.

## Example Usage

``` objective-c
TTTAttributedLabel *label = [[[TTTAttributedLabel alloc] initWithFrame:CGRectZero] autorelease];
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
	CTFontRef font = CTFontCreateWithName((CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
	if (font) {
	  [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)font range:boldRange];
	  [mutableAttributedString addAttribute:@"TTTCustomStrikeOut" value:[NSNumber numberWithBool:YES] range:strikeRange];
	  CFRelease(font);
	}

	return mutableAttributedString;
}];
```

First, we create and configure the label, the same way you would instantiate `UILabel`. Any text properties that are set on the label are inherited as the base attributes when using the `-setText:afterInheritingLabelAttributesAndConfiguringWithBlock:` method. In this example, the substring "ipsum dolar", would appear in bold, such that the label would read "Lorem **ipsum dolar** sit amet", in size 14 Helvetica, with a dark gray color.

The normal `setText:` setter accepts both `NSString` and `NSAttributedString`; in the latter case, the attributed string is directly set, without inheriting the base style of the label.

### Links and UIDataDetectors

In addition to supporting rich text, `TTTAttributedLabel` allows you to automatically detect links for URLs, addresses, phone numbers, and dates, or allow you to embed your own.

``` objective-c
label.dataDetectorTypes = UIDataDetectorTypeAll; // Automatically detect links when the label text is subsequently changed
label.delegate = self; // Delegate methods are called when the user taps on a link (see `TTTAttributedLabelDelegate` protocol)

label.text = @"Fork me on GitHub! (http://github.com/mattt/TTTAttributedLabel/)"; // Repository URL will be automatically detected and linked

NSRange range = [label.text rangeOfString:@"me"];
[label addLinkToURL:[NSURL URLWithString:@"http://github.com/mattt/"] withRange:range]; // Embedding a custom link in a substring
```

## Credits

Inspired by [Olivier Halligon](https://github.com/AliSoftware)'s [OHAttributedLabel](https://github.com/AliSoftware/OHAttributedLabel), borrowing some general approaches in converting between UIKit and Core Text text attributes.

Many thanks to [the contributors to TTTAttributedLabel](https://github.com/mattt/TTTAttributedLabel/contributors), for all of their features, fixes, and feedback.

## Contact

Mattt Thompson

- http://github.com/mattt
- http://twitter.com/mattt
- m@mattt.me

## License

TTTAttributedLabel is available under the MIT license. See the LICENSE file for more info.
