# Markdown Finder Preview

Read Markdown in macOS Finder. Select a Markdown file and press Space to open a typeset Quick Look preview. Use **Preview** and **Source** at the top to switch between the rendered document and its original text. Choose **Serif**, **Sans-serif**, or **Monospace** from the font menu for the rendered preview; the choice is remembered. Each file opens in Preview. Finder’s right-hand Preview pane shows a typeset first-page thumbnail on light paper.

The page follows macOS light and dark appearance. It defaults to Iowan Old Style for reading and uses Menlo for code, and adjusts the reading width as the preview window is resized. The local MD4C renderer supports CommonMark with GitHub-style tables, task lists, and strikethrough. This MVP displays links as text with link styling and keeps navigation and image loading disabled.

## Build and register

Requires macOS Catalina or later with Apple Command Line Tools and Python 3. Tested on Intel macOS 10.15.8.

```sh
python3 scripts/build.py
open -a "$PWD/build/Markdown Finder Preview.app"
```

Dismiss the app’s welcome dialog, select a Markdown file in Finder, and press Space. If another Markdown Quick Look extension takes precedence, select Markdown Finder Preview in System Preferences under Extensions → Quick Look. The app bundle can also be moved to Applications for permanent use.

The MD4C sources in `vendor/md4c` come from upstream tag `release-0.5.2` and include the MIT license.

## Smoke tests

Run `scripts/smoke.sh` to build and verify signing, then check the renderer. Run `scripts/smoke.sh --finder` from a logged-in English-language desktop to also check the Quick Look thumbnail pixels and verify that Finder displays formatted text and literal source when you use the toggle. The Finder test uses System Events and requires Accessibility and Automation access for the shell’s host.
