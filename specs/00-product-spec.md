# Clipboard Manager — Product Specification

## Document role

This is the source of truth for the product. Every implementation phase must comply with this file.

Implementation agents must follow these rules:

1. Read this entire file before reading a phase specification.
2. Implement only the assigned phase.
3. Do not change product behavior without explicit approval.
4. Build and run the checks listed in the phase specification.
5. Stop after the phase completion report. Do not begin the next phase.

If a phase specification conflicts with this file, this file wins.

## Product summary

Build a personal, native macOS menu-bar application that records copied text and lets the user copy an older item again.

The application is local-only. It has no accounts, backend, synchronization, analytics, subscriptions, or network requests.

## Primary workflow

1. The app runs in the macOS menu bar with no permanent Dock icon.
2. It monitors `NSPasteboard.general` for copied text.
3. The user presses `Control + Shift + Space` (`⌃⇧Space`).
4. A compact floating picker opens above the currently active app.
5. The picker starts on Recent with an empty search field.
6. The user chooses an older item.
7. The chosen text is written to the system clipboard.
8. The picker closes.
9. The user pastes normally with `Command + V`.

The app must copy the selected entry. It must not automatically paste or simulate keystrokes in another application.

## Required keyboard behavior

| Action | Shortcut |
| --- | --- |
| Open or close picker | `⌃⇧Space` |
| First visible entry | `⌘0` |
| Second visible entry | `⌘1` |
| Third through tenth visible entries | `⌘2` through `⌘9` |
| Move selection | Up and Down arrows |
| Copy selected entry | Return |
| Close picker | Escape |
| Focus search | Start typing or `⌘F` |

The number mapping is intentional: digit 0 maps to visible index 0, digit 1 maps to visible index 1, and digit 9 maps to visible index 9.

The mapping always uses the first ten currently visible results after tab selection and search filtering. If a mapped row does not exist, do nothing.

## Clipboard history rules

- Version 1 stores plain text only.
- Default recent-history limit: 20.
- Configurable limit: 10–100 in increments of 5.
- The panel has a fixed maximum height and scrolls.
- Ignore non-text clipboard content.
- Ignore empty or whitespace-only text.
- Preserve accepted text exactly, including whitespace and line breaks.
- Use exact Swift `String` equality for duplicate detection.
- Do not trim, lowercase, or normalize before comparing duplicates.
- A duplicate updates the existing entry's `copiedAt` date and moves it to the top of Recent.
- A new entry starts as non-favorite.
- Recent is ordered by `copiedAt` descending.
- When the history limit is exceeded, delete the oldest non-favorite entries.
- Selecting an older entry copies its complete original text.
- If `Move selected items to the top` is enabled, selection updates `copiedAt`.
- An app-generated clipboard write must never cause an infinite loop or duplicate.

## Favorites rules

- Each row has a pin control.
- A pinned entry appears in Favorites.
- Favorites are unlimited and do not count toward the Recent limit.
- A favorite can appear in Recent and Favorites at the same time.
- Favorites persist across restarts and history cleanup.
- Favorites are ordered by `favoritedAt` descending.
- Re-copying a favorite must not change Favorites ordering.
- Clicking a pin must not copy the row or close the picker.
- Unpinning keeps the entry in Recent if it is still inside the recent limit.

## Search rules

- Search is case-insensitive.
- Search matches any substring of the full original text.
- Search filters only the active tab.
- Results update as the user types.
- Each panel opening resets to Recent with empty search.
- Select the first result when results exist.
- Show `No matching clipboard entries` when a search has no results.
- Show a tab-specific empty state when there are no stored entries.

## Required screens

### Menu-bar menu

Use a system-style clipboard icon and provide:

1. `Show Clipboard` with displayed shortcut `⌃⇧Space`.
2. `Settings…`.
3. Divider.
4. `Quit Clipboard Manager`.

### Floating picker

