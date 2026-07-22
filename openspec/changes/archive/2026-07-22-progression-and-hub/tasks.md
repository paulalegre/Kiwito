## 1. ProgressionManager logic

- [x] 1.1 In `core/autoloads/ProgressionManager.gd`, add the frozen `MILESTONES` const array (5 →
      `sticker_01`, 20 → `sticker_02`, 50 → `sticker_03`) and load `total_balloons_popped`/
      `unlocked_stickers` from `SaveManager` in `_ready()`.
- [x] 1.2 Implement `record_session_result(result: MinigameResult) -> void`: add `result.correct_pops` to
      `total_balloons_popped`, walk `MILESTONES` ascending, unlock+emit `sticker_unlocked(id)` for any
      newly-crossed threshold not already in `unlocked_stickers`, then persist both fields via
      `SaveManager` and `flush()` once.

## 2. SceneDirector wiring

- [x] 2.1 Update `core/autoloads/SceneDirector.gd`'s `_on_minigame_session_finished` to call
      `ProgressionManager.record_session_result(result)` before `goto_hub()`.

## 3. Hub interactive nodes

- [x] 3.1 Create a small placeholder-circle script/component pattern (runtime `_draw()`, palette-tinted, no
      texture asset) reusable by both Hub nodes.
- [x] 3.2 Build `CajaDeGlobos` under `features/hub_main/`: placeholder circle (tinted `red_coral`) + child
      `HitboxComponent`; on `tapped`, call `SceneDirector.launch_minigame()` with the balloon cartridge
      scene and the `level_match_color_red.tres` preset.
- [x] 3.3 Build `LibroMagico` under `features/hub_main/`: placeholder circle (tinted `blue_oceano`) + child
      `HitboxComponent`; on `tapped`, open the Álbum de Stickers modal.
- [x] 3.4 Wire both nodes into `features/hub_main/hub_main.tscn` with `hub_main.gd` connecting their
      signals.

## 4. Álbum de Stickers modal

- [x] 4.1 Create `shared/ui_elements/sticker_album/sticker_album.tscn` + `.gd`: `CanvasLayer`
      (`PROCESS_MODE_ALWAYS`) with a full-screen background `Control` (tap-anywhere-to-close) and a
      `GridContainer` with one slot per `MILESTONES` entry.
- [x] 4.2 On open, read `ProgressionManager.unlocked_stickers` and render each slot black (locked) or
      `red_coral`-tinted from `palette.tres` (unlocked).
- [x] 4.3 Wire `LibroMagico`'s tap to instantiate/show this modal and the background tap to close it.

## 5. Verification

- [x] 5.1 Run the project from the Hub: confirm tapping Caja de Globos launches Explotaglobos with the
      `MATCH_COLOR`/red preset, playing a session through to `session_finished` returns to the Hub.
      Verified via a temporary harness (deleted after use): Caja de Globos tap correctly called
      `SceneDirector.launch_minigame()` (`_active_minigame` became the `MgBalloons` instance); a
      `session_finished` emission correctly returned to the Hub (`_active_minigame` cleared).
- [x] 5.2 Confirm `total_balloons_popped` accumulates correctly across repeated sessions and that
      `sticker_01`/`sticker_02`/`sticker_03` unlock at the right cumulative thresholds, each only once.
      Covered by a permanent GUT suite (`tests/unit/test_progression_manager.gd`, 5 tests: accumulation,
      first-milestone unlock + single emit, no re-unlock, multiple milestones in one session, persistence
      through `SaveManager.reload()`) — chosen over an ad-hoc harness since `CLAUDE.md`/`Core_Architecture.md`
      §7 names progression milestones as GUT's second priority. All 5 pass.
- [x] 5.3 Confirm tapping Libro Mágico shows correct lock state per unlocked sticker, and that tapping the
      background closes the modal. Verified via the same temporary harness: after a fabricated 5-pop
      session, the album's 3 slots rendered `red_coral` (unlocked, `sticker_01`), black, black
      (`sticker_02`/`sticker_03` still locked); a background tap closed the modal.
- [x] 5.4 Grep the diff for literal hex/`Color(...)` values outside `palette.tres` to confirm the no-literal-
      color rule holds. Only hit: `sticker_album.tscn`'s `Background` dimming overlay
      (`Color(0, 0, 0, 0.6)`) — achromatic pure-opacity dimming, the same exemption already established by
      `fade_transition.tscn`'s black overlay; `Color.BLACK` for locked slots is likewise achromatic and is
      GDD's own literal requirement ("siluetas en negro"), not an invented color. Compliant.
- [x] 5.5 Re-run the GUT suite to confirm no regression in previously-shipped Phase 1-3 behavior. 10/10
      tests pass (5 pre-existing `SaveManager` tests + 5 new `ProgressionManager` tests), 23 asserts, no
      new orphans introduced by this change.
