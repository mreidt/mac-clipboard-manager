# Phase 1 — Foundation and Storage

## Mandatory instruction

Read `00-product-spec.md` first. Implement only this phase. Build and run all checks below, report the result, and stop. Do not start Phase 2.

## Goal

Create the macOS project foundation, menu-bar shell, SwiftData model, repository, and persistent settings. Do not monitor the clipboard or build the floating picker yet.

## Prerequisites

- Xcode with macOS 14 SDK or newer.
- A repository with no unresolved build errors.
- If a project already exists, inspect it before adding files and preserve its naming conventions where practical.

## Required files

```text
ClipboardManager/
├── App/ClipboardManagerApp.swift
├── App/AppDelegate.swift
├── Models/ClipboardEntry.swift
├── Services/ClipboardRepository.swift
├── Settings/AppSettings.swift
├── MenuBar/MenuBarView.swift
└── Tests/
    ├── ClipboardRepositoryTests.swift
    └── AppSettingsTests.swift
```

## Task 1 — Create the application shell

1. Create a SwiftUI macOS application targeting macOS 14.
2. Use Swift 5.9 or newer.
3. Configure SwiftData in `ClipboardManagerApp`.
4. Add an `AppDelegate` only for lifecycle behavior that SwiftUI cannot express clearly.
5. Set `NSApp.setActivationPolicy(.accessory)` after launch.
6. Add a `MenuBarExtra` with a system clipboard icon.
7. Add placeholder menu items:
   - `Show Clipboard`;
   - `Settings…`;
   - divider;
   - `Quit Clipboard Manager`.
8. Connect Quit to `NSApplication.shared.terminate(nil)`.
9. Placeholder Show and Settings actions may do nothing in this phase, but they must not crash.

Check:

- The app builds and launches.
- A menu-bar icon appears.
- There is no permanent Dock icon.
- Quit works.

## Task 2 — Add the SwiftData model

Create `ClipboardEntry` with:

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

Add an initializer that accepts `text`, defaults `id` to a new UUID, defaults `copiedAt` to now, defaults `isFavorite` to false, and defaults `favoritedAt` to nil.

Do not make `text` unique at the SwiftData layer.

## Task 3 — Implement `AppSettings`

Create one `@MainActor` observable settings object backed by `UserDefaults`.

Required properties:

| Property | Default |
| --- | --- |
| `historyLimit` | 20 |
| `launchAtLogin` | false |
| `moveSelectedToTop` | true |
| `playCopySound` | false |

Rules:

- Clamp history limit to 10–100 on read and write.
- The UI will later change it in increments of 5, but storage must safely accept any integer and clamp only the range.
- Allow a custom `UserDefaults` instance in the initializer so tests do not modify real app preferences.
- Do not implement launch-at-login system registration in this phase.

## Task 4 — Implement `ClipboardRepository`

Make this the only type that mutates `ClipboardEntry` records.

Required operations:

```text
recordCopiedText(text, historyLimit)
fetchRecent()
fetchFavorites()
setFavorite(entryID, isFavorite)
markSelected(entryID, moveToTop)
enforceHistoryLimit(limit)
clearRecentHistoryKeepingFavorites()
```

Detailed behavior:

### Record copied text

1. Reject the value if trimming whitespace and newlines produces an empty string.
2. Search existing entries using exact original-text equality.
3. If found, update only `copiedAt` and save.
4. If not found, insert a new non-favorite entry.
5. Enforce the history limit.
6. Save the context.

### Fetch Recent

- Return entries sorted by `copiedAt` descending.
- Include favorites if they were copied recently.
- The result size may exceed the non-favorite limit because favorites are protected.

### Fetch Favorites

- Return only `isFavorite == true`.
- Sort by `favoritedAt` descending.

### Set favorite

- When pinning, set `isFavorite = true` and `favoritedAt = now`.
- When unpinning, set `isFavorite = false` and `favoritedAt = nil`.
- Save immediately.

### Mark selected

- If `moveToTop` is true, update `copiedAt`.
- If false, leave dates unchanged.
- Never change `favoritedAt` during selection.

### Enforce limit

1. Clamp limit to 10–100.
2. Fetch non-favorites sorted newest first.
3. Preserve the first `limit`.
4. Delete the remaining non-favorites.
5. Never delete favorites.
6. Save.

### Clear history

- Delete every non-favorite entry.
- Keep every favorite.
- Save.

## Task 5 — Add unit tests

Use an in-memory SwiftData container. Test at least:

1. New text creates an entry.
2. Empty and whitespace-only strings are rejected.
3. Exact duplicate text produces one entry and updates `copiedAt`.
4. Case-different text creates separate entries.
5. Whitespace-different text creates separate entries.
6. Recent is newest first.
7. Favorites are ordered by pin date.
8. Re-copying a favorite does not modify `favoritedAt`.
9. Limit enforcement deletes oldest non-favorites.
10. Limit enforcement preserves all favorites.
11. Clear history preserves favorites.
12. Settings use the correct defaults.
13. Settings persist in the supplied defaults suite.
14. Settings clamp values below 10 and above 100.

## Do not implement in this phase

- Clipboard polling.
- Global shortcuts.
- Floating panel.
- Picker UI.
- Settings UI.
- `SMAppService` registration.

## Phase acceptance criteria

- [ ] Debug build succeeds.
- [ ] Release build succeeds.
- [ ] Menu-bar shell works without a Dock icon.
- [ ] Model container loads successfully.
- [ ] Repository is the only persistence mutation layer.
- [ ] All repository tests pass.
- [ ] All settings tests pass.
- [ ] No network dependency was added.

## Required completion report

Report:

1. Files created or changed.
2. Build commands and results.
3. Test count and result.
4. Any deviation from this spec.
5. Confirmation that Phase 2 was not started.

