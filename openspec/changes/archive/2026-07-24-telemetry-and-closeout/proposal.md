## Why

Phase 6 (`Propuesta_MVP.md` §8, item 6, "Telemetría y cierre") is the last unimplemented MVP phase.
`MetricsLogger` is the only one of the five domain autoloads named in `CLAUDE.md`/`Core_Architecture.md`
§6.1 still a one-line stub, so the platform currently has no way to capture the session data
(`Core_Architecture.md` §5: resolution time, failed taps, per-color errors) that `GDD_MVP.md` §5 and
`Propuesta_MVP.md` §4/§8 name as the evidence base for calibrating future difficulty presets and for the
eventual parent/tutor progress reports. Closing this phase also means running the two verification passes
the roadmap bundles with it — a node-leak check on the Hub↔minigame cycle and a final accessibility audit —
which the roadmap explicitly gates child validation testing behind ("la validación con niños puede empezar
en cuanto la fase 4 esté completa y refinarse con 5-6").

## What Changes

- Implement `core/autoloads/MetricsLogger.gd` as a passive, in-memory-buffered telemetry service
  (`Core_Architecture.md` §5): one public method to record a finished minigame session, an in-memory buffer,
  and a flush that appends to a local JSON file only at safe points (session end, app pause/quit) — never
  once per event.
- Wire `SceneDirector._on_minigame_session_finished()` to also call `MetricsLogger`'s recording method
  alongside the existing `ProgressionManager.record_session_result()` call, using the same already-shipped
  typed `MinigameResult` — no new signal, no EventBus, just a second direct call on the same typed object
  (implementation detail; does not change any existing `scene-director` requirement's text or shape).
- Add flush triggers on `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_WM_CLOSE_REQUEST`, reusing the same
  atomic write-then-rename discipline `SaveManager` already established (`GDD_MVP.md` §7.3), but writing to
  its own file (`user://metrics_log.json`), never through `SaveManager` — metrics are not save data.
- Any I/O failure (disk full, permission denied) is swallowed silently; `MetricsLogger` never raises, blocks,
  or alters gameplay, per its "verdaderamente pasivo" contract (`Core_Architecture.md` §5).
- Add GUT tests for `MetricsLogger` (buffer accumulation, flush-on-safe-point, malformed/missing file
  tolerance on next boot — same fallback-to-empty discipline as `SaveManager`).
- Run and document a node-leak verification pass: repeated Hub→minigame→Hub cycles must leave the orphan
  node count unchanged, exercising the `scene-director` spec's already-existing "no orphaned nodes" teardown
  requirement rather than changing it.
- Run and document a final accessibility audit pass against invariants already established in earlier
  phases (hitbox sizing, zero on-screen text, non-chromatic color redundancy, Low-Stim perceptibility) —
  confirming existing behavior, not introducing new product rules.

## Capabilities

### New Capabilities
- `metrics-logger`: the `MetricsLogger` autoload — session-result recording API, in-memory buffer, flush at
  safe points only, atomic local JSON write, silent-fail/never-block contract, no remote transmission.
- `mvp-closeout-verification`: the two closing verification passes bundled into this phase — a node-leak
  check across repeated Hub↔minigame cycles, and a final accessibility audit checklist (hitbox sizes,
  zero-text, non-chromatic redundancy, Low-Stim perceptibility) — the gate the roadmap places before child
  validation testing begins.

### Modified Capabilities
(none — `MetricsLogger` is consumed by a new direct call inside `SceneDirector`'s existing handler body, and
the node-leak check only verifies `scene-director`'s existing teardown requirement more rigorously; no
existing requirement's text or behavior changes.)

## Impact

- `core/autoloads/MetricsLogger.gd` — empty stub → full implementation.
- `core/autoloads/SceneDirector.gd` — one new line in `_on_minigame_session_finished()` calling
  `MetricsLogger`; no other change.
- New file at runtime: `user://metrics_log.json` (local only, no network code anywhere in this change).
- `tests/unit/` — new GUT suite for `MetricsLogger`.
- No changes to `features/minigames/mg_balloons/` — it already emits the full typed `MinigameResult`
  `MetricsLogger` needs; no cartridge-side code changes required.
- Out of scope: any in-app UI to view collected metrics (developer/researcher-facing only), any remote/network
  transmission (explicitly Phase-2-and-parental-consent-gated per `Propuesta_MVP.md` §4), any new minigame
  cartridge.
