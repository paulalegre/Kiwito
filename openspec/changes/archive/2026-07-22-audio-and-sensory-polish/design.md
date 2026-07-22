## Context

`core/autoloads/AudioManager.gd` is a one-line stub. `SettingsManager.low_stim_mode`/`low_stim_changed`
have existed since Phase 2 but have zero consumers anywhere in the codebase. `shared/components/
juice_component.gd` (Phase 3) hardcodes `SCALE_PUNCH = 1.2` (a ±20% squash&stretch, not the documented
±12%) and `SHAKE_DURATION_SEC = 0.15` (the documented **Low-Stim** duration, not the ±6px/200ms standard
one) — both a pre-existing drift from `Direccion_de_Arte.md` §6.4/§7's exact tables, not an intentional
choice; `play_shake()` has no color tint at all. `features/minigames/mg_balloons/` has no goal box and no
frustration detection — Phase 3 was scoped to core mechanics only. `shared/ui_elements/transitions/
fade_transition.gd` hardcodes `Color(0, 0, 0, alpha)`, fading to black, contradicting §7's explicit
fade-to-cream (`#FBF3E4`) requirement. No pause UI exists anywhere, though `MinigameBase.pause()`/`resume()`
defaults (`get_tree().paused`) have sat unused since Phase 1. No audio asset files (`.ogg` or otherwise)
exist anywhere under `design/`.

## Goals / Non-Goals

**Goals:**
- A real, testable `AudioManager` service (buses, ducking, VO policy, SFX pooling) that works correctly
  today with an empty/near-empty sound registry, and needs zero code changes once real `.ogg` files arrive.
- The Low-Stim table (`Direccion_de_Arte.md` §6.4) implemented exactly, not interpretively, in
  `JuiceComponent` and `AudioManager`.
- 2-level escalating help wired into `mg_balloons`, including the goal box it depends on.
- A correct/incorrect juice pass on the balloon cartridge that matches the feedback vocabulary table
  (`Direccion_de_Arte.md` §7) precisely, fixing the pre-existing constant drift.
- A pause menu as `SceneDirector`-owned persistent chrome.
- Fix the fade-to-black bug (should be cream).

**Non-Goals:**
- Recording or sourcing real audio content (VO/SFX/music) — a follow-up asset pass.
- `MetricsLogger`/telemetry (Phase 6).
- Confetti/level-end and sticker-unlock-sweep animations from the feedback table — deferred as extra scope
  beyond this phase's remit; this pass targets the highest-frequency interactions (pop/incorrect-tap) and
  the transition color bug only.
- A second minigame cartridge, or generalizing frustration-detection into a shared component before a second
  cartridge exists to prove it needs to be generic.

## Decisions

**1. Sound registry is a sparse `const Dictionary[StringName, AudioStream]` inside `AudioManager`, not a
`Resource`.** Same reasoning as `ProgressionManager`'s milestone table (Change #4): one reader, no content
to author yet, so a `Resource` indirection buys nothing. An id missing from the dictionary (which is all of
them today) hits the already-drafted `push_warning`-and-no-op path from `Core_Architecture.md` §8.5 — this
mirrors exactly how Change #3 shipped `palette.tres` fully populated before all 4 pattern textures existed.

**2. SFX: a fixed pool of `AudioStreamPlayer` nodes (round-robin), each assigned to the `SFX` bus.** This is
the one pooling case the architecture doc itself justifies (`Core_Architecture.md` §2B/§8.4 — overlapping
taps). VO: a single dedicated `AudioStreamPlayer` on the `VO` bus; a new `play_vo()` call while one is
active **interrupts** it immediately (stops the old stream, starts the new one) rather than queuing —
simpler for MVP's short single-cue VO lines, and queuing is deferred as unneeded complexity until a real
case demands it. Music: two alternating `AudioStreamPlayer`s on the `Music` bus so `set_music()` can
crossfade (fade the old one out / new one in via `Tween` on `volume_db`) without needing a dedicated
crossfade node type.

**3. Ducking is a `Tween` on the Music bus's `volume_db`, not a sidechain/compressor.** Exactly as
`Core_Architecture.md` §8.2 already specifies: on `play_vo()`, tween `Music` bus down ~-12dB; on the VO
player's `finished` signal, tween it back. Deterministic, zero extra CPU cost.

**4. Low-Stim is read fresh at the moment of each call, never cached.** `JuiceComponent.play_feedback()`/
`play_shake()` and `AudioManager.play_sfx()` each check `SettingsManager.low_stim_mode` at call time and pick
the matching parameter set. Alternative considered: subscribe to `low_stim_changed` and pre-swap a
"current profile" reference — rejected as unnecessary indirection; per-call reads are just as correct and
trivially satisfy the art doc's own acceptance bar ("percibir la diferencia en menos de 5 segundos") since
the very next tap after toggling already reflects the new mode.

**5. Juice constants are corrected to match `Direccion_de_Arte.md` §7/§6.4 exactly, replacing the Phase 3
approximation.** Shake: ±6px/200ms standard, ±3px/150ms Low-Stim (Phase 3's `0.15s` was actually the
Low-Stim value, applied unconditionally — a drift, not a deliberate choice). Squash&stretch: ±12% standard
(`scale_punch = 1.12`, not the shipped `1.2`), ±6% Low-Stim (`1.06`). This is a bug fix against an already
-written, verifiable spec, not a new design call.

