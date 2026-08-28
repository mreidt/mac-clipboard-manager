# Phase 3 — Picker Interface

## Mandatory instruction

Read `00-product-spec.md` first. Confirm Phases 1 and 2 are complete. Implement only this phase. Do not register the global shortcut or final keyboard commands yet.

## Goal

Build the Recent/Favorites picker, search and pin interactions, then host it in one reusable native floating panel that can be opened from the menu-bar command.

## Required files

```text
ClipboardManager/Picker/ClipboardPickerViewModel.swift
ClipboardManager/Picker/ClipboardPickerView.swift
ClipboardManager/Picker/ClipboardRowView.swift
ClipboardManager/Picker/ClipboardPanelController.swift
ClipboardManagerTests/ClipboardPickerViewModelTests.swift
```

## Task 1 — Build the picker view model

The view model owns presentation state, not persistence logic.

Required state:

- active tab: Recent or Favorites;
- search text;
- full entries for the active tab;
- filtered entries;
- selected visible index;
- whether the panel is being presented.

Required behavior:

1. `prepareForOpening()` selects Recent, clears search, reloads entries, and selects index 0 if any entry exists.
2. Recent reload uses repository ordering.
3. Favorites reload uses repository ordering.
4. Search performs a case-insensitive substring match against full original text.
5. Search filters only the active tab.
6. Changing tabs reloads and selects the first filtered result.
7. Changing search clamps selection into the valid range.
8. Empty results use no selection.
9. Pin/unpin calls the repository and refreshes both relevant data sets.
10. Pin/unpin preserves the active tab and current search where possible.

Add methods for moving selection and selecting a visible index even though full keyboard binding belongs to Phase 4.

## Task 2 — Build each clipboard row

Row requirements:

- Height approximately 54 points.
- Leading shortcut badge for visible indices 0–9.
- Badge labels: index 0 is `⌘0`, index 1 is `⌘1`, through index 9 as `⌘9`.
- Rows after index 9 reserve the same leading width but show no badge.
- Convert line breaks to spaces only for preview display.
- Use one line and tail truncation.
- Keep full original text in the model.
- Trailing outline pin for non-favorite and filled pin for favorite.
- Tooltip: `Add to Favorites` or `Remove from Favorites`.
- Accessibility label includes the text preview and favorite state.
- Selected row uses a restrained system-blue background.

Interaction:

- Clicking the row calls a selection callback.
- Clicking the pin calls only the favorite callback.
- Prevent pin clicks from also triggering row selection.

## Task 3 — Build the picker layout

Use this vertical order:

1. Heading `Clipboard`.
2. Segmented control: `Recent`, `Favorites`.
3. Search field placeholder: `Search clipboard`.
4. Scrollable result list.
5. Footer with count at left and Settings gear at right.

Dimensions and style:

- Content width: 490 points.
- Maximum total height: 650 points.
- Use native material or visual effect background.
- Rounded outer corner radius: 16 points.
- Use system spacing, colors and fonts.
- Support light and dark mode.
- Do not add branding or illustrations.

Empty states:

- Recent with no entries: `No clipboard history yet`.
- Favorites with no entries: `No favorites yet`.
- Non-empty tab with unmatched search: `No matching clipboard entries`.

Footer count reflects the full selected tab before search filtering. Use `1 item` for one and `{N} items` otherwise.

## Task 4 — Copy a clicked entry

Implement one selection service or controller method:

1. Clear the general pasteboard.
2. Write the complete original string using `.string`.
3. Capture the resulting pasteboard `changeCount` in the monitor so the app-generated write is not processed twice.
4. Call repository `markSelected` using the `moveSelectedToTop` setting.
5. Play no sound yet unless the existing architecture already safely supports the Phase 5 setting.
6. Close the panel.

If updating the monitor's known count is awkward, allow it to observe the write once and rely on exact deduplication. It must never create a second record or loop.

## Task 5 — Build the floating panel controller

Create one reusable `NSPanel`:

- Host `ClipboardPickerView` using `NSHostingController`.
- Borderless or full-size-content style without visible title bar.
- Hide traffic-light controls.
- Set a floating level suitable for a utility picker.
- Allow the panel to become key and receive text input.
- Use transient/full-screen auxiliary collection behavior where appropriate.
- Do not activate as a normal Dock application.
- Center it on the screen containing the currently focused app; fall back to the screen containing the mouse, then main screen.
- Reuse the same panel for every opening.

Panel actions:

- `show()` calls `prepareForOpening()`, positions the panel, presents it and focuses search.
- `hide()` closes or orders out the panel without destroying the controller.
- `toggle()` switches between those states.
- Close on focus loss.
- Close on Escape if simple to add here; Phase 4 will guarantee keyboard behavior.

## Task 6 — Connect existing UI

- Menu-bar `Show Clipboard` calls panel `toggle()`.
- Picker gear opens the Settings scene if it already exists; otherwise it may open a clearly labeled temporary empty Settings window. The real Settings UI is Phase 5.
- Do not register `⌃⇧Space` yet.

## Task 7 — Tests and previews

View-model tests:

1. Opening resets to Recent and empty search.
2. Search is case-insensitive substring matching.
3. Search affects only the active tab.
4. Tab change resets valid selection.
5. Filtering safely clamps selection.
6. No results means no selection.
7. Pinning refreshes results without changing clipboard.
8. Digit-to-index helper maps 0–9 directly.

SwiftUI previews:

- Recent in light mode.
- Recent in dark mode.
- Favorites.
- No entries.
- No search results.
- Long multiline and Unicode text.

## Manual checks

- Open picker from menu-bar command.
- Confirm it appears above the active app.
- Confirm search accepts typing.
- Confirm Recent and Favorites switch correctly.
- Confirm long text does not alter row height.
- Confirm list scrolls with 100 entries.
- Confirm clicking a row copies exact full text and closes the panel.
- Confirm clicking a pin does not copy or close.
- Confirm clicking another app closes the panel.
- Reopen 30 times and confirm only one panel exists.
- Test light and dark mode.

## Phase acceptance criteria

- [ ] All earlier tests pass.
- [ ] All view-model tests pass.
- [ ] Picker opens from the menu-bar command.
- [ ] Search, tabs, pinning and mouse selection work.
- [ ] Panel is fixed-size/scrollable and visually native.
- [ ] Panel reuses one controller instance.
- [ ] No global shortcut was registered.

## Required completion report

Report changed files, test results, manual results, screenshots if available, deviations, and confirmation that Phase 4 was not started.

