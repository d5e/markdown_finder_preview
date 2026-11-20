#!/usr/bin/env python3
import os
import plistlib
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
os.chdir(root)
app = root / "build/Markdown Finder Preview.app"
extension = app / "Contents/PlugIns/MarkdownPreview.appex"
bundle_id = "io.github.d5e.MarkdownFinderPreview"
markdown_type = "net.daringfireball.markdown"


def run(*args):
    subprocess.run(args, check=True)


def bundle(path, executable, identifier, package, **extra):
    contents = path / "Contents"
    binary = contents / "MacOS" / executable
    binary.parent.mkdir(parents=True, exist_ok=True)
    with (contents / "Info.plist").open("wb") as plist:
        plistlib.dump(dict(
            CFBundleExecutable=executable, CFBundleIdentifier=identifier,
            CFBundleName=executable, CFBundlePackageType=package,
            CFBundleShortVersionString="0.1.0", CFBundleVersion="1",
            LSMinimumSystemVersion="10.15", **extra
        ), plist)
    return binary


host = bundle(
    app, "Markdown Finder Preview", bundle_id, "APPL", LSUIElement=True,
    UTImportedTypeDeclarations=[dict(
        UTTypeIdentifier=markdown_type, UTTypeDescription="Markdown document",
        UTTypeConformsTo=["public.plain-text"],
        UTTypeTagSpecification={"public.filename-extension": ["md", "markdown", "mdown", "mkd", "mkdn"]},
    )],
)
preview = bundle(
    extension, "MarkdownPreview", bundle_id + ".Preview", "XPC!",
    NSExtension=dict(
        NSExtensionPointIdentifier="com.apple.quicklook.preview",
        NSExtensionPrincipalClass="PreviewViewController",
        NSExtensionAttributes=dict(
            QLSupportedContentTypes=[markdown_type, "com.unknown.md", "org.commonmark.commonmark"],
        ),
    ),
)
flags = ("-mmacosx-version-min=10.15", "-O2", "-Wall", "-Wextra")
run("xcrun", "clang", *flags, "-fobjc-arc", "src/Host.m", "-framework", "Cocoa", "-o", str(host))
run("xcrun", "clang", *flags, "-fobjc-arc", "-fapplication-extension", "-Ivendor/md4c",
    "src/Preview.m", "src/MarkdownHTML.m", "vendor/md4c/md4c.c", "vendor/md4c/md4c-html.c",
    "vendor/md4c/entity.c", "-framework", "Cocoa", "-framework", "QuickLook",
    "-framework", "WebKit", "-o", str(preview))
run("codesign", "--force", "--sign", "-", "--entitlements", "src/Preview.entitlements", str(extension))
run("codesign", "--force", "--sign", "-", str(app))
run("codesign", "--verify", "--deep", "--strict", str(app))
print(app)
