#import "MarkdownHTML.h"

static BOOL Contains(NSString *html, NSString *fragment) {
    return [html containsString:fragment];
}

static BOOL Check(NSString *name, BOOL passed) {
    printf("%s %s\n", passed ? "PASS" : "FAIL", name.UTF8String);
    return passed;
}

int main(void) {
    @autoreleasepool {
        BOOL headings = Check(@"Heading", Contains(MarkdownHTML(@"# Grüße"), @"<h1>Grüße</h1>"));
        BOOL table = Check(@"Table", Contains(MarkdownHTML(@"| A |\n| --- |\n| B |"), @"<td>B</td>"));
        BOOL code = Check(@"Code escaping", Contains(MarkdownHTML(@"\x60\x60\x60\n<a>&\n\x60\x60\x60"),
                                                      @"<pre><code>&lt;a&gt;&amp;"));
        NSString *html = MarkdownHTML(@"<script>alert(1)</script>");
        BOOL rawHTML = Check(@"Raw HTML escaping", !Contains(html, @"<script>") && Contains(html, @"&lt;script&gt;"));
        BOOL theme = Check(@"Dark appearance rule", Contains(MarkdownHTML(@""), @"prefers-color-scheme:dark"));
        BOOL empty = Check(@"Empty document", Contains(MarkdownHTML(@""), @"<body></body>"));
        return headings && table && code && rawHTML && theme && empty ? 0 : 1;
    }
}
