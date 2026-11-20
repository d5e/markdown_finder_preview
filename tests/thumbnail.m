#import <Cocoa/Cocoa.h>
#import <QuickLookThumbnailing/QuickLookThumbnailing.h>

static bool IsReadablePage(CGImageRef image) {
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    if (width != 440 || height != 420) {
        return false;
    }
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap = CGBitmapContextCreate(NULL, width, height, 8, 4 * width, rgb,
                                                 kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(rgb);
    if (!bitmap) {
        return false;
    }
    CGContextDrawImage(bitmap, CGRectMake(0, 0, width, height), image);
    const uint8_t *pixels = CGBitmapContextGetData(bitmap);
    size_t ink = 0, paper = 0;
    for (size_t i = 0; i < width * height; i++) {
        const uint8_t *pixel = pixels + i * 4;
        if (pixel[3] == 255) {
            paper += pixel[0] > 235 && pixel[1] > 235 && pixel[2] > 235;
            ink += pixel[0] < 100 && pixel[1] < 100 && pixel[2] < 100;
        }
    }
    CGContextRelease(bitmap);
    return paper > width * height / 2 && ink > width * height / 150;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 2) {
            return 2;
        }
        NSURL *file = [NSURL fileURLWithPath:@(argv[1])];
        QLThumbnailGenerationRequest *request = [[QLThumbnailGenerationRequest alloc]
            initWithFileAtURL:file size:CGSizeMake(220, 210) scale:2
            representationTypes:QLThumbnailGenerationRequestRepresentationTypeThumbnail];
        [QLThumbnailGenerator.sharedGenerator generateBestRepresentationForRequest:request
            completionHandler:^(QLThumbnailRepresentation *result, NSError *error) {
                CGImageRef image = result.CGImage;
                if (!image || !IsReadablePage(image)) {
                    NSLog(@"Quick Look did not return a full-size page with visible text. %@", error);
                    exit(1);
                }
                puts("PASS Quick Look thumbnail has visible text across a Retina-sized page");
                exit(0);
            }];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            fputs("Quick Look thumbnail request timed out\n", stderr);
            exit(2);
        });
        [[NSRunLoop currentRunLoop] run];
    }
}
