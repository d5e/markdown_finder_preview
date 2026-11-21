#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "MarkdownHTML.h"

@interface BrowserCheck : NSObject <WKNavigationDelegate>
@property(nonatomic, strong) WKWebView *browser;
@end

@implementation BrowserCheck
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSString *script = @"document.querySelector('h1').textContent + '|' + document.querySelector('strong').textContent";
    [webView evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
        if (error || ![result isEqual:@"Preview heading|bold text"]) {
            NSLog(@"Browser preview failed: %@ %@", result, error);
            exit(1);
        }
        puts("PASS browser renders heading and bold text");
        exit(0);
    }];
}
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"Browser preview failed: %@", error);
    exit(1);
}
@end

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        BrowserCheck *check = [BrowserCheck new];
        check.browser = [[WKWebView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
        check.browser.navigationDelegate = check;
        NSString *html = MarkdownHTML(@"# Preview heading\n\n**bold text**");
        [check.browser loadHTMLString:html baseURL:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            fputs("Browser preview timed out\n", stderr);
            exit(1);
        });
        [NSApp run];
    }
}
