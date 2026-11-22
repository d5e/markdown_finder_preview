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

@interface PreviewScrollView : NSScrollView
@end

@implementation PreviewScrollView
- (void)tile {
    [super tile];
    NSView *document = self.documentView;
    CGFloat width = self.contentSize.width;
    if (document && width > 0 && document.frame.size.width != width) {
        [document setFrameSize:NSMakeSize(width, document.frame.size.height)];
    }
}
@end

@interface PreviewViewController : NSViewController <QLPreviewingController>
@property(nonatomic, strong) NSSegmentedControl *mode;
@property(nonatomic, strong) NSPopUpButton *fontChoice;
@property(nonatomic, strong) NSPopUpButton *fontSizeChoice;
@property(nonatomic, strong) PreviewTextView *documentView;
@property(nonatomic, copy) NSString *source;
@end

@implementation PreviewViewController

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 760, 680)];
    self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

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

    self.fontChoice = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    [self.fontChoice addItemsWithTitles:@[@"Serif", @"Sans-serif", @"Monospace"]];
    NSString *savedFont = [[NSUserDefaults standardUserDefaults] stringForKey:@"PreviewFontFamily"];
    if (savedFont && [self.fontChoice itemWithTitle:savedFont]) [self.fontChoice selectItemWithTitle:savedFont];
    self.fontChoice.target = self;
    self.fontChoice.action = @selector(changeFont:);
    self.fontChoice.translatesAutoresizingMaskIntoConstraints = NO;
    [self.fontChoice setAccessibilityLabel:@"Preview font"];
    [bar addSubview:self.fontChoice];

    self.fontSizeChoice = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    [self.fontSizeChoice addItemsWithTitles:@[@"10 pt", @"12 pt", @"14 pt", @"16 pt", @"18 pt"]];
    NSInteger savedSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"PreviewFontSize"];
    NSString *sizeTitle = [NSString stringWithFormat:@"%ld pt", (long)savedSize];
    [self.fontSizeChoice selectItemWithTitle:@"14 pt"];
    if ([self.fontSizeChoice itemWithTitle:sizeTitle]) [self.fontSizeChoice selectItemWithTitle:sizeTitle];
    self.fontSizeChoice.target = self;
    self.fontSizeChoice.action = @selector(changeFontSize:);
    self.fontSizeChoice.translatesAutoresizingMaskIntoConstraints = NO;
    [self.fontSizeChoice setAccessibilityLabel:@"Preview font size"];
    [bar addSubview:self.fontSizeChoice];
    return bar;
}

- (NSScrollView *)createDocumentScrollView {
    NSScrollView *scroll = [[PreviewScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.hasVerticalScroller = YES;
    scroll.drawsBackground = YES;

    self.documentView = [[PreviewTextView alloc] initWithFrame:NSZeroRect];
    self.documentView.editable = NO;
    self.documentView.selectable = YES;
    self.documentView.drawsBackground = NO;
    self.documentView.verticallyResizable = YES;
    self.documentView.horizontallyResizable = NO;
    self.documentView.minSize = NSMakeSize(0, 0);
    self.documentView.maxSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
    self.documentView.textContainer.containerSize = NSMakeSize(0, CGFLOAT_MAX);
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
        [self.fontSizeChoice.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor constant:-12],
        [self.fontSizeChoice.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],
        [self.fontChoice.trailingAnchor constraintEqualToAnchor:self.fontSizeChoice.leadingAnchor constant:-8],
        [self.fontChoice.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.mode.trailingAnchor constant:12],
        [self.fontChoice.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],
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

- (void)changeFont:(id)sender {
    (void)sender;
    [[NSUserDefaults standardUserDefaults] setObject:self.fontChoice.titleOfSelectedItem forKey:@"PreviewFontFamily"];
    [self updateAppearance];
}

- (void)changeFontSize:(id)sender {
    (void)sender;
    NSInteger size = self.fontSizeChoice.titleOfSelectedItem.integerValue;
    [[NSUserDefaults standardUserDefaults] setInteger:size forKey:@"PreviewFontSize"];
    [self updateAppearance];
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
        return MarkdownTextWithFont(self.source, appearance, self.fontChoice.titleOfSelectedItem,
            self.fontSizeChoice.titleOfSelectedItem.integerValue);
    }

    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont monospacedSystemFontOfSize:13 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: dark ? NSColor.whiteColor : NSColor.blackColor
    };
    return [[NSAttributedString alloc] initWithString:self.source attributes:attributes];
}
@end
