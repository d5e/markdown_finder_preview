#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <WebKit/WebKit.h>
#import "MarkdownHTML.h"

@interface PreviewViewController : NSViewController <QLPreviewingController, WKNavigationDelegate>
@property(nonatomic, strong) NSSegmentedControl *mode;
@property(nonatomic, strong) WKWebView *documentView;
@property(nonatomic, copy) NSString *source;
@end

@implementation PreviewViewController

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 760, 680)];
    self.preferredContentSize = self.view.frame.size;

    NSVisualEffectView *bar = [[NSVisualEffectView alloc] init];
    bar.material = NSVisualEffectMaterialHeaderView;
    bar.blendingMode = NSVisualEffectBlendingModeWithinWindow;
    bar.translatesAutoresizingMaskIntoConstraints = NO;

    self.mode = [NSSegmentedControl segmentedControlWithLabels:@[@"Preview", @"Source"]
        trackingMode:NSSegmentSwitchTrackingSelectOne target:self action:@selector(showSelectedMode:)];
    self.mode.selectedSegment = 0;
    self.mode.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mode setAccessibilityLabel:@"Markdown view"];
    [bar addSubview:self.mode];

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.preferences.javaScriptEnabled = NO;
    configuration.websiteDataStore = [WKWebsiteDataStore nonPersistentDataStore];
    self.documentView = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:configuration];
    self.documentView.navigationDelegate = self;
    self.documentView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:bar];
    [self.view addSubview:self.documentView];
    [NSLayoutConstraint activateConstraints:@[
        [bar.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [bar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [bar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [bar.heightAnchor constraintEqualToConstant:42],
        [self.mode.centerXAnchor constraintEqualToAnchor:bar.centerXAnchor],
        [self.mode.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],
        [self.documentView.topAnchor constraintEqualToAnchor:bar.bottomAnchor],
        [self.documentView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.documentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.documentView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)preparePreviewOfFileAtURL:(NSURL *)url completionHandler:(void (^)(NSError *))handler {
    NSError *error = nil;
    NSString *source = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
    if (!source) {
        source = [NSString stringWithContentsOfURL:url usedEncoding:NULL error:&error];
    }
    if (!source) {
        handler(error);
        return;
    }
    (void)self.view;
    self.source = source;
    self.mode.selectedSegment = 0;
    [self showSelectedMode:self.mode];
    handler(nil);
}

- (void)showSelectedMode:(NSSegmentedControl *)sender {
    [self.documentView loadHTMLString:MarkdownHTML(self.source ?: @"", sender.selectedSegment == 1)
                              baseURL:nil];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)action
decisionHandler:(void (^)(WKNavigationActionPolicy))handler {
    BOOL generatedDocument = [action.request.URL.absoluteString isEqualToString:@"about:blank"];
    handler(generatedDocument ? WKNavigationActionPolicyAllow : WKNavigationActionPolicyCancel);
}
@end

extern int NSExtensionMain(int argc, const char *argv[]);
int main(int argc, const char *argv[]) {
    return NSExtensionMain(argc, argv);
}