**6. Incorrect-tap grey tint is a new `warm_grey_tint` entry in `palette.tres`, not a hardcoded `Color`.**
`Direccion_de_Arte.md` §7 specifies a *warm* grey (not pure achromatic black/white), so — unlike the
cream/black overlay exemption used for `fade_transition`/`PatternSprite` opacity — this is a genuine
designed color and must come from the palette like any other, per `CLAUDE.md`'s "no literal hex" rule.
`JuiceComponent.play_shake()` gains a brief `modulate` tween toward this color and back (150/200ms,
matching the shake duration for whichever mode is active), requiring `JuiceComponent` to take a
`@export var palette: Palette` the same way `Balloon`/`mg_balloons.gd` already do.

**7. Goal box lives inside `mg_balloons`, not `shared/`.** It shows the current `MATCH_COLOR` target in the
top-right corner (`GDD_MVP.md` §3) using the same "tint a shared neutral shape from `palette.tres`" technique
already established for Hub placeholders (Change #4) — reusing `PlaceholderCircle`-style rendering rather
than inventing new art. It is cartridge-specific (hidden/inert for `MATCH_ANY`, since there is no single
target color to show), so it belongs in `features/minigames/mg_balloons/`, matching the strict-isolation
rule — nothing generic enough yet to warrant `shared/`.

**8. Frustration detection lives in `mg_balloons.gd` itself, not a shared component.** The 3-taps-in-1.5s /
4-seconds-idle thresholds (`GDD_MVP.md` §3) are tracked via simple timestamp bookkeeping local to this one
cartridge. Alternative considered: a generic `FrustrationDetectorComponent` in `shared/components/` —
rejected as premature generalization; there is only one cartridge today, and its frustration model may not
generalize as-is to a future one (e.g. a shape-matching game's "wrong tap" cadence could differ). Any correct
tap resets the frustration window and clears active escalation immediately.

**9. Escalating help: level 1 pulses the goal box + plays a (currently-unregistered, warn-only) VO cue;
level 2 highlights live target-colored balloons directly.** Level 1: goal box scale
tween (1.0→1.12→1.0) + amber halo overlay, repeatable, plus `AudioManager.play_vo(&"help_level_1")`. Level
2 (frustration persisting past level 1): each currently-alive target-color `Balloon` gets a new
`set_highlighted(enabled: bool)` method (halo + slow bounce, 1.5s cycle, non-chromatic) called by
`mg_balloons.gd` — no audio at level 2, matching the doc's explicit "ninguno (evita saturar)". Both levels
run without pausing or discarding input, per the Zero-Punishment/no-freeze invariant.

**10. Pause menu is `SceneDirector`-owned chrome, a sibling to the existing `_fade` CanvasLayer.**
`SceneDirector._ready()` instantiates a `PauseOverlay` (Home button + overlay) exactly like it already does
for `_fade`. Its Home button's visibility is toggled by `SceneDirector` right where `_active_minigame` is
set/cleared (in `launch_minigame()`/`_swap_scene()`) — visible only during a minigame session, hidden in the
Hub, since the Hub has nothing to pause. Both button and overlay use `process_mode = PROCESS_MODE_ALWAYS`
per `Core_Architecture.md` §1.3. "Continuar" sets `get_tree().paused = false` and hides the overlay.
"Salir al Hub" unpauses first (so the fade transition itself isn't frozen), then calls the existing
`SceneDirector.goto_hub()` — reusing the already-shipped teardown path from `scene-director`'s spec
unmodified.

**11. Fade-to-cream fix bundled into this change.** `palette.tres` gains `cream_fade` (`#FBF3E4`) alongside
`warm_grey_tint`, both non-gameplay UI colors (no `pattern_id`, unlike the 4 `MATCH_COLOR` entries — patterns
only exist for that specific redundancy purpose). `fade_transition.gd`/`.tscn` take a `@export var palette:
Palette` and read `palette.get_color(&"cream_fade")` instead of a hardcoded `Color(0,0,0,alpha)`. This isn't
textually part of roadmap item 5, but is fixed here — the same code this change is already touching for the
pause overlay — rather than opened as a separate change, mirroring how Change #3 absorbed a mid-
implementation asset discovery instead of leaving it stale.

## Risks / Trade-offs

- **[Risk]** `AudioManager` ships against an almost-empty sound registry — real playback is unverified until
  actual `.ogg` assets land. → **Mitigation:** the missing-id warn-and-no-op path is itself the thing under
  test; wiring is proven safe today, and dropping in real files later requires zero code changes.
- **[Risk]** SFX pool size is a guess with no real telemetry to size it against yet. → **Mitigation:** kept
  small (a handful of players); revisit with real usage data once `MetricsLogger` ships in Phase 6.
- **[Trade-off]** Correcting the Phase 3 juice constants (`1.2`/`0.15s` → `1.12`/`0.06`/mode-split) changes
  already-shipped balloon feel slightly. → Accepted: this is a fix against a written, verifiable spec, not
  new design; the old values were an unintentional drift, not a decision anyone made on purpose.
- **[Risk]** Bundling the fade-to-cream fix here, off-roadmap for item 5's own text. → **Mitigation**:
  called out explicitly in the proposal and here, not silently expanded scope; same precedent as Change #3's
  mid-implementation asset absorption.

## Open Questions

None blocking. Deferred follow-ups, kept from being lost:
- Confetti/level-end and sticker-unlock-sweep animations from the feedback vocabulary table.
- Real audio asset production (VO scripts, SFX, music) and re-tuning the SFX pool size once real content and
  `MetricsLogger` telemetry exist.
- Whether frustration detection should generalize into a shared component — revisit once a second cartridge
  exists to prove (or disprove) that its shape is reusable.
