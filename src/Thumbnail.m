#import <QuickLookThumbnailing/QuickLookThumbnailing.h>
#import "MarkdownText.h"

@interface MarkdownThumbnailProvider : QLThumbnailProvider
@end

@implementation MarkdownThumbnailProvider

- (void)provideThumbnailForFileRequest:(QLFileThumbnailRequest *)request
                     completionHandler:(void (^)(QLThumbnailReply *, NSError *))handler {
    NSError *error = nil;
    NSString *source = ReadMarkdown(request.fileURL, &error);
    if (!source) {
        handler(nil, error);
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // A thumbnail only shows the start of the document.
        NSUInteger limit = 8000;
        if (source.length > limit) {
            limit = [source rangeOfComposedCharacterSequenceAtIndex:limit].location;
        }
        NSString *excerpt = [source substringToIndex:MIN(limit, source.length)];
        NSAppearance *paperAppearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
        NSAttributedString *text = MarkdownText(excerpt, paperAppearance);
        CGSize size = request.maximumSize;
        CGFloat scale = MIN(1, size.width / 270);
        NSRect page = NSMakeRect(0, 0, size.width / scale, size.height / scale);
        NSRect inset = NSInsetRect(page, 16, 14);
        QLThumbnailReply *reply = [QLThumbnailReply replyWithContextSize:size drawingBlock:^BOOL(CGContextRef context) {
            CGContextSaveGState(context);
            // Catalina passes a bitmap in pixel coordinates even for Retina requests.
            CGFloat pixelWidth = CGBitmapContextGetWidth(context);
            CGFloat pixelHeight = CGBitmapContextGetHeight(context);
            CGContextConcatCTM(context, CGAffineTransformInvert(CGContextGetCTM(context)));
            CGContextTranslateCTM(context, 0, pixelHeight);
            CGContextScaleCTM(context, pixelWidth / page.size.width, -pixelHeight / page.size.height);
            [NSGraphicsContext saveGraphicsState];
            NSGraphicsContext.currentContext = [NSGraphicsContext graphicsContextWithCGContext:context flipped:YES];
            [[NSColor colorWithWhite:0.99 alpha:1] setFill];
            NSRectFill(page);
            NSRectClip(inset);
            [text drawWithRect:NSMakeRect(inset.origin.x, inset.origin.y, inset.size.width, CGFLOAT_MAX)
                       options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading];
            [NSGraphicsContext restoreGraphicsState];
            CGContextRestoreGState(context);
            return YES;
        }];
        handler(reply, nil);
    });
}

@end
