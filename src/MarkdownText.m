#import "MarkdownText.h"
#import "MarkdownHTML.h"

NSString *ReadMarkdown(NSURL *url, NSError **error) {
    NSString *source = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
    return source ?: [NSString stringWithContentsOfURL:url usedEncoding:NULL error:error];
}

NSAttributedString *MarkdownText(NSString *source, NSAppearance *appearance) {
    BOOL dark = [[appearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]]
        isEqualToString:NSAppearanceNameDarkAqua];
    NSString *html = [MarkdownHTML(source)
        stringByReplacingOccurrencesOfString:@"@media(prefers-color-scheme:dark)"
        withString:dark ? @"@media all" : @"@media not all"];
    // Keep the HTML importer independent of document-linked resources.
    html = [html stringByReplacingOccurrencesOfString:@"<img\\b[^>]*>" withString:@""
                                              options:NSRegularExpressionSearch range:NSMakeRange(0, html.length)];
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc]
        initWithData:[html dataUsingEncoding:NSUTF8StringEncoding]
        options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                  NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
        documentAttributes:NULL error:NULL];
    if (!result) {
        result = [[NSMutableAttributedString alloc] initWithString:source attributes:@{
            NSFontAttributeName: [NSFont systemFontOfSize:18]
        }];
    }

    NSColor *ink = dark ? [NSColor colorWithWhite:0.92 alpha:1] : [NSColor colorWithWhite:0.15 alpha:1];
    NSColor *link = dark ? [NSColor colorWithSRGBRed:0.60 green:0.80 blue:0.95 alpha:1]
                         : [NSColor colorWithSRGBRed:0.13 green:0.36 blue:0.56 alpha:1];
    NSRange all = NSMakeRange(0, result.length);
    [result addAttribute:NSForegroundColorAttributeName value:ink range:all];
    [result removeAttribute:NSStrokeColorAttributeName range:all];
    [result enumerateAttribute:NSLinkAttributeName inRange:all options:0
        usingBlock:^(id value, NSRange range, BOOL *stop) {
            (void)stop;
            if (value) {
                [result addAttribute:NSForegroundColorAttributeName value:link range:range];
                [result removeAttribute:NSLinkAttributeName range:range];
            }
        }];
    return result;
}
