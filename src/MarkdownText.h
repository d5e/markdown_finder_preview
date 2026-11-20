#import <Cocoa/Cocoa.h>

NSString *ReadMarkdown(NSURL *url, NSError **error);
NSAttributedString *MarkdownText(NSString *source, NSAppearance *appearance);
