# Phase 4 — Keyboard and Selection

**Status:** FINISHED

## Mandatory instruction

Read `00-product-spec.md` first. Confirm Phases 1–3 are complete. Implement only keyboard shortcuts and keyboard selection in this phase.

## Goal

Make the picker accessible globally with `⌃⇧Space` and fully operable by keyboard while it is active.

## Required files

```text
ClipboardManager/Services/GlobalShortcutManager.swift
```

Modify the picker view model, panel controller and app coordinator only as required.

## Task 1 — Add the global-shortcut dependency

Add the Swift Package:

```text
https://github.com/sindresorhus/KeyboardShortcuts
```

Use a stable current release compatible with the project's macOS and Swift versions. Commit the resolved package file.

Do not add another shortcut package.

## Task 2 — Register the toggle shortcut

1. Define one shortcut name: `.toggleClipboardPicker`.
2. Default it to Control + Shift + Space.
3. Register one handler during app startup.
4. The handler calls `ClipboardPanelController.toggle()` on the main actor.
5. Do not register a second handler when the menu opens or settings change.
6. Keep the shortcut fixed in version 1.
7. Do not request Accessibility permission.

If registration fails because another app owns the shortcut:

- Show: `The shortcut ⌃⇧Space is already being used by another application.`
- Keep the menu-bar `Show Clipboard` command operational.
- Do not silently select a different shortcut.

## Task 3 — Make panel keyboard focus reliable

When opening:

1. Activate the application without showing a Dock icon.
2. Make the panel key and front.
3. Focus the search field.
4. Ensure typing immediately updates search.

When closing, return focus naturally to the previously active application. Do not simulate a click or keystroke.

## Task 4 — Implement panel-only keyboard commands

Handle keys only while the picker panel is active.

| Input | Required behavior |
| --- | --- |
| Down | Move to next result, stopping at last |
| Up | Move to previous result, stopping at first |
| Return | Copy selected result and close |
| Escape | Close without copying |
| `⌘F` | Focus search |
| `⌘0` | Copy visible index 0 and close |
| `⌘1` | Copy visible index 1 and close |
| ... | ... |
| `⌘9` | Copy visible index 9 and close |

Rules:

- Number commands use filtered results, not the unfiltered store.
- Number commands use the same selection/copy path as clicking a row.
- Missing rows do nothing and must not crash.
- Arrow selection should scroll into view.
- Changing search keeps selection valid.
- Return does nothing when no entry is selected.
- Escape never changes clipboard contents.
- Do not install a global event tap for panel-only keys.

Use SwiftUI commands, `.onKeyPress`, focused values, or a small AppKit key handler. Choose one clear approach; do not implement the same key in several layers.

## Task 5 — Prevent conflicts with search typing

- Ordinary digits typed without Command must enter the search field.
- `⌘0`–`⌘9` must select results and must not alter search text.
- Arrow keys should navigate results even while search is focused.
- Left and Right arrows may continue normal text-field behavior.
- `⌘A`, `⌘C`, `⌘V`, and editing shortcuts must work normally inside search.

## Task 6 — Add tests

Automated tests should cover the pure command-to-action mapping:

1. Digit 0 maps to visible index 0.
2. Digit 9 maps to visible index 9.
3. Missing index is ignored.
4. Arrow up stops at index 0.
5. Arrow down stops at the final index.
6. Filtering clamps selection.
7. Selection uses the filtered entry.
8. Selecting with `moveSelectedToTop = false` leaves `copiedAt` unchanged.
9. Selecting with it enabled updates `copiedAt`.
10. Selection never updates `favoritedAt`.

Global hotkey delivery and focus behavior must be checked manually because unit tests do not reliably reproduce macOS window-server behavior.

## Manual verification

From Finder, Safari or TextEdit:

- Press `⌃⇧Space`; picker opens.
- Press again; picker closes.
- Type immediately; search updates.
- Use Up and Down; selection changes and scrolls.
- Press Return; exact selected text reaches clipboard and picker closes.
- Press Escape; picker closes without changing clipboard.
- Press `⌘F`; search receives focus.
- Verify every shortcut `⌘0` through `⌘9`.
- Search for a subset and verify number shortcuts use filtered order.
- Verify ordinary digits can be typed into search.
- Verify no Accessibility prompt appears.
- Quit, relaunch and verify the global shortcut still works.

## Do not implement in this phase

- Editable shortcut UI.
- Global shortcuts for individual entries when panel is closed.
- Automatic pasting.
- Accessibility permissions.
- Launch-at-login behavior.
- Settings UI changes beyond a placeholder read-only shortcut label.

## Phase acceptance criteria

- [ ] All previous tests pass.
- [ ] New mapping and selection tests pass.
- [ ] `⌃⇧Space` reliably toggles the picker globally.
- [ ] All documented panel keys work.
- [ ] Search and number shortcuts do not conflict.
- [ ] No Accessibility permission is requested.
- [ ] No automatic paste occurs.

## Required completion report

Report dependency version, changed files, tests, full manual shortcut results, deviations, and confirmation that Phase 5 was not started.
