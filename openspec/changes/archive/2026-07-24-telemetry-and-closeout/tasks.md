## 1. MetricsLogger core implementation

- [x] 1.1 Define the session-entry shape `MetricsLogger` records (session start timestamp, `correct_pops`,
      `failed_taps`, `duration`, `errors_by_color`) built directly from the typed `MinigameResult`.
- [x] 1.2 Implement the in-memory buffer (`Array[Dictionary]`) and the public recording method that appends
      an entry from a `MinigameResult` — no disk I/O inside this call.
- [x] 1.3 Implement the atomic flush (write `.tmp`, append/rename into `user://metrics_log.json`),
      independent of `SaveManager` — its own `FileAccess` code path.
- [x] 1.4 Wire the flush call at minigame-session-finish time (see task 2.1) and at
      `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_WM_CLOSE_REQUEST` via `_notification()`.
- [x] 1.5 Wrap every flush attempt so any `FileAccess` failure logs `push_warning`, discards that flush's
      buffered entries, and returns normally — never throws, retries, or blocks.
- [x] 1.6 Confirm `MetricsLogger.gd` contains no networking API of any kind (`HTTPRequest`,
      `WebSocketPeer`, etc.).

## 2. SceneDirector wiring

- [x] 2.1 Add one call to `MetricsLogger`'s recording method inside
      `SceneDirector._on_minigame_session_finished()`, alongside the existing
      `ProgressionManager.record_session_result(result)` call — same `MinigameResult` object, no new
      signal.
- [x] 2.2 Verify autoload init order still matches `Core_Architecture.md` §5.1 (`MetricsLogger` hydrates
      nothing from another autoload in `_ready()` beyond what it already needs — it has no dependency on
      `SaveManager`/`SettingsManager`/`ProgressionManager`).

## 3. Automated tests (GUT)

- [x] 3.1 Test: recording a session appends to the in-memory buffer without writing to disk.
- [x] 3.2 Test: flushing appends buffered entries to the telemetry file atomically.
- [x] 3.3 Test: a missing or corrupt `metrics_log.json` on next read is tolerated (empty/default state,
      no crash), mirroring `SaveManager`'s fallback discipline.
- [x] 3.4 Test: a simulated flush failure logs a warning, discards the buffer, and does not raise.

## 4. Node-leak verification pass

- [x] 4.1 Build a temporary runtime harness (per the established `_verify.gd`/`_verify.tscn` pattern) that
      drives several consecutive Hub→minigame→Hub cycles via `SceneDirector`.
- [x] 4.2 Measure the orphan node count before the first cycle and after the last cycle; confirm they match.
- [x] 4.3 If a leak is found, fix the root cause (e.g. a dangling signal connection) in the relevant
      cartridge/Core script — do not paper over it in the harness.
- [x] 4.4 Delete the temporary harness once the pass is confirmed clean.

## 5. Accessibility audit pass

- [x] 5.1 Audit every interactive element shipped through Phase 5 (balloons, pause-menu icons, Hub
      tappables, sticker-album close affordance) for the +30% hitbox-to-sprite ratio; fix any violation.
- [x] 5.2 Audit every shipped `.tscn` for stray instructional/navigational text nodes; fix any violation.
- [x] 5.3 Audit every place a `MATCH_COLOR` game color is used for a rule-relevant distinction to confirm
      its non-chromatic pattern is present; fix any violation.
- [x] 5.4 Re-verify Low-Stim perceptibility (<5s) across every shipped feedback path (balloon pop/shake,
      escalating help levels 1-2, Hub↔minigame transition), using the same harness technique proven in the
      `audio-and-sensory-polish` change.
- [x] 5.5 Record the audit's findings and fixes (if any) in the PR/commit description for this change.

## 6. Spec validation

- [x] 6.1 Run `npx --yes @fission-ai/openspec@1.6.0 validate telemetry-and-closeout --strict` and resolve
      any errors before archiving.
