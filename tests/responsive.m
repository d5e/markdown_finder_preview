#import <Cocoa/Cocoa.h>
#import "../src/Preview.m"

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        PreviewViewController *controller = [PreviewViewController new];
        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 500, 500)
            styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
        window.contentView = controller.view;
        [window makeKeyAndOrderFront:nil];
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
        printf("%s preview reflows on resize (width %.0f -> %.0f, height %.0f -> %.0f)\n", passed ? "PASS" : "FAIL", narrowWidth, wideWidth, narrowHeight, wideHeight);
        return passed ? 0 : 1;
    }
}
