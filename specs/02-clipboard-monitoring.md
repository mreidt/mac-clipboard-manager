# Phase 2 — Clipboard Monitoring

## Mandatory instruction

Read `00-product-spec.md` first. Confirm Phase 1 is complete. Implement only this phase, run all checks, report the result, and stop.

## Goal

Monitor the macOS clipboard for plain text, record accepted changes through `ClipboardRepository`, and avoid duplicates or feedback loops.

## Required files

```text
ClipboardManager/Services/ClipboardMonitor.swift
ClipboardManagerTests/ClipboardMonitorTests.swift
```

Modify the app entry point only enough to create and start one monitor.

## Task 1 — Define a pasteboard abstraction

Testing `NSPasteboard.general` directly is unreliable. Define a small protocol used by the monitor:

```swift
protocol PasteboardReading: AnyObject {
    var changeCount: Int { get }
    func string(forType dataType: NSPasteboard.PasteboardType) -> String?
}
```

Make `NSPasteboard` conform in an extension. Production uses `NSPasteboard.general`; tests use a fake.

Do not create a large generic pasteboard framework.

## Task 2 — Implement `ClipboardMonitor`

Requirements:

- Run on the main actor.
- Accept the pasteboard, repository, settings, and timer interval as dependencies.
- Production polling interval: 0.5 seconds.
- Store the last observed `changeCount`.
- Start only once even if `start()` is called twice.
- Invalidate the timer in `stop()` and deinitialization.
- Use a main-run-loop timer that continues while menus and panels are being used.

Poll algorithm:

1. Read current `changeCount`.
2. If unchanged, return.
3. Update the stored known count immediately.
4. Read `.string` from the pasteboard.
5. If no string exists, return.
6. If trimming whitespace and newlines is empty, return.
7. Pass the exact original string to `recordCopiedText` with the current history limit.
8. Catch persistence errors, log in Debug, and allow later polls to continue.

Do not write anything to the pasteboard in this phase.

## Task 3 — Start one monitor with app lifecycle

1. Create one long-lived monitor when the app starts.
2. Start it once after the SwiftData context and settings are available.
3. Retain it for the application lifetime.
4. Do not start a new monitor when the menu opens.

## Task 4 — Handle history-limit changes

When `historyLimit` decreases, call `enforceHistoryLimit` immediately. Do not wait for the next clipboard event.

Put this observation in one clear owner, such as the app coordinator. Do not duplicate it across several views.

## Task 5 — Add monitor tests

Use a fake pasteboard and in-memory persistence. Test:

1. Unchanged `changeCount` does nothing.
2. A changed count with text records the text.
3. A changed count without text does nothing.
4. Empty and whitespace-only text does nothing.
5. Multiline and surrounding whitespace are preserved exactly.
6. Repeated identical text produces one persisted entry.
7. `start()` called twice creates only one timer.
8. `stop()` prevents later polling.
9. A repository error on one poll does not disable later polls.

Prefer exposing a test-only or internal `pollNow()` method rather than making tests wait for real timers.

## Manual checks

1. Launch the app.
2. Copy normal text in TextEdit.
3. Confirm it is persisted within approximately one second using a temporary Debug-only log or debugger inspection.
4. Copy the same text again and confirm one entry remains.
5. Copy an image and confirm no entry is created.
6. Copy whitespace-only text and confirm no entry is created.
7. Copy emoji, accented Portuguese text, a URL, and multiline text.
8. Quit and relaunch; confirm entries persist.

Remove temporary Debug UI before completing the phase. Debug logging guarded by `#if DEBUG` is acceptable.

## Do not implement in this phase

- Writing selected entries to the clipboard.
- Floating picker.
- Search UI.
- Favorites UI.
- Global shortcut.
- Settings screen.

## Phase acceptance criteria

- [ ] All Phase 1 tests still pass.
- [ ] All monitor tests pass.
- [ ] Text copied in another app is recorded within about one second.
- [ ] Non-text and blank changes are ignored.
- [ ] Exact original text is preserved.
- [ ] Duplicate handling uses the repository.
- [ ] Exactly one monitor runs.
- [ ] No crash occurs during rapid clipboard changes.

## Required completion report

Report changed files, automated test results, manual check results, deviations, and confirmation that Phase 3 was not started.

