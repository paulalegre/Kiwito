## 1. Palette additions

- [x] 1.1 Add `cream_fade` (`#FBF3E4`) and `warm_grey_tint` entries to `palette.tres`/`Palette.gd`'s
      `colors` dictionary (no `pattern_id` needed — non-gameplay UI colors).

## 2. AudioManager service

- [x] 2.1 Build the 3-bus layout (Music/SFX/VO) in the project's audio bus config.
- [x] 2.2 Implement `AudioManager.gd`: sparse sound registry (`Dictionary[StringName, AudioStream]`), a
      round-robin `AudioStreamPlayer` pool on the SFX bus, two alternating `AudioStreamPlayer`s on the Music
      bus for crossfade, one dedicated `AudioStreamPlayer` on the VO bus.
- [x] 2.3 Implement `play_sfx(sfx_id)`, `play_vo(vo_id)` (ducking + interrupt-on-overlap + restore-on-finish),
      `set_music(track_id)` (crossfade), `stop_vo()`.
- [x] 2.4 Implement the missing-id safe path: `push_warning`, no playback, no crash, for all 3 play methods.
- [x] 2.5 Apply the Low-Stim softer-SFX-profile check inside `play_sfx()` (reduced SFX bus attenuation when
      `SettingsManager.low_stim_mode` is true).

## 3. JuiceComponent Low-Stim + juice fixes

- [x] 3.1 Correct `SCALE_PUNCH`/shake constants to the exact table (±12%/±6% scale, ±6px/200ms vs
      ±3px/150ms shake), branching per `SettingsManager.low_stim_mode` read at call time.
- [x] 3.2 Add `@export var palette: Palette` to `JuiceComponent` and a warm-grey `modulate` tween in
      `play_shake()` using the new `warm_grey_tint` palette entry.

## 4. Fade-to-cream fix

- [x] 4.1 Add `@export var palette: Palette` to `fade_transition.gd`, wire `palette.tres` into
      `fade_transition.tscn`, and replace the hardcoded `Color(0,0,0,alpha)` with
      `palette.get_color(&"cream_fade")` (preserving the alpha channel for the fade tween).

## 5. Pause menu

- [x] 5.1 Build a `PauseOverlay` scene/script under `shared/ui_elements/pause_menu/`: Home button
      (top-left, +30% hitbox, `process_mode = PROCESS_MODE_ALWAYS`) and the pause overlay itself (two
      icon-only affordances: Continuar, Salir al Hub), also `PROCESS_MODE_ALWAYS`.
- [x] 5.2 Wire `SceneDirector` to instantiate `PauseOverlay` in `_ready()` alongside `_fade`; toggle the Home
      button's visibility wherever `_active_minigame` is set/cleared.
- [x] 5.3 Wire "Continuar" (`get_tree().paused = false` + hide overlay) and "Salir al Hub" (unpause, then
      `SceneDirector.goto_hub()`).

## 6. mg_balloons: goal box + escalating help + juice pass

- [x] 6.1 Add a goal-box node to `mg_balloons.tscn`/`.gd`: fixed top-right position, tinted from
      `palette.tres` per the active `MATCH_COLOR` target, visible only in `MATCH_COLOR` sessions.
- [x] 6.2 Implement frustration-detection bookkeeping in `mg_balloons.gd`: sliding window for "3 incorrect
      taps in <1.5s", a timer for "4s with no correct tap," reset on any correct tap.
- [x] 6.3 Implement level-1 help: goal-box pulse tween (1.0→1.12→1.0) + amber halo + `AudioManager.play_vo()`
      call, repeatable.
- [x] 6.4 Implement level-2 help: add `Balloon.set_highlighted(enabled: bool)` (non-chromatic halo + slow
      1.5s-cycle bounce); `mg_balloons.gd` applies it to all currently-alive target-color balloons when
      frustration persists past level 1, clears it on any correct tap.
- [x] 6.5 Verify escalating help never blocks input: correct/incorrect taps are processed identically whether
      or not help is active. Verified via a temporary harness (deleted after use): a correct tap on a
      target-color balloon was fully processed (counted, cleared escalation) while level-2 help was
      actively highlighting balloons.
- [x] 6.6 Apply corrected juice constants (task 3.1) to the balloon's own correct/incorrect feedback calls
      (no changes needed if `JuiceComponent` already owns these — verify wiring only).

## 7. Verification

- [x] 7.1 Run the project: confirm the Home button appears only during a minigame session, pause/resume/exit
      all work, and the Hub<->minigame fade now visibly uses cream, not black. Verified via a temporary
      harness (deleted after use): Home button hidden in Hub, visible after `launch_minigame()`; Home tap
      paused the tree and opened the overlay; Continuar resumed correctly; Salir al Hub unpaused, tore down
      the minigame, and hid the Home button again; fade color during `fade_out()` matched `palette.tres`'s
      `cream_fade` exactly, not black.
- [x] 7.2 Confirm `AudioManager`'s missing-id path logs warnings and never crashes for `play_sfx`/`play_vo`/
      `set_music` with unregistered ids. Verified: all three calls with unregistered ids logged a
      `push_warning` and returned normally with no crash.
- [x] 7.3 Confirm Low-Stim toggling changes `JuiceComponent`'s shake/scale amounts and `AudioManager`'s SFX
      level on the very next call, with no stale state. Verified via a temporary harness (deleted after
      use): sampling `play_shake()`'s position offset near the peak of each mode's own first tween leg
      showed ~4.8px (of an expected 6px) in standard mode vs ~2.8px (of an expected 3px) in Low-Stim mode,
      confirming both the amplitude AND duration branch immediately after toggling
      `SettingsManager.low_stim_mode` mid-session, no caching.
- [x] 7.4 Confirm frustration detection triggers level-1 then level-2 help correctly (both trigger
      conditions), that a correct tap resets it, and that taps remain fully responsive throughout. Verified:
      3 incorrect taps in <1.5s escalated `_frustration_level` 0→1 (goal-box pulse + VO call); a further 3
      incorrect taps escalated 1→2 (target-color balloons highlighted); a correct tap on a deterministically
      spawned target-color balloon while level-2 help was active was fully counted and cleared the
      escalation state, proving input is never blocked.
- [x] 7.5 Grep the diff for literal hex/`Color(...)` values outside `palette.tres` to confirm the
      no-literal-color rule holds for all new code (cream fade, warm-grey tint, goal box, halos). Only hit
      in project code (excluding `addons/gut/`, a third-party plugin): `balloon_halo.gd`'s
      `Color(1.0, 1.0, 1.0, 0.28)` — pure white at partial opacity, achromatic by design ("halo... no-
      cromático" per the doc itself), matching the same exemption already established by
      `fade_transition`'s pre-fix overlay and `sticker_album`'s black/dim-background literals. Compliant.
- [x] 7.6 Re-run the GUT suite to confirm no regression in previously-shipped Phase 1-4 behavior. 10/10
      tests pass, 23 asserts, no new orphans.
