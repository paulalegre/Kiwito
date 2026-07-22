## Why

`Propuesta_MVP.md` §8 fixes Phase 3 as "Cartucho Explotaglobos": the generic matching engine, gameplay
components, and the first playable minigame cartridge. Phases 1-2 built the empty vessel (autoloads,
contracts, persistence) but there is still no game — `MinigameBase` has zero subclasses and `LevelConfig`
has zero `.tres` instances. This change fills that gap so the platform has a real, playable cartridge to
validate the "add a minigame without touching architecture" promise (`GDD_MVP.md` §4).

Per explicit product decision, this change proceeds **without waiting on final art**: at proposal time only
1 of the 4 MVP colors (red/dots) had art under `design/minigames/mg_balloons/`, and
`shared/global_assets/palette.tres` did not exist. Gameplay logic does not need to wait on an illustration
pass to be validated — the remaining 3 pattern textures (stars/stripes/zigzag) landed mid-implementation
and were wired in as they arrived; see `design.md`'s Context section for the up-to-date asset state.

## What Changes

- Add a generic `matches(balloon_color, level_config) -> bool` pure function evaluating
  `MatchRule.MATCH_ANY` (always true) and `MatchRule.MATCH_COLOR` (color equality against the config's
  target), per the `MatchRule` enum already frozen on `shared/contracts/LevelConfig.gd`. Adding
  `MATCH_SHAPE`/`MATCH_SIZE`/`MATCH_COUNT` later must require no change to this function's existing
  branches, only new ones.
- Add three composition components under `shared/components/` (no dependency on a specific parent scene,
  per `Core_Architecture.md`'s composition-over-inheritance rule): a hitbox component (Area2D, 30% larger
  than the visible sprite, rejects secondary touches via `event.index == 0`, calls
  `set_input_as_handled()`), a float-upward/ascent component (spawns below camera, ascends on Y), and a
  juice component (scale/bounce feedback on valid touch, under 100ms).
- Add the first real cartridge: `features/minigames/mg_balloons/` — a `MinigameBase` subclass wiring the
  above components and the matching engine, implementing `start(config: LevelConfig)`, spawning balloons
  per config, resolving correct/incorrect taps per the Zero-Punishment principle (incorrect tap = neutral
  shake + opaque sound, never blocks the level), and emitting `session_finished(result: MinigameResult)`
  with `correct_pops`/`failed_taps`/`duration`/`errors_by_color` populated.
- Add two `LevelConfig` `.tres` presets (data-only, no new scripts): a `MATCH_COLOR` default (N=5 correct
  balloons to win, per `GDD_MVP.md` §5) and a `MATCH_ANY` onboarding preset — proving the engine needs zero
  code changes to add an educational dimension.
- Populate `shared/global_assets/palette.tres` with all 4 real, frozen colors and their pattern ids
  (`Direccion_de_Arte.md` §2.2 already fixes these values — this is data entry, not new art). Balloon
  bodies for all 4 colors are produced by `modulate`-tinting the existing neutral balloon assets, per the
  production technique the art doc itself prescribes.

## Capabilities

### New Capabilities
- `match-rule-engine`: the generic `matches()` function and the extensibility guarantee that new
  `MatchRule` values never require changing existing evaluation branches.
- `mg-balloons-cartridge`: the first playable cartridge — components, scene, spawn/win/loss behavior,
  `LevelConfig` presets, and its `MinigameResult` reporting contract.

### Modified Capabilities
(none — `minigame-contracts` is consumed as-is, not modified)

## Impact

- New: `shared/components/hitbox_component.gd`, `shared/components/ascent_component.gd`,
  `shared/components/juice_component.gd`, `shared/utils/match_rule_engine.gd`.
- New: `features/minigames/mg_balloons/*` (scene, script, `resources/*.tres` presets).
- New: `shared/global_assets/palette.tres`, fully populated with all 4 game colors.
- No changes to `shared/contracts/*` (`MinigameBase`/`MinigameResult`/`LevelConfig` shapes untouched).
- No Hub wiring yet — this cartridge is not yet reachable in-game; Phase 4 connects
  `SceneDirector`/Hub to it.
