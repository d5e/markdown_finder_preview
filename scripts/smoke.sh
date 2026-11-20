#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

python3 scripts/build.py
app="$PWD/build/Markdown Finder Preview.app"
codesign --verify --deep --strict "$app"
echo "PASS signed app and extensions"

scratch=$(mktemp -d "$PWD/build/smoke.XXXXXX")
trap 'rm -r "$scratch"' EXIT
xcrun clang -mmacosx-version-min=10.15 -fobjc-arc -Isrc -Ivendor/md4c \
    tests/render.m src/MarkdownHTML.m vendor/md4c/{md4c.c,md4c-html.c,entity.c} \
    -framework Foundation -o "$scratch/render"
"$scratch/render"

if [[ ${1:-} == --finder ]]; then
    fixture="$scratch/Markdown Finder Smoke.md"
    printf '# Markdown Finder Smoke\n\n**Rendered text**\n' > "$fixture"
    pluginkit -a "$app/Contents/PlugIns/MarkdownPreview.appex"
    pluginkit -a "$app/Contents/PlugIns/MarkdownThumbnail.appex"
    xcrun clang -mmacosx-version-min=10.15 -fobjc-arc tests/thumbnail.m \
        -framework Cocoa -framework QuickLookThumbnailing -o "$scratch/thumbnail"
    "$scratch/thumbnail" "$fixture"
    osascript tests/finder.applescript "$fixture"
fi
