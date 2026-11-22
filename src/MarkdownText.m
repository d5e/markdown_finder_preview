#import "MarkdownText.h"
#import "MarkdownHTML.h"

static NSString * const DarkMediaQuery = @"@media(prefers-color-scheme:dark)";
static NSString * const EnabledMediaQuery = @"@media all";
static NSString * const DisabledMediaQuery = @"@media not all";
static NSString * const ImageTagPattern = @"<img\\b[^>]*>";
static NSString * const EmptyString = @"";
static const CGFloat FallbackFontSize = 18.0;
static const CGFloat DarkInkWhite = 0.92;
static const CGFloat LightInkWhite = 0.15;
static const CGFloat ColorOpacity = 1.0;
static const CGFloat DarkLinkRed = 0.60;
static const CGFloat DarkLinkGreen = 0.80;
static const CGFloat DarkLinkBlue = 0.95;
static const CGFloat LightLinkRed = 0.13;
static const CGFloat LightLinkGreen = 0.36;
static const CGFloat LightLinkBlue = 0.56;

NSString *ReadMarkdown(NSURL *url, NSError **error) {
    NSString *source = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
    return source ?: [NSString stringWithContentsOfURL:url usedEncoding:NULL error:error];
}

static BOOL IsDarkAppearance(NSAppearance *appearance) {
    NSArray *appearances = @[NSAppearanceNameAqua, NSAppearanceNameDarkAqua];
    NSString *matchedAppearance = [appearance bestMatchFromAppearancesWithNames:appearances];
    return [matchedAppearance isEqualToString:NSAppearanceNameDarkAqua];
}

static NSString *HTMLForAppearance(NSString *source, BOOL dark) {
    NSString *mediaQuery = dark ? EnabledMediaQuery : DisabledMediaQuery;
    NSString *html = [MarkdownHTML(source) stringByReplacingOccurrencesOfString:DarkMediaQuery
                                                                     withString:mediaQuery];
    NSRange entireHTML = NSMakeRange(0, html.length);
    return [html stringByReplacingOccurrencesOfString:ImageTagPattern
                                           withString:EmptyString
                                              options:NSRegularExpressionSearch
                                                range:entireHTML];
}

static NSMutableAttributedString *ImportHTML(NSString *html) {
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *options = @{
        NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
        NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
    };
    return [[NSMutableAttributedString alloc] initWithData:data
                                                   options:options
                                        documentAttributes:NULL
                                                     error:NULL];
}

static NSMutableAttributedString *FallbackText(NSString *source) {
    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont systemFontOfSize:FallbackFontSize]
    };
    return [[NSMutableAttributedString alloc] initWithString:source attributes:attributes];
}

static NSColor *InkColor(BOOL dark) {
    CGFloat white = dark ? DarkInkWhite : LightInkWhite;
    return [NSColor colorWithWhite:white alpha:ColorOpacity];
}

static NSColor *LinkColor(BOOL dark) {
    CGFloat red = dark ? DarkLinkRed : LightLinkRed;
    CGFloat green = dark ? DarkLinkGreen : LightLinkGreen;
    CGFloat blue = dark ? DarkLinkBlue : LightLinkBlue;
    return [NSColor colorWithSRGBRed:red green:green blue:blue alpha:ColorOpacity];
}

static void ApplyInkColor(NSMutableAttributedString *text, NSColor *color) {
    NSRange entireText = NSMakeRange(0, text.length);
    [text addAttribute:NSForegroundColorAttributeName value:color range:entireText];
    [text removeAttribute:NSStrokeColorAttributeName range:entireText];
}

static void StyleLinks(NSMutableAttributedString *text, NSColor *color) {
    NSRange entireText = NSMakeRange(0, text.length);
    [text enumerateAttribute:NSLinkAttributeName inRange:entireText options:0
        usingBlock:^(id value, NSRange range, BOOL *stop) {
            (void)stop;
            if (value) {
                [text addAttribute:NSForegroundColorAttributeName value:color range:range];
                [text removeAttribute:NSLinkAttributeName range:range];
            }
        }];
}

NSAttributedString *MarkdownTextWithFont(NSString *source, NSAppearance *appearance, NSString *fontFamily) {
    BOOL dark = IsDarkAppearance(appearance);
    NSString *html = HTMLForAppearance(source, dark);
    NSString *family = [fontFamily isEqualToString:@"Sans-serif"] ? @"-apple-system,sans-serif" :
        ([fontFamily isEqualToString:@"Monospace"] ? @"Menlo,monospace" : @"'Iowan Old Style',Georgia,serif");
    html = [html stringByReplacingOccurrencesOfString:@"'Iowan Old Style',Georgia,serif" withString:family];
    html = [html stringByReplacingOccurrencesOfString:@"font-family:-apple-system,sans-serif;font-size:.92em" withString:@"font-size:.92em"];
    NSMutableAttributedString *text = ImportHTML(html) ?: FallbackText(source);
    ApplyInkColor(text, InkColor(dark));
    StyleLinks(text, LinkColor(dark));
    return text;
}

NSAttributedString *MarkdownText(NSString *source, NSAppearance *appearance) {
    return MarkdownTextWithFont(source, appearance, @"Serif");
}
