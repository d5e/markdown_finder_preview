#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "MarkdownText.h"

@interface PreviewTextView : NSTextView
@property(nonatomic, copy) void (^appearanceDidChange)(void);
@end

@implementation PreviewTextView
- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
    if (self.appearanceDidChange) {
        self.appearanceDidChange();
    }
}
@end

@interface PreviewViewController : NSViewController <QLPreviewingController>
@property(nonatomic, strong) NSSegmentedControl *mode;
@property(nonatomic, strong) PreviewTextView *documentView;
@property(nonatomic, copy) NSString *source;
@end

@implementation PreviewViewController

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 760, 680)];
    self.preferredContentSize = self.view.frame.size;

    NSVisualEffectView *bar = [self createToolbar];
    NSScrollView *scroll = [self createDocumentScrollView];
    [self.view addSubview:bar];
    [self.view addSubview:scroll];
    [self constrainToolbar:bar scrollView:scroll];
}

- (NSVisualEffectView *)createToolbar {
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
    return bar;
}

- (NSScrollView *)createDocumentScrollView {
    NSScrollView *scroll = [[NSScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.hasVerticalScroller = YES;
    scroll.drawsBackground = YES;

    self.documentView = [[PreviewTextView alloc] init];
    self.documentView.editable = NO;
    self.documentView.selectable = YES;
    self.documentView.drawsBackground = NO;
    self.documentView.verticallyResizable = YES;
    self.documentView.autoresizingMask = NSViewWidthSizable;
    self.documentView.textContainer.widthTracksTextView = YES;
    self.documentView.textContainerInset = NSMakeSize(38, 30);
    [self.documentView setAccessibilityLabel:@"Markdown document"];
    scroll.documentView = self.documentView;
    __weak typeof(self) weakSelf = self;
    self.documentView.appearanceDidChange = ^{
        [weakSelf updateAppearance];
    };

    return scroll;
}

- (void)constrainToolbar:(NSVisualEffectView *)bar scrollView:(NSScrollView *)scroll {
    [NSLayoutConstraint activateConstraints:@[
        [bar.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [bar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [bar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [bar.heightAnchor constraintEqualToConstant:42],
        [self.mode.centerXAnchor constraintEqualToAnchor:bar.centerXAnchor],
        [self.mode.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],
        [scroll.topAnchor constraintEqualToAnchor:bar.bottomAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)preparePreviewOfFileAtURL:(NSURL *)url completionHandler:(void (^)(NSError *))handler {
    NSError *error = nil;
    NSString *source = ReadMarkdown(url, &error);
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
    [self updateAppearance];
    [self.documentView setSelectedRange:NSMakeRange(0, 0)];
    [self.documentView scrollRangeToVisible:NSMakeRange(0, 0)];
}

- (void)updateAppearance {
    if (!self.source) {
        return;
    }
    NSAppearance *appearance = self.documentView.effectiveAppearance;
    BOOL dark = [[appearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]]
        isEqualToString:NSAppearanceNameDarkAqua];
    self.documentView.enclosingScrollView.backgroundColor =
        dark ? [NSColor colorWithWhite:0.125 alpha:1] : NSColor.whiteColor;

    NSAttributedString *text = [self textForAppearance:appearance dark:dark];
    [self.documentView.textStorage setAttributedString:text];
}

- (NSAttributedString *)textForAppearance:(NSAppearance *)appearance dark:(BOOL)dark {
    if (self.mode.selectedSegment != 1) {
        return MarkdownText(self.source, appearance);
    }

    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont monospacedSystemFontOfSize:13 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: dark ? NSColor.whiteColor : NSColor.blackColor
    };
    return [[NSAttributedString alloc] initWithString:self.source attributes:attributes];
}
@end
