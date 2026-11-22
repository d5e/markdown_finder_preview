#import <Cocoa/Cocoa.h>

NSString *ReadMarkdown(NSURL *url, NSError **error);
NSAttributedString *MarkdownTextWithFont(NSString *source, NSAppearance *appearance, NSString *fontFamily, NSInteger fontSize);
NSAttributedString *MarkdownText(NSString *source, NSAppearance *appearance);
