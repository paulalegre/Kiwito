## Context

`MetricsLogger` is the last of the five domain autoloads named in `Core_Architecture.md` §6.1 still an
empty stub (`extends Node` + a two-line comment). `SaveManager` (`core/data/SaveManager.gd`) already
establishes the pattern this change reuses: JSON via `FileAccess`, atomic write (`.tmp` then rename),
tolerant of a missing/corrupt file (falls back rather than crashing on boot). `SceneDirector` already owns
the single point where a finished minigame session becomes a typed `MinigameResult` and calls
`ProgressionManager.record_session_result(result)` — the natural second call site for telemetry, requiring
no new signal and no EventBus.

The other half of this phase is not new code but two verification passes the roadmap bundles with it: a
node-leak check (does the Hub↔minigame cycle really leave zero orphans across N repeated cycles, not just
one) and a final accessibility audit (do the invariants established across Phases 1-5 — hitbox sizing,
zero on-screen text, non-chromatic color redundancy, Low-Stim perceptibility — actually hold across the
whole built surface, not just the file each was introduced in). The roadmap explicitly gates the start of
child validation testing behind this phase, so both passes need a recorded, repeatable result, not just an
implicit "it probably still works."

## Goals / Non-Goals

**Goals:**
- A real, passive `MetricsLogger` autoload: buffers session results in memory, flushes to
  `user://metrics_log.json` only at safe points, never blocks or crashes the child's session on I/O failure.
- One new direct call from `SceneDirector` into `MetricsLogger`, reusing the existing typed `MinigameResult`
  — zero changes to how or when `MinigameResult` itself is built.
- A recorded node-leak verification result across repeated Hub↔minigame cycles (not a one-shot check).
- A recorded accessibility audit result against the invariants already shipped in Phases 1-5.

**Non-Goals:**
- No in-app UI to view collected metrics — this is developer/researcher-facing telemetry only.
- No remote/network transmission of any kind — explicitly Phase-2-and-parental-consent-gated per
  `Propuesta_MVP.md` §4; this change is 100% local file I/O.
- No new minigame cartridge, no changes to `mg_balloons`'s existing mechanics — it already emits the full
  `MinigameResult` this change needs.
- No new product/UX rule — the accessibility audit verifies existing invariants, it does not introduce new
  ones the design docs haven't already specified.

## Decisions

**Decision 1 — Metrics are not save data; they never go through `SaveManager`.**
`CLAUDE.md`/`Core_Architecture.md` §6.1 name `SaveManager` as the *sole* persistence I/O layer, but its
existing contract (`user://save_data.json`, versioned, milestone/settings-shaped) has nothing to do with an
append-only telemetry log. Routing metrics through `SaveManager` would either force an unrelated schema
bump on every metrics change, or silently blur "save data" (must never be lost) with "telemetry" (fine to
lose on rare I/O failure — see Decision 3). `MetricsLogger` therefore does its own minimal `FileAccess` I/O
directly to its own file (`user://metrics_log.json`), following the exact same atomic write-then-rename
pattern `SaveManager` established, but as a separate, independent code path. Alternative considered: add a
`record_metrics_event()` method to `SaveManager` — rejected, since `Core_Architecture.md` §6.1 is explicit
that `SaveManager` holds "sin reglas de juego" (no game rules) and telemetry is a distinct domain, not save
state.

**Decision 2 — In-memory buffer, flush only at safe points.**
Per `Core_Architecture.md` §5, `MetricsLogger` accumulates session entries in an in-memory `Array` and
appends to disk only at: (a) a minigame session finishing (the same moment `SceneDirector` already calls
`ProgressionManager`), and (b) `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_WM_CLOSE_REQUEST` via
`_notification()`, catching any buffered-but-unflushed entries before the app backgrounds or closes.
Writing per-event would mean a disk write on every balloon tap — unacceptable on tablet storage and a
needless corruption-window per the same reasoning `SaveManager`'s atomic-write design already applies.

