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
        BOOL headings = Check(@"Heading", Contains(MarkdownHTML(@"# Grüße", NO), @"<h1>Grüße</h1>"));
        BOOL table = Check(@"Table", Contains(MarkdownHTML(@"| A |\n| --- |\n| B |", NO), @"<td>B</td>"));
        BOOL code = Check(@"Code escaping", Contains(MarkdownHTML(@"\x60\x60\x60\n<a>&\n\x60\x60\x60", NO),
                                                      @"<pre><code>&lt;a&gt;&amp;"));
        BOOL source = Check(@"Literal source", Contains(MarkdownHTML(@"\n# Grüße <b>&", YES),
                                                        @"<pre class='source'>\n\n# Grüße &lt;b&gt;&amp;</pre>"));
        NSString *html = MarkdownHTML(@"<script>alert(1)</script>", NO);
        BOOL rawHTML = Check(@"Raw HTML escaping", !Contains(html, @"<script>") && Contains(html, @"&lt;script&gt;"));
        BOOL theme = Check(@"Dark appearance rule", Contains(MarkdownHTML(@"", NO), @"prefers-color-scheme:dark"));
        BOOL empty = Check(@"Empty document", Contains(MarkdownHTML(@"", NO), @"<body></body>"));
        return headings && table && code && source && rawHTML && theme && empty ? 0 : 1;
    }
}
