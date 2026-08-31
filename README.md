# Clipboard Manager

A small, native macOS menu-bar app for keeping a local history of copied text and quickly copying an older entry again.

The project is designed as a private personal utility: no accounts, cloud synchronization, analytics, subscriptions, backend, or network connection.

## Status

The product and implementation specifications are complete. Application implementation follows the phases in [`specs`](specs) in numeric order.

## Core experience

- Runs quietly in the macOS menu bar.
- Records plain-text clipboard changes locally.
- Opens a compact picker with `Control + Shift + Space` (`⌃⇧Space`).
- Shows Recent and Favorites tabs.
- Searches clipboard history as the user types.
- Pins frequently used entries as favorites.
- Configures the recent-history limit from 10 to 100 entries.
- Supports mouse and keyboard navigation.
- Automatically supports light and dark mode.

Selecting an entry copies it back to the system clipboard and automatically pastes it into the application that was active before the picker opened when macOS Accessibility permission is available. Without permission, the item remains available for manual `⌘V`.

## Keyboard controls

| Action | Shortcut |
| --- | --- |
| Open or close the picker | `⌃⇧Space` |
| Copy first visible entry | `⌘0` |
| Copy second visible entry | `⌘1` |
| Copy third through tenth visible entries | `⌘2` through `⌘9` |
| Move selection | Up/Down arrows |
| Copy selected entry | Return |
| Close picker | Escape |
| Focus search | `⌘F` or start typing |

The number mapping is intentional: `⌘0` selects the first result, `⌘1` the second, and `⌘9` the tenth. These shortcuts follow the currently visible filtered order.

## Requirements

- macOS 14 or newer
- Xcode with the macOS 14 SDK or newer
- Swift 5.9 or newer

## Technology

- Swift and SwiftUI
- AppKit for floating-panel behavior
- SwiftData for local persistence
- `NSPasteboard` for clipboard monitoring
- `SMAppService` for launch at login
- [`KeyboardShortcuts`](https://github.com/sindresorhus/KeyboardShortcuts) for the global shortcut
- XCTest for automated testing

## Project structure

The planned application structure is:

```text
ClipboardManager/
├── App/
├── Models/
├── Services/
├── Picker/
├── Settings/
├── MenuBar/
└── Tests/

specs/
ClipboardManagerTests/
```

## Specifications

Start with the product contract, then implement one phase at a time:

1. [`00-product-spec.md`](specs/00-product-spec.md) — authoritative scope and behavior
2. [`01-foundation-and-storage.md`](specs/01-foundation-and-storage.md) — project shell, SwiftData, repository and settings
3. [`02-clipboard-monitoring.md`](specs/02-clipboard-monitoring.md) — pasteboard observation and deduplication
4. [`03-picker-interface.md`](specs/03-picker-interface.md) — floating panel, Recent, Favorites and search
5. [`04-keyboard-and-selection.md`](specs/04-keyboard-and-selection.md) — global shortcut and keyboard workflow
6. [`05-settings-and-menu-bar.md`](specs/05-settings-and-menu-bar.md) — settings, login item, sound and menu completion
7. [`06-testing-and-release.md`](specs/06-testing-and-release.md) — regression testing and release readiness

Every implementation agent must read `00-product-spec.md` first, complete only its assigned phase, run that phase's checks, report the result, and stop before the next phase.

## Building

This repository uses Swift Package Manager. From the repository root:

```sh
swift build
swift test
swift build -c release
```

The executable is a macOS menu-bar application and can also be opened in Xcode as a Swift package for interactive builds and manual testing.

Convenience Makefile targets are also available:

```sh
make test       # Debug build, tests, then launch the app
make release    # Release build, then launch the app
make bundle     # Build ClipboardManager.app in .build
make install    # Build, sign and install ClipboardManager.app in /Applications
```

Both launch targets keep running until the app is quit or interrupted with `Ctrl+C`.

## Privacy

All clipboard entries and preferences remain on the Mac. The app does not require an account, network access, or Accessibility permission.

Version 1 stores text only. Images, files, HTML and rich clipboard formats are intentionally unsupported.

## Development rules

- Treat `00-product-spec.md` as the source of truth.
- Implement phases in numeric order.
- Do not add out-of-scope features during version 1.
- Build after each focused task.
- Run all existing tests before completing a phase.
- Commit `Package.resolved` so dependency versions remain reproducible.
- Never commit local signing identities, secrets, Derived Data or user-specific Xcode settings.

## License

This is a personal project. No public license has been selected.
