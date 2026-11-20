#import <Cocoa/Cocoa.h>

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Markdown Finder Preview";
        alert.informativeText = @"Select a Markdown file in Finder and press Space. Use the control at the top to switch between Preview and Source.";
        [NSApp activateIgnoringOtherApps:YES];
        [alert runModal];
    }
    return 0;
}