- Reusable floating `NSPanel` hosting SwiftUI.
- Width: 490 points.
- Maximum height: 650 points.
- Rounded, translucent native material with a subtle shadow.
- No title bar or traffic-light controls.
- Center on the screen containing the active app.
- Close on selection, Escape, focus loss, or a second global-shortcut press.
- Automatically support light and dark appearances.

Layout order:

1. `Clipboard` heading.
2. `Recent` / `Favorites` segmented control.
3. Search field with placeholder `Search clipboard`.
4. Scrollable results.
5. Footer with entry count and Settings gear.

Each result row:

- Approximately 54 points high.
- Shows a one-line preview; display line breaks as spaces.
- Truncates long preview text with an ellipsis.
- Shows `⌘0`–`⌘9` badges for only the first ten visible entries.
- Reserves equal leading space on rows after the tenth.
- Shows filled pin for favorites and outline pin otherwise.
- Highlights the keyboard-selected row with restrained system blue.

### Settings

One General screen is sufficient. Do not create empty sidebar sections.

Show controls in this order:

1. `Launch at login` toggle.
2. `Play sound when copying` toggle.
3. `Entries shown in picker` stepper and current value.
4. `Choose between 10 and 100 entries.` supporting text.
5. Read-only `Global shortcut` displaying `⌃ ⇧ Space`.
6. `Move selected items to the top` toggle.
7. `Clear Clipboard History…` destructive button.

Clear confirmation:

- Title: `Clear clipboard history?`
- Message: `This removes all recent entries. Favorites will be kept.`
- Cancel: `Cancel`
- Confirmation: `Clear History`

## Technical baseline

| Area | Required choice |
| --- | --- |
| Language | Swift 5.9 or newer |
| Minimum OS | macOS 14 |
| UI | SwiftUI plus AppKit for panel behavior |
| Persistence | SwiftData |
| Clipboard | `NSPasteboard.general` |
| Detection | Poll `changeCount` every 0.5 seconds |
| Global shortcut | Sindre Sorhus `KeyboardShortcuts` package |
| Login item | `SMAppService.mainApp` |
| Testing | XCTest plus manual macOS interaction tests |

Do not request Accessibility permission.

## Data model

Use one SwiftData model:

```swift
@Model
final class ClipboardEntry {
    @Attribute(.unique) var id: UUID
    var text: String
    var copiedAt: Date
    var isFavorite: Bool
    var favoritedAt: Date?
}
```

Generate `id` during insertion. Do not make `text` a SwiftData unique attribute. Enforce text uniqueness in the repository.

## Settings and defaults

Store settings through one observable `AppSettings` backed by `UserDefaults`.

| Setting | Type | Default |
| --- | --- | --- |
| `historyLimit` | Integer | 20 |
| `launchAtLogin` | Boolean | false |
| `moveSelectedToTop` | Boolean | true |
| `playCopySound` | Boolean | false |

Clamp `historyLimit` to 10–100 on every read and write.

## Required project structure

Equivalent names are allowed only if the project already has a clear convention.

```text
ClipboardManager/
├── App/
├── Models/
├── Services/
├── Picker/
├── Settings/
├── MenuBar/
└── Tests/
```

## Out of scope

Do not implement:

- Accounts, authentication, or profiles.
- Network access, cloud sync, or a backend.
- Analytics or telemetry.
- Images, files, HTML, rich text, or colors.
- Automatic pasting.
- iPhone or iPad versions.
- Encryption or password protection.
- Per-application exclusions.
- Custom themes.
- Multiple picker windows.
- Payments, subscriptions, or App Store commerce.
- Editable global shortcut in version 1.

## Global definition of done

Version 1 is complete only when:

1. All six phase specifications are complete in order.
2. Every phase acceptance criterion passes.
3. All automated tests pass.
4. Debug and Release builds compile without errors.
5. The complete manual regression checklist passes.
6. The app works offline and without Accessibility permission.
7. No required behavior was silently changed.

