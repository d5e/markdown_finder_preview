#import <Cocoa/Cocoa.h>
#import "../src/Preview.m"

static BOOL Check(NSString *label, BOOL passed) {
    printf("%s %s\n", passed ? "PASS" : "FAIL", label.UTF8String);
    return passed;
}

static NSFont *BodyFont(NSAttributedString *text) {
    NSRange word = [text.string rangeOfString:@"Rendered"];
    return word.location == NSNotFound ? nil :
        [text attribute:NSFontAttributeName atIndex:word.location effectiveRange:NULL];
}

static BOOL CheckUnits(void) {
    NSString *source = @"**Rendered**";
    NSAppearance *appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    NSFont *serif = BodyFont(MarkdownTextWithFont(source, appearance, @"Serif", 18));
    NSFont *sans = BodyFont(MarkdownTextWithFont(source, appearance, @"Sans-serif", 18));
    NSFont *mono = BodyFont(MarkdownTextWithFont(source, appearance, @"Monospace", 18));
    BOOL passed = Check(@"unit font family selects three distinct families",
        serif && sans && mono.isFixedPitch &&
        ![serif.familyName isEqual:sans.familyName] &&
        ![serif.familyName isEqual:mono.familyName] && ![sans.familyName isEqual:mono.familyName]);

    CGFloat previous = 0;
    BOOL increasing = YES;
    for (NSNumber *size in @[@10, @12, @14, @16, @18]) {
        NSFont *font = BodyFont(MarkdownTextWithFont(source, appearance, @"Serif", size.integerValue));
        increasing &= font.pointSize > previous;
        previous = font.pointSize;
    }
    passed &= Check(@"unit font size increases across all five choices", increasing);

    PreviewViewController *controller = [PreviewViewController new];
    (void)controller.view;
    controller.source = source;
    controller.mode.selectedSegment = 1;
    NSAttributedString *literal = [controller textForAppearance:appearance dark:NO];
    controller.mode.selectedSegment = 0;
    NSAttributedString *rendered = [controller textForAppearance:appearance dark:NO];
    passed &= Check(@"unit mode selects literal or rendered text",
        [literal.string isEqual:source] && ![rendered.string containsString:@"**"] && BodyFont(rendered));

    PreviewScrollView *scroll = [[PreviewScrollView alloc] initWithFrame:NSMakeRect(0, 0, 300, 300)];
    scroll.documentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 200, 500)];
    [scroll tile];
    passed &= Check(@"unit scroll view fits document width and preserves height",
        scroll.documentView.frame.size.width == scroll.contentSize.width &&
        scroll.documentView.frame.size.height == 500);
    return passed;
}

static BOOL CheckControls(PreviewViewController *controller, NSURL *fixture) {
    __block NSError *error = nil;
    [controller preparePreviewOfFileAtURL:fixture completionHandler:^(NSError *failure) { error = failure; }];
    NSAttributedString *text = controller.documentView.textStorage;
    if (error || !BodyFont(text)) return Check(@"integration loads Markdown fixture", NO);

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    id oldFamily = [defaults objectForKey:@"PreviewFontFamily"];
    id oldSize = [defaults objectForKey:@"PreviewFontSize"];
    [defaults removeObjectForKey:@"PreviewFontSize"];
    PreviewViewController *freshController = [PreviewViewController new];
    (void)freshController.view;
    BOOL defaultSize = [freshController.fontSizeChoice.titleOfSelectedItem isEqual:@"14 pt"];
    NSPopUpButton *family = controller.fontChoice;
    NSMutableSet *families = [NSMutableSet set];
    for (NSString *title in @[@"Serif", @"Sans-serif", @"Monospace"]) {
        [family selectItemWithTitle:title];
        [family sendAction:family.action to:family.target];
        NSString *renderedFamily = BodyFont(text).familyName;
        if (renderedFamily) [families addObject:renderedFamily];
    }
    BOOL passed = Check(@"integration font menu redraws each family and saves the choice",
        families.count == 3 && BodyFont(text).isFixedPitch &&
        [[defaults stringForKey:@"PreviewFontFamily"] isEqual:@"Monospace"]);

    NSPopUpButton *size = controller.fontSizeChoice;
    CGFloat previous = 0;
    BOOL increasing = YES;
    for (NSString *title in @[@"10 pt", @"12 pt", @"14 pt", @"16 pt", @"18 pt"]) {
        [size selectItemWithTitle:title];
        [size sendAction:size.action to:size.target];
        CGFloat current = BodyFont(text).pointSize;
        increasing &= current > previous;
        previous = current;
    }
    passed &= Check(@"integration size menu redraws all five sizes and saves the choice",
        defaultSize && size.numberOfItems == 5 && increasing && [defaults integerForKey:@"PreviewFontSize"] == 18);

    NSSegmentedControl *mode = controller.mode;
    BOOL initiallyVisible = !family.hidden && !size.hidden;
    mode.selectedSegment = 1;
    [mode sendAction:mode.action to:mode.target];
    BOOL hiddenInSource = family.hidden && size.hidden;
    BOOL literal = [text.string isEqual:@"**Rendered**\n"];
    mode.selectedSegment = 0;
    [mode sendAction:mode.action to:mode.target];
    passed &= Check(@"integration mode control switches to source and back",
        literal && [text.string containsString:@"Rendered"] && ![text.string containsString:@"**"]);
    passed &= Check(@"integration font menus are visible only in Preview",
        initiallyVisible && hiddenInSource && !family.hidden && !size.hidden);
    [defaults setObject:oldFamily forKey:@"PreviewFontFamily"];
    [defaults setObject:oldSize forKey:@"PreviewFontSize"];
    return passed;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        if (argc != 2) return 2;
        BOOL checks = CheckUnits();
        PreviewViewController *controller = [PreviewViewController new];
        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 500, 500)
            styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
        window.contentView = controller.view;
        [window makeKeyAndOrderFront:nil];
        checks &= CheckControls(controller, [NSURL fileURLWithPath:@(argv[1])]);
        controller.source = [@"A paragraph of words that should reflow across the available width. " stringByPaddingToLength:1500 withString:@" More words follow." startingAtIndex:0];
        [controller updateAppearance];
        [window setContentSize:NSMakeSize(500, 500)];
        [controller.view layoutSubtreeIfNeeded];
        [controller.documentView.layoutManager ensureLayoutForTextContainer:controller.documentView.textContainer];
        CGFloat narrowWidth = controller.documentView.textContainer.containerSize.width;
        CGFloat narrowHeight = [controller.documentView.layoutManager usedRectForTextContainer:controller.documentView.textContainer].size.height;
        [window setContentSize:NSMakeSize(1000, 500)];
        [controller.view layoutSubtreeIfNeeded];
        [controller.documentView.layoutManager ensureLayoutForTextContainer:controller.documentView.textContainer];
        CGFloat wideWidth = controller.documentView.textContainer.containerSize.width;
        CGFloat wideHeight = [controller.documentView.layoutManager usedRectForTextContainer:controller.documentView.textContainer].size.height;
        BOOL passed = wideWidth > narrowWidth + 300 && wideHeight < narrowHeight;
        printf("%s integration preview reflows on resize (width %.0f -> %.0f, height %.0f -> %.0f)\n", passed ? "PASS" : "FAIL", narrowWidth, wideWidth, narrowHeight, wideHeight);
        return passed && checks ? 0 : 1;
    }
}
