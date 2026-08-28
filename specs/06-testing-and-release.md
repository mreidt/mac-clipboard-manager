# Phase 6 — Testing and Release Readiness

**Status:** NOT STARTED

## Mandatory instruction

Read `00-product-spec.md` first. Confirm Phases 1–5 are complete. This phase fixes defects needed to satisfy existing requirements; it must not add new product features.

## Goal

Run complete automated and manual regression testing, fix requirement violations, polish accessibility and stability, and produce a release-ready personal build.

## Task 1 — Audit scope and architecture

Confirm:

- There are no network calls or network SDKs.
- There is no account or authentication code.
- There is one SwiftData persistence mutation layer.
- There is one clipboard monitor.
- There is one reusable picker panel.
- There is one global shortcut handler.
- The app does not request Accessibility permission.
- The app never simulates paste.
- Version 1 handles text only.
- No out-of-scope feature was added.

Remove unused scaffolding and dead code only when safe and covered by a build/test afterward.

## Task 2 — Complete automated tests

Ensure automated coverage exists for:

### Repository

- insertion;
- blank rejection;
- exact deduplication;
- ordering;
- pin/unpin;
- history limit;
- favorite protection;
- clear-history semantics;
- selection date behavior.

### Settings

- defaults;
- persistence;
- history limit clamping;
- immediate limit application.

### Monitor

- change-count detection;
- no-change behavior;
- non-text rejection;
- exact text preservation;
- timer start/stop behavior;
- recovery after an error.

### Picker view model

- opening reset;
- tabs;
- search;
- empty states;
- selection clamping;
- digit mapping;
- pin refresh behavior.

### Services

- login item success and failure states;
- optional sound trigger conditions.

Use in-memory SwiftData and isolated `UserDefaults` suites. Tests must not modify the user's real clipboard, preferences, or login items unless explicitly marked as manual integration tests.

## Task 3 — Accessibility polish

- Add labels to icon-only buttons.
- Pins announce `Add to Favorites` or `Remove from Favorites`.
- Gear announces `Open Settings`.
- Rows announce preview text, favorite state and shortcut when present.
- Selected row has an accessibility selected state.
- All controls are reachable with keyboard navigation.
- VoiceOver focus does not become trapped when the panel closes.
- System text contrast remains readable in light and dark mode.

## Task 4 — Stability and edge cases

Test and fix:

- very long strings;
- 10,000-character single-line string;
- multiline string;
- emoji and composed Unicode;
- accented Portuguese characters;
- right-to-left sample text;
- URLs;
- code snippets;
- leading and trailing whitespace;
- rapid copies from multiple applications;
- 100 recent entries;
- at least 100 favorites;
- empty storage;
- corrupted or failed persistence operation where realistically testable;
- monitor active while picker and Settings open;
- repeated show/hide cycles;
- multiple displays if available;
- full-screen application if available;
- app relaunch and computer login behavior.

The panel must remain responsive and row height must not expand for long or multiline content.

## Task 5 — Full manual regression checklist

### Application shell

- [ ] Launch shows menu-bar icon.
- [ ] No permanent Dock icon appears.
- [ ] Menu items are in required order.
- [ ] Quit works.

### Monitoring

- [ ] Copy text in another application; it appears within about one second.
- [ ] Copy exact duplicate; one entry remains and moves to top.
- [ ] Copy case-different text; separate entry appears.
- [ ] Copy whitespace-only text; nothing is added.
- [ ] Copy image or file; nothing is added.
- [ ] Emoji, accents and multiline text preserve exact copy value.

### Picker

- [ ] `⌃⇧Space` opens from another application.
- [ ] Second press closes it.
- [ ] Escape closes without changing clipboard.
- [ ] Focus loss closes it.
- [ ] Search accepts immediate typing.
- [ ] Recent and Favorites tabs work.
- [ ] Pin does not copy or close.
- [ ] Mouse selection copies and closes.
- [ ] Up/Down and Return work.
- [ ] `⌘F` focuses search.
- [ ] `⌘0` maps to first visible result.
- [ ] `⌘1` maps to second visible result.
- [ ] `⌘2`–`⌘9` map to third–tenth results.
- [ ] Number mapping uses filtered order.
- [ ] Missing numbered rows do nothing safely.
- [ ] 100 entries scroll smoothly.
- [ ] Light and dark appearances look correct.

### Favorites and history

- [ ] Pin creates a persistent favorite.
- [ ] Unpin removes favorite status.
- [ ] Favorite can appear in both tabs.
- [ ] Re-copying favorite does not change Favorites ordering.
- [ ] Lowering limit preserves favorites.
- [ ] Clear History preserves favorites.
- [ ] Data survives quit and relaunch.

### Settings

- [ ] Opens from menu bar and picker gear.
- [ ] Entry limit supports 10–100 by 5.
- [ ] Changes apply immediately and persist.
- [ ] Move-to-top toggle changes selection behavior.
- [ ] Sound plays once only for deliberate selection when enabled.
- [ ] Launch-at-login toggle reflects actual system state.
- [ ] Clear confirmation text and buttons are exact.

### Privacy and permissions

- [ ] App works offline.
- [ ] No Accessibility prompt appears.
- [ ] No automatic paste occurs.
- [ ] No network requests or telemetry occur.

## Task 6 — Build configurations

1. Clean build folder.
2. Build Debug.
3. Run all tests.
4. Build Release.
5. Run static analyzer if available.
6. Resolve all compiler errors.
7. Resolve warnings caused by project code when reasonable; document any unavoidable dependency warnings.
8. Verify the Release app launches outside Xcode.

Do not disable warnings merely to obtain a clean report.

## Task 7 — Release documentation

Create or update a short project README containing:

- what the app does;
- macOS requirement;
- how to build in Xcode;
- default global shortcut;
- keyboard mappings;
- where settings are found;
- text-only limitation;
- statement that all data remains local;
- known limitations, if any.

Do not add marketing claims or installation instructions that were not tested.

## Final acceptance criteria

- [ ] All phase acceptance criteria remain satisfied.
- [ ] All automated tests pass.
- [ ] Debug and Release builds succeed.
- [ ] Every manual checklist item passes or has a documented blocker.
- [ ] No known crash remains.
- [ ] No required shortcut is broken.
- [ ] No data-loss bug affecting favorites remains.
- [ ] The Release app launches and operates without Xcode.
- [ ] README accurately describes the finished product.

## Required final report

Report:

1. Final changed files.
2. Debug and Release build results.
3. Automated test count and results.
4. Manual checklist results, including any untested hardware-dependent items.
5. Known limitations.
6. Confirmation that no new feature outside the product spec was added.