**Decision 3 — Passive means it never blocks or crashes, full stop.**
Every write path is wrapped so a `FileAccess` failure (disk full, permission denied) is caught, logged via
`push_warning`, and dropped — the in-memory buffer for that flush is discarded rather than retried or
queued, since retrying risks accumulating unbounded memory if storage is genuinely unavailable for a whole
session. This mirrors the "silently swallowed" contract `Core_Architecture.md` §5 states explicitly:
"Su fallo... se traga silenciosamente — nunca interrumpe el juego del niño." Telemetry loss is an acceptable
trade-off; a stalled or crashed session is not.

**Decision 4 — `SceneDirector` gets one new line, not a new signal.**
`_on_minigame_session_finished(result: MinigameResult)` already exists and already receives the exact typed
object `MetricsLogger` needs. Adding `MetricsLogger.record_session(result)` alongside the existing
`ProgressionManager.record_session_result(result)` call keeps "signals up, calls down" intact (`MetricsLogger`
is a service being called directly, exactly like `AudioManager`, not a signal fan-out) and requires no
change to `mg_balloons.gd`, `MinigameBase`, or `MinigameResult` — none of which need to know telemetry
exists. Alternative considered: have `MetricsLogger` connect directly to a minigame's `session_finished`
signal — rejected, since a cartridge's local signal is architecturally owned by whoever instantiates it
(`SceneDirector`), not a global listener list; connecting `MetricsLogger` to it directly would require
`SceneDirector` to expose the active minigame reference outward, a bigger surface change for no benefit.

**Decision 5 — Node-leak verification is a repeated-cycle check, not a new requirement.**
`scene-director`'s existing "Minigame teardown on stop" requirement already asserts zero orphans after one
Hub→minigame→Hub cycle. This change's verification pass runs that same teardown N times in a row (a
temporary harness, per the established pattern from Phases 4-5) and asserts the orphan count stays flat
across all N — catching a leak that only shows up on the second-or-later cycle (e.g. a dangling signal
connection keeping a freed node's closure alive) that a single-cycle check would miss. This is *stronger
verification of an existing requirement*, not new behavior, so it is captured as new scenarios under a new
`mvp-closeout-verification` capability rather than as a MODIFIED delta on `scene-director`.

**Decision 6 — Accessibility audit re-verifies, it does not re-legislate.**
The audit checklist (hitbox ratio, zero-text, non-chromatic redundancy, Low-Stim perceptibility) restates
invariants already normative in `CLAUDE.md` and already specified in `low-stim-contract`/
`mg-balloons-cartridge`. This change's job is to confirm they hold across the actually-built surface today
(Hub chrome, pause menu, sticker album — several of which shipped in Phases 4-5 after those invariants were
first written) — not to invent new rules. Findings that reveal a real violation get fixed as part of this
change's tasks; the requirement itself is unchanged.

## Risks / Trade-offs

- **[Risk] Silent-fail-on-I/O-error means real metrics data can go missing with no user-visible signal.**
  → Mitigation: this is the explicit, documented trade-off in `Core_Architecture.md` §5 itself ("nunca
  interrumpe el juego del niño"); `push_warning` still surfaces the failure to a developer running from the
  editor/console, just never to the child.
- **[Risk] A separate `user://metrics_log.json` file (vs. reusing `SaveManager`) means a second atomic-write
  code path to maintain.** → Mitigation: the write helper is a handful of lines mirroring `SaveManager`'s
  already-proven pattern; the alternative (coupling telemetry's schema evolution to save-schema versioning)
  is a worse long-term cost.
- **[Risk] Repeated-cycle node-leak verification is a temporary harness, not a permanent GUT test, so it
  won't catch a future regression automatically.** → Mitigation: consistent with the established
  Phases 4-5 precedent (temporary `_verify.gd` harnesses for runtime/timing-dependent behavior); if a GUT-testable
  invariant emerges from this pass it gets added to the permanent suite, but the multi-cycle scene-swap
  itself needs a running `SceneTree`, which is harness territory, not a pure-logic GUT unit test.

## Open Questions

None — scope, file boundaries, and the metrics-vs-save-data boundary are all settled above.
