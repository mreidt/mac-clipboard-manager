# Phase 5 — Settings and Menu Bar

**Status:** FINISHED

## Mandatory instruction

Read `00-product-spec.md` first. Confirm Phases 1–4 are complete. Implement only Settings, menu-bar completion, launch at login and optional selection sound.

## Goal

Provide a polished native settings experience and complete every menu-bar command.

## Required files

```text
ClipboardManager/Settings/SettingsView.swift
ClipboardManager/Services/LoginItemManager.swift
ClipboardManager/MenuBar/MenuBarView.swift
ClipboardManagerTests/LoginItemManagerTests.swift
```

## Task 1 — Create the Settings scene

Use SwiftUI's macOS Settings scene so only one Settings window is created.

Open it from:

- menu-bar `Settings…`;
- picker footer gear button.

Opening Settings from the picker should close the picker first.

Use a single General page. Do not add empty General/Shortcuts/History sidebar destinations.

## Task 2 — Build the settings layout

Show these controls in exact order:

1. `Launch at login` toggle.
2. `Play sound when copying` toggle.
3. `Entries shown in picker` stepper and current number.
4. `Choose between 10 and 100 entries.` secondary text.
5. `Global shortcut` with read-only keycap display `⌃ ⇧ Space`.
6. `Move selected items to the top` toggle.
7. `Clear Clipboard History…` destructive button.

History stepper:

- Range 10–100.
- Step 5.
- Default 20.
- Show value as a number, not a text field.
- Apply immediately.
- Decreasing the limit immediately trims oldest non-favorites.
- Favorites remain.

Use native controls, system font, standard macOS spacing and automatic light/dark appearance.

## Task 3 — Implement clear-history confirmation

On button click, show:

- Title: `Clear clipboard history?`
- Message: `This removes all recent entries. Favorites will be kept.`
- Cancel button: `Cancel`.
- Destructive button: `Clear History`.

Cancel changes nothing. Confirm calls the repository's clear method and refreshes an open picker if necessary.

Important: in this product, clearing history deletes non-favorites only. Do not reinterpret the label as deleting favorites.

## Task 4 — Implement launch at login

Create `LoginItemManager` around `SMAppService.mainApp`.

Requirements:

- Expose actual registration status.
- Enabling calls `register()`.
- Disabling calls `unregister()`.
- Update `AppSettings.launchAtLogin` only after the system operation succeeds.
- On launch, reconcile stored preference with actual system status; actual status wins.
- If an operation fails, return the toggle to actual state and show a short error alert.
- Make the service injectable or wrapped behind a protocol for testing.

Do not use deprecated login-item APIs.

## Task 5 — Implement optional selection sound

- When `playCopySound` is true, play one quiet standard macOS sound after the user deliberately selects a picker entry.
- Do not play sound during normal clipboard monitoring.
- Do not play sound when pinning, clearing, searching, or opening the panel.
- Play at most once for one selection.
- Sound failure must not prevent copying or closing.

## Task 6 — Complete the menu-bar menu

Exact order:

1. `Show Clipboard` with `⌃⇧Space` shortcut display.
2. `Settings…`.
3. Divider.
4. `Quit Clipboard Manager`.

Behavior:

- Show toggles the existing panel.
- Settings closes picker, then opens the Settings window.
- Quit terminates normally.
- Keep accessory activation policy and no permanent Dock icon.

## Task 7 — Add tests

Test:

1. Settings defaults render from `AppSettings`.
2. History stepper cannot leave the allowed range.
3. Decreasing limit trims non-favorites immediately.
4. Favorites survive limit changes.
5. Cancel clear makes no changes.
6. Confirm clear deletes non-favorites and keeps favorites.
7. Successful login registration updates stored state.
8. Failed registration restores actual state.
9. Successful unregistration updates stored state.
10. Failed unregistration restores actual state.
11. Selection sound service is called only when enabled and only on selection.

## Manual verification

- Open Settings from menu bar.
- Open Settings from picker gear and confirm picker closes.
- Change every setting, quit and relaunch, and confirm persistence.
- Set entry limit to 10, 15, 20 and 100.
- Confirm trimming preserves favorites.
- Cancel Clear History and confirm no change.
- Confirm Clear History and verify favorites remain.
- Enable and disable launch at login; inspect macOS Login Items if needed.
- Enable sound and select an item; hear one sound.
- Copy normal text externally; hear no sound.
- Verify menu-bar command order and actions.
- Test light and dark mode.

## Phase acceptance criteria

- [ ] All previous tests pass.
- [ ] New settings/login tests pass.
- [ ] Settings opens from both entry points.
- [ ] All settings persist and apply immediately.
- [ ] Launch-at-login state reflects the system.
- [ ] Clear History preserves favorites.
- [ ] Optional sound follows exact trigger rules.
- [ ] Menu-bar menu is complete.

## Required completion report

Report changed files, tests, manual verification, any system limitations, deviations, and confirmation that Phase 6 was not started.
