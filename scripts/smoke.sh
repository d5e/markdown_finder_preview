#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

group=${1:---ci}
case "$group" in
    --ci|--finder|--all) ;;
    *) echo "Usage: $0 [--ci|--finder|--all]" >&2; exit 2 ;;
esac

python3 scripts/build.py
app="$PWD/build/Markdown Finder Preview.app"
codesign --verify --deep --strict "$app"
echo "PASS signed app and extensions"

scratch=$(mktemp -d "$PWD/build/smoke.XXXXXX")
trap 'rm -r "$scratch"' EXIT
if [[ $group != --finder ]]; then
    xcrun clang -mmacosx-version-min=10.15 -fobjc-arc -Isrc -Ivendor/md4c \
        tests/render.m src/MarkdownHTML.m vendor/md4c/{md4c.c,md4c-html.c,entity.c} \
        -framework Foundation -o "$scratch/render"
    "$scratch/render"

    xcrun clang -mmacosx-version-min=10.15 -fobjc-arc -Isrc -Ivendor/md4c \
        tests/preview.m src/MarkdownText.m src/MarkdownHTML.m vendor/md4c/{md4c.c,md4c-html.c,entity.c} \
        -framework Cocoa -framework QuickLook -o "$scratch/preview"
    printf '**Rendered**\n' > "$scratch/controls.md"
    "$scratch/preview" "$scratch/controls.md"

    xcrun clang -mmacosx-version-min=10.15 -fobjc-arc -Isrc -Ivendor/md4c \
        tests/browser.m src/MarkdownHTML.m vendor/md4c/{md4c.c,md4c-html.c,entity.c} \
        -framework Cocoa -framework WebKit -o "$scratch/browser"
    "$scratch/browser"
fi

if [[ $group != --ci ]]; then
    fixture="$scratch/Markdown Finder Smoke.md"
    printf '# Markdown Finder Smoke\n\n**Rendered text**\n' > "$fixture"
    pluginkit -a "$app/Contents/PlugIns/MarkdownPreview.appex"
    pluginkit -a "$app/Contents/PlugIns/MarkdownThumbnail.appex"
    xcrun clang -mmacosx-version-min=10.15 -fobjc-arc tests/thumbnail.m \
        -framework Cocoa -framework QuickLookThumbnailing -o "$scratch/thumbnail"
    "$scratch/thumbnail" "$fixture"
    osascript tests/finder.applescript "$fixture"
fi
