#import "MarkdownHTML.h"
#import "md4c-html.h"

static const unsigned MarkdownParserFlags = MD_DIALECT_GITHUB | MD_FLAG_NOHTML;
static const unsigned HTMLRendererFlags = 0;
static const int ParserSuccess = 0;
static NSString * const RenderFailureHTML = @"<p>Markdown could not be rendered.</p>";
static NSString * const HTMLDocumentTemplate =
    @"<!doctype html><html><head><meta charset='utf-8'>"
    "<meta name='viewport' content='width=device-width, initial-scale=1'>"
    "<meta http-equiv='Content-Security-Policy' content=\"default-src 'none'; style-src 'unsafe-inline'\">"
    "<style>"
    ":root{color-scheme:light dark;--paper:#fff;--ink:#262423;--muted:#595553;--rule:#dedbd7;--wash:#f5f3f0;--link:#215b8f}"
    "@media(prefers-color-scheme:dark){:root{--paper:#202123;--ink:#eeece7;--muted:#c0bab3;--rule:#4c4a47;--wash:#2c2d30;--link:#9acbf1}}"
    "html{background:var(--paper);color:var(--ink);overflow-wrap:anywhere}"
    "body{box-sizing:border-box;max-width:72ch;margin:auto;padding:clamp(24px,5vw,54px);font:18px/1.64 'Iowan Old Style',Georgia,serif;"
    "font-kerning:normal;font-variant-numeric:oldstyle-nums}"
    "h1,h2,h3,h4,h5,h6{line-height:1.17;margin:1.5em 0 .45em;font-weight:700}"
    "h1{font-size:2.35em;letter-spacing:-.025em}h2{font-size:1.65em}h3{font-size:1.26em}"
    "h4,h5,h6{font-family:-apple-system,sans-serif;font-size:.92em}"
    "body>:first-child{margin-top:0}p,ul,ol,blockquote,pre,table{margin:0 0 1em}"
    "ul,ol{padding-left:1.45em}li>ul,li>ol{margin-bottom:0}li+li{margin-top:.2em}"
    "blockquote{margin-left:1.2em;border-left:2px solid var(--rule);padding-left:1em;font-style:italic;color:var(--muted)}"
    "a{color:var(--link)}hr{border:0;border-top:1px solid var(--rule);margin:1.8em 0}"
    "pre,code{font-family:Menlo,monospace;font-size:.79em;font-variant-numeric:normal}"
    "code{padding:.15em .3em;background:var(--wash);border-radius:3px}"
    "pre{padding:.85em 1em;background:var(--wash);overflow:auto;line-height:1.6}"
    "pre code{font-size:inherit;padding:0}"
    "table{width:100%%;border-collapse:collapse;font-variant-numeric:tabular-nums}"
    "th,td{padding:.25em .75em;border-bottom:1px solid var(--rule)}"
    "</style></head><body>%@</body></html>";

static void AppendHTML(const MD_CHAR *text, MD_SIZE size, void *context) {
    [(__bridge NSMutableData *)context appendBytes:text length:size];
}

static NSString *RenderMarkdownBody(NSString *source) {
    NSData *input = [source dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *output = [NSMutableData data];
    int result = md_html(input.bytes ?: "", (MD_SIZE)input.length, AppendHTML,
                         (__bridge void *)output, MarkdownParserFlags, HTMLRendererFlags);
    if (result != ParserSuccess) {
        return RenderFailureHTML;
    }

    NSString *body = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
    return body ?: RenderFailureHTML;
}

NSString *MarkdownHTML(NSString *source) {
    NSString *body = RenderMarkdownBody(source);
    return [NSString stringWithFormat:HTMLDocumentTemplate, body];
}
